{ pkgs, ... }:
{
  boot = {
    kernelPackages = pkgs.linuxPackages_6_16;
    zfs.package = pkgs.zfs_unstable;
  };

  # zfs doesn't support Hibernation
  services.upower.criticalPowerAction = "HybridSleep";
}
