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
    ./backup.nix
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

  services.vnstat.enable = true;

  services.scrutiny = {
    enable = true;
    collector.enable = true;
    settings.web.listen.port = 5500;
  };

  systemd.services.traggo = {
    wantedBy = [ "multi-user.target" ];
    environment = {
      TRAGGO_PORT = toString 3030;
      TRAGGO_DEFAULT_USER_NAME = "admin";
      TRAGGO_DEFAULT_USER_PASS = "admin";
    };
    serviceConfig = {
      DynamicUser = true;
      StateDirectory = "traggo";
      WorkingDirectory = "/var/lib/traggo";
      Restart = "on-failure";
      ExecStart = lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.traggo;
    };
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

  systemd.services."rclone-webdav" = {
    after = [ "network.target" ];
    unitConfig = {
      RequiresMountsFor = "/data";
    };
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = 5;
      ExecStart = "${lib.getExe pkgs.rclone} serve webdav /data/share/ --addr 0.0.0.0:9999";
    };
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
