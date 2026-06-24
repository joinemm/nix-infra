{
  self,
  lib,
  inputs,
  pkgs,
  config,
  ...
}:
{
  imports = lib.flatten [
    (with self.profiles; [
      core
      server
    ])
    (with self.nixosModules; [
      locale
      systemd-boot
      tailscale
      nginx
      bluetooth
      nebula
    ])
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops
    inputs.nix-topology.nixosModules.default
    inputs.hjem.nixosModules.default
    ./arr.nix
    ./disk-config.nix
    ./gatus.nix
    ./home-assistant.nix
    ./immich.nix
    ./homepage.nix
    ./network-share.nix
    ./nginx.nix
    ./mealie.nix
    ./monitoring.nix
    ./paperless.nix
    ./backup.nix
    ./webos-devmode.nix
  ];

  networking.hostName = "nickel";
  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "24.11";

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      cloudflare_env.owner = "root";
      nebula_key.owner = config.nebula.user;
    };
  };

  networking.useDHCP = true;

  boot.kernelModules = [ "kvm-intel" ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];

  # Intel hardware acceleration
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libva-vdpau-driver
      intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
      vpl-gpu-rt # QSV on 11th gen or newer
    ];
  };

  # enable vaapi on OS-level
  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };

  fileSystems = {
    # Storage drives are formatted by hand
    "/mnt/disk1" = {
      device = "/dev/disk/by-uuid/f8527518-67e5-45a2-b2d2-f4c197b9d80f";
      fsType = "xfs";
    };

    "/mnt/disk2" = {
      device = "/dev/disk/by-uuid/757bbc28-5fd7-4a46-8be0-3082bb5fd52c";
      fsType = "xfs";
    };

    # Merge all disks to a fuse mount at /data
    "/data" = {
      device = "/mnt/disk*";
      fsType = "fuse.mergerfs";
      options = [
        "cache.files=full" # required for deluge to work properly
        "dropcacheonclose=true"
        "category.create=mfs"
        "func.getattr=newest" # required for jellyfin to find new files
      ];
    };
  };

  services.scrutiny = {
    enable = true;
    collector.enable = true;
    settings.web.listen.port = 5500;
  };

  nebula = {
    enable = true;
    cert = ./nebula.crt;
    key = config.sops.secrets.nebula_key.path;
  };

  services.nebula.networks.milkyway = {
    firewall = {
      inbound = [
        {
          port = "8096";
          proto = "tcp";
          group = "funnel";
        }
        {
          port = "2284";
          proto = "tcp";
          group = "funnel";
        }
        {
          port = "5055";
          proto = "tcp";
          group = "funnel";
        }
        {
          port = "3210";
          proto = "tcp";
          group = "funnel";
        }
      ];
    };
  };

  networking.firewall = {
    allowedTCPPorts = [
      9999
      2283
    ];
    allowedUDPPorts = [
      9999
      2283
    ];
  };

  services.kimai.sites."kimai.lab.joinemm.dev" = {
    settings = { };
  };

  services.unifi = {
    enable = true;
    openFirewall = true;
  };

  environment.systemPackages = with pkgs; [
    mergerfs
    lm_sensors
    rclone
  ];

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune.enable = true;
  };
}
