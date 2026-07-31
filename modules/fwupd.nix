{
  pkgs,
  lib,
  config,
  ...
}:
{
  services.fwupd = {
    enable = true;
    # https://github.com/nix-community/lanzaboote/issues/591
    package = pkgs.fwupd.overrideAttrs (old: {
      version = "2.1.6";
      src = pkgs.fetchFromGitHub {
        owner = "fwupd";
        repo = "fwupd";
        tag = "2.1.6";
        hash = "sha256-K8n1rPiLuHDybWPoAUQA7RY4J+Ga1fwNiaj48fHAh9A=";
      };
      patches = lib.filter (
        patch: baseNameOf patch != "0004-Get-the-efi-app-from-fwupd-efi.patch"
      ) old.patches;
      mesonFlags = lib.filter (flag: !lib.hasPrefix "-Defi_app_location=" flag) old.mesonFlags ++ [
        (lib.mesonOption "efi_app_location" (
          if lib.attrByPath [ "boot" "lanzaboote" "enable" ] false config then
            "/run/fwupd-efi"
          else
            "${pkgs.fwupd-efi}/libexec/fwupd/efi"
        ))
      ];
    });
  };

  systemd.services.fwupd-refresh.enable = false;
  systemd.timers.fwupd-refresh.enable = false;
}
