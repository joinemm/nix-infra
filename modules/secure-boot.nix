{
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  environment.systemPackages = with pkgs; [
    sbctl
    tpm2-tss
    tpm2-tools
  ];

  # Lanzaboote currently replaces the systemd-boot module.
  boot.loader.systemd-boot.enable = lib.mkForce false;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
    configurationLimit = 3;
  };

  # TPM2 Unlocking
  boot.initrd.availableKernelModules = [ "tpm_tis" ];
  boot.initrd.systemd.enable = true;
}
