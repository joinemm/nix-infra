{
  inputs,
  user,
  self,
  lib,
  pkgs,
  ...
}:
{
  imports = lib.flatten [
    (with self.profiles; [
      core
      workstation
    ])
    (with self.nixosModules; [
      laptop
      wayland
      secure-boot
      hibernate
    ])
    (with inputs.nixos-hardware.nixosModules; [
      lenovo-thinkpad-x1-11th-gen
    ])
    inputs.sops-nix.nixosModules.sops
    inputs.disko.nixosModules.disko
    ./disk-config.nix
  ];

  system.stateVersion = "25.11";
  nixpkgs.hostPlatform = "x86_64-linux";

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };

  networking = {
    hostName = "carbon";
  };

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

  # boot.initrd.luks.devices = {
  #   crypt = {
  #     device = "/dev/disk/by-partlabel/luks";
  #     allowDiscards = true;
  #     preLVM = true;
  #   };
  # };

  hardware.cpu.intel.updateMicrocode = true;

  hardware.graphics = {
    extraPackages = with pkgs; [
      intel-compute-runtime
      intel-media-driver
    ];
  };

  services.syncthing.settings.folders = {
    "code".enable = true;
    "notes".enable = true;
    "pictures".enable = true;
    "videos".enable = true;
    "work".enable = true;
    "documents".enable = true;
    "projects".enable = true;
  };

  services.fprintd.enable = true;

  # extra home-manager configuration
  home-manager.users."${user.name}" = {
    imports = [
      ../../modules/home/laptop.nix
    ];

    xdg.configFile."way-displays/cfg.yml".text = ''
      SCALING: FALSE
      AUTO_SCALE: FALSE
    '';
  };
}
