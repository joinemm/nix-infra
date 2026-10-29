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
      zfs
    ])
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops
    inputs.nix-topology.nixosModules.default
    inputs.hjem.nixosModules.default
    ./arr.nix
    ./audiobookshelf.nix
    ./scrutiny.nix
    ./unifi.nix
    ./authelia.nix
    ./disk-config.nix
    ./home-assistant.nix
    ./immich.nix
    ./lldap.nix
    ./network-share.nix
    ./nginx.nix
    ./mealie.nix
    ./monitoring.nix
    ./paperless.nix
    ./printing.nix
    ./sparkyfitness.nix
    ./backup.nix
    # Enable boot-recovery.nix when early-boot SSH recovery is needed.
    ./encrypted-data.nix
    ./dawarich.nix
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
  networking.enableIPv6 = false;

  boot.kernelModules = [ "kvm-intel" ];

  networking.hostId = "deab5f10";

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
          port = "9091";
          proto = "tcp";
          group = "funnel";
        }
        {
          port = "17170";
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

  environment.systemPackages = with pkgs; [
    lm_sensors
    rclone
  ];

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune.enable = true;
  };
}
