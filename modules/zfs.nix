{ pkgs, ... }:
{
  boot = {
    zfs.package = pkgs.zfs_unstable;
    zfs.forceImportRoot = false;
  };

  # zfs doesn't support Hibernation
  services.upower.criticalPowerAction = "HybridSleep";
}
