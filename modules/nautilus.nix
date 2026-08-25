{
  config,
  lib,
  pkgs,
  ...
}:
{
  services = {
    gvfs.enable = true;
    udisks2.mountOnMedia = true;
  };

  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "footclient";
  };

  environment.sessionVariables.NAUTILUS_4_EXTENSION_DIR = lib.mkForce "${config.system.path}/lib/nautilus/extensions-4";

  environment.systemPackages = with pkgs; [
    nautilus
    file-roller
    ouch
    evince # PDF thumbnails
  ];
}
