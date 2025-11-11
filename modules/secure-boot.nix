{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  sbsetup = pkgs.writeShellScriptBin "sbsetup" ''
    if [ "$EUID" -ne 0 ]; then echo "Please run as root" >&2; exit 1; fi
    sbctl create-keys
    chattr -i /sys/firmware/efi/efivars/KEK*
    chattr -i /sys/firmware/efi/efivars/db*
    sbctl enroll-keys --microsoft
  '';
in
{
  imports = [
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  environment.systemPackages =
    (with pkgs; [
      sbctl
      e2fsprogs
    ])
    ++ [ sbsetup ];

  # Lanzaboote currently replaces the systemd-boot module.
  boot.loader.systemd-boot.enable = lib.mkForce false;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
    configurationLimit = 3;
  };
}
