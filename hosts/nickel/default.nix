{
  self,
  lib,
  inputs,
  pkgs,
  config,
  user,
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
    ])
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops
    inputs.home-manager.nixosModules.home-manager
    ./arr.nix
    ./disk-config.nix
    ./gatus.nix
    ./home-assistant.nix
    ./homepage.nix
    ./nfs.nix
    ./nginx.nix
  ];

  networking.hostName = "nickel";
  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "24.11";

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      cloudflare_env.owner = "root";
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

  services.immich = {
    enable = true;
    host = "127.0.0.1";
  };

  users.users."${user.name}".extraGroups = [ "immich" ];

  services.immich-public-proxy = {
    enable = true;
    openFirewall = true;
    port = 2284;
    immichUrl = "http://127.0.0.1:${toString config.services.immich.port}";
  };

  services.audiobookshelf = {
    enable = true;
    group = "media";
  };

  networking.firewall = {
    allowedTCPPorts = [ 9999 ];
    allowedUDPPorts = [ 9999 ];
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

  services.unifi = {
    enable = true;
    unifiPackage = pkgs.unifi8;
    mongodbPackage = pkgs.mongodb-6_0;
    openFirewall = true;
  };

  # init home-manager
  home-manager.users.${user.name}.home.stateVersion = config.system.stateVersion;

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
