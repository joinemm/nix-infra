{
  lib,
  inputs,
  self,
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
      hetzner
      nginx
    ])
    inputs.disko.nixosModules.disko
    ../../disko/hetzner-osdisk.nix
  ];

  disko.devices.disk.sda.device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_56638307";

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "misobot-prod";
  system.stateVersion = "24.11";

  environment.systemPackages = with pkgs; [ busybox ];

  services.grafana = {
    enable = true;

    settings = {
      server = {
        http_port = 3300;
        http_addr = "127.0.0.1";
      };

      # disable telemetry
      analytics = {
        reporting_enabled = false;
        feedback_links_enabled = false;
      };
    };

    provision.datasources.settings.datasources = [
      {
        name = "prometheus";
        type = "prometheus";
        isDefault = true;
        url = "http://${config.services.prometheus.listenAddress}:${toString config.services.prometheus.port}/prometheus";
      }
    ];
  };

  services.prometheus = {
    enable = true;
    port = 9090;
    listenAddress = "0.0.0.0";
    webExternalUrl = "/prometheus/";
    checkConfig = true;
    globalConfig.scrape_interval = "15s";

    scrapeConfigs = [
      {
        job_name = "services";
        static_configs = [
          {
            targets = [
              "127.0.0.1:3000"
            ];
          }
        ];
      }
      {
        job_name = "hardware";
        static_configs = [
          {
            targets = [
              "127.0.0.1:9100"
            ];
          }
        ];
      }
    ];
  };

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  users.users.joonas.extraGroups = [ "docker" ];

  services.nginx.virtualHosts = {
    "monitoring.misobot.xyz" = {
      enableACME = true;
      forceSSL = true;
      locations."/prometheus/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.prometheus.port}";
      };

      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}";
        proxyWebsockets = true;
      };
    };

    "api.misobot.xyz" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:3000"; # port mapped in docker-compose
        # CORS
        extraConfig = ''
          add_header Access-Control-Allow-Origin "*";
        '';
      };
    };

    "url.misobot.xyz" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8080"; # port mapped in docker-compose
      };
    };
  };
}
