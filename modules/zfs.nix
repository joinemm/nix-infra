{ pkgs, ... }:
{
  boot = {
    kernelPackages = pkgs.linuxPackages_6_17;
    zfs.package = pkgs.zfs_unstable;
  };

  # zfs doesn't support Hibernation
  services.upower.criticalPowerAction = "HybridSleep";
}
