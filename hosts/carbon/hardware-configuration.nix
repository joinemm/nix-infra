{
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    initrd.availableKernelModules = [
      "xhci_pci"
      "thunderbolt"
      "nvme"
      "usb_storage"
      "sd_mod"
    ];
    initrd.kernelModules = [ "i915" ];
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
  };

  fileSystems = {
    "/" = {
      device = "tank/root";
      fsType = "zfs";
    };

    "/home" = {
      device = "tank/home";
      fsType = "zfs";
    };

    "/nix" = {
      device = "tank/nix";
      fsType = "zfs";
    };

    "/var" = {
      device = "tank/var";
      fsType = "zfs";
    };

    "/tmp" = {
      device = "tank/tmp";
      fsType = "zfs";
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/DE7A-2CD6";
      fsType = "vfat";
      options = [ "umask=0077" ];
    };
  };

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
