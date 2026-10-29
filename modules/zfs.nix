{ pkgs, ... }:
{
  boot = {
    zfs = {
      package = pkgs.zfs_unstable;
      forceImportRoot = false;
    };
    kernelPackages = pkgs.linuxPackages;
    supportedFilesystems = [ "zfs" ];
  };

  services.zfs.autoScrub.enable = true;

  # zfs doesn't support Hibernation
  services.upower.criticalPowerAction = "HybridSleep";
}
