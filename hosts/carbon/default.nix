{
  inputs,
  self,
  config,
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
      tpm
      keyd
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

  networking.hostName = "carbon";

  boot = {
    initrd.availableKernelModules = [
      "xhci_pci"
      "thunderbolt"
      "nvme"
      "usb_storage"
      "sd_mod"
    ];

    kernelModules = [ "kvm-intel" ];

    # use experimental Xe driver
    kernelParams = [
      # graphics chip's id: lspci -nn | grep VGA
      "i915.force_probe=!a7a1"
      "xe.force_probe=a7a1"
    ];
    initrd.kernelModules = [
      "xe"
    ];
  };

  hardware = {
    cpu.intel.updateMicrocode = true;

    graphics = {
      extraPackages = with pkgs; [
        intel-media-driver
        vpl-gpu-rt
        intel-compute-runtime
      ];
    };

    trackpoint = {
      enable = true;
      emulateWheel = true;
    };
  };

  services.fstrim.enable = true;

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

  environment.etc."way-displays/cfg.yaml".text = ''
    SCALING: FALSE
    AUTO_SCALE: FALSE
  '';

  services.niks3-auto-upload.enable = true;

  systemd.services.syncthing-init.wantedBy = lib.mkForce [ "syncthing.service" ];

  # extra home-manager configuration
  home-manager.users."${config.owner}" = {
    imports = [
      self.homeModules.laptop
    ];

    programs.niri.settings.outputs."eDP-1" = {
      mode = {
        width = 1920;
        height = 1200;
      };
      scale = 1;
      position = {
        x = 0;
        y = 0;
      };
    };

    programs.foot.fontSize = 12;

    sops.defaultSopsFile = ./secrets.yaml;

    # home.file =
    #   let
    #     stignore = ''
    #       #include .stglobalignore
    #     '';
    #   in
    #   {
    #     "code/.stignore".text = stignore;
    #     "notes/.stignore".text = stignore;
    #     "pictures/.stignore".text = stignore;
    #     "videos/.stignore".text = stignore;
    #     "work/.stignore".text = stignore;
    #     "documents/.stignore".text = stignore;
    #     "projects/.stignore".text = stignore;
    #   };
  };
}
