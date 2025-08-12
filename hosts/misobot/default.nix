{
  lib,
  inputs,
  self,
  pkgs,
  config,
  user,
  ...
}:
let
  ports = {
    api = 3000;
    shlink = 8080;
  };
in
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
    inputs.sops-nix.nixosModules.sops
    ../../disko/hetzner-osdisk.nix
  ];

  disko.devices.disk.os.device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_56638307";

  nixpkgs.hostPlatform = "x86_64-linux";
  networking.hostName = "misobot-prod";
  system.stateVersion = "24.11";

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      # github oauth app credentials
      github_client_id.owner = "grafana";
      github_client_secret.owner = "grafana";
      gatus_env.owner = "gatus";
    };
  };

  services.grafana = {
    enable = true;

    settings = {
      server = {
        http_port = 3300;
        http_addr = "127.0.0.1";
        domain = "monitoring.misobot.xyz";
        enforce_domain = true;
        root_url = "https://%(domain)s/";
      };

      # disable telemetry
      analytics = {
        reporting_enabled = false;
        feedback_links_enabled = false;
      };

      # github OIDC
      "auth.github" = {
        enabled = true;
        client_id = "$__file{${config.sops.secrets.github_client_id.path}}";
        client_secret = "$__file{${config.sops.secrets.github_client_secret.path}}";
        allowed_organizations = [ "miso-bot" ];
        allow_assign_grafana_admin = true;
        role_attribute_path = "login == joinemm && 'GrafanaAdmin'";
      };

      auth.disable_login_form = true;
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
              "127.0.0.1:${toString ports.api}"
            ];
          }
        ];
      }
      {
        job_name = "hardware";
        static_configs = [
          {
            targets = [
              "127.0.0.1:${toString config.services.prometheus.exporters.node.port}"
            ];
          }
        ];
      }
    ];
  };

  users.groups.gatus = { };
  users.users.gatus = {
    isSystemUser = true;
    group = "gatus";
  };
  services.gatus = {
    enable = true;
    environmentFile = config.sops.secrets.gatus_env.path;
    settings = {
      web.port = 4000;
      connectivity.checker = {
        target = "1.1.1.1:53";
        interval = "60s";
      };
      ui = {
        title = "Status | Miso Bot";
        description = "Status of Miso Bot services";
        header = "Miso Bot services";
        logo = "https://cdn.discordapp.com/avatars/500385855072894982/6364f6344f1c0eba50c6f699634407ca.webp?size=512";
        buttons = [
          {
            name = "Check Discord API status by clicking here";
            link = "https://discordstatus.com";
          }
        ];
      };
      endpoints = [
        {
          name = "Internal API";
          url = "http://127.0.0.1:${toString ports.api}/ping";
          conditions = [
            "[STATUS] == 200"
          ];
          alerts = [
            {
              type = "discord";
              send-on-resolved = true;
            }
          ];
        }
        {
          name = "External API";
          url = "https://api.misobot.xyz/ping";
          conditions = [
            "[STATUS] == 200"
          ];
          alerts = [
            {
              type = "discord";
              send-on-resolved = true;
            }
          ];
        }
        {
          name = "misobot.xyz";
          url = "https://misobot.xyz";
          conditions = [
            "[STATUS] == 200"
          ];
          alerts = [
            {
              type = "discord";
              send-on-resolved = true;
            }
          ];
        }
      ];
      alerting.discord = {
        webhook-url = "\${DISCORD_WEBHOOK_URL}";
      };
    };
  };

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  users.users.${user.name}.extraGroups = [ "docker" ];

  environment.systemPackages = with pkgs; [ busybox ];

  services.nginx.virtualHosts =
    let
      ssl = {
        enableACME = true;
        forceSSL = true;
      };
    in
    {
      "monitoring.misobot.xyz" = ssl // {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}";
          proxyWebsockets = true;
        };

        locations."/prometheus/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.prometheus.port}";
        };
      };

      "api.misobot.xyz" = ssl // {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString ports.api}";
          extraConfig = ''
            add_header Access-Control-Allow-Origin "*";
          '';
        };
      };

      "url.misobot.xyz" = ssl // {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString ports.shlink}";
        };
      };

      "status.misobot.xyz" = ssl // {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.gatus.settings.web.port}";
        };
      };
    };
}
