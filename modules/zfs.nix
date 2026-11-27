{ inputs, pkgs, ... }:
{
  imports = [
    (inputs.nixos-images + "/nix/latest-zfs-kernel.nix")
  ];

  boot = {
    zfs = {
      package = pkgs.zfs_unstable;
      forceImportRoot = false;
    };
    supportedFilesystems = [ "zfs" ];
  };

  services.zfs.autoScrub.enable = true;

  # zfs doesn't support Hibernation
  services.upower.criticalPowerAction = "HybridSleep";
}
