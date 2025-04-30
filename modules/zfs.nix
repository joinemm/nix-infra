{ pkgs, ... }:
{
  boot = {
    kernelPackages = pkgs.linuxPackages_6_13;
    zfs.package = pkgs.zfs_unstable;
  };

  # zfs doesn't support Hibernation
  services.upower.criticalPowerAction = "HybridSleep";
}
