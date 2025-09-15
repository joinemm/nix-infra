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

  backupScript = pkgs.writeShellApplication {
    name = "backup";
    text = ''
      if [ "$1" = init ]; then
          echo "Initialising repository and exiting"
          restic -r "$BUCKET" init
          exit 0
      fi

      BACKUP_DIR="$1"
      DUMP_OPTIONS="--force --quick --single-transaction --extended-insert --order-by-primary"
      BUCKET="s3:s3.us-west-004.backblazeb2.com/misobot"

      # Signal healthcheck.io that the backup run started
      curl -m 10 --retry 5 "https://hc-ping.com/$HC_PING_KEY/db-backup/start"

      # Create our backup directory if not already there
      mkdir -p "$BACKUP_DIR"
      if [ ! -d "$BACKUP_DIR" ]; then
          echo "Not a directory: $BACKUP_DIR"
          exit 1
      fi

      # back up the backups because why not
      echo "Copying old backups to $BACKUP_DIR-yesterday"
      cp -r "$BACKUP_DIR" "$BACKUP_DIR"-yesterday

      # Dump our databases
      DATABASE_NAME=misobot
      echo "Dumping MySQL Database $DATABASE_NAME"
      # shellcheck disable=SC2086
      docker exec miso-bot-db \
          mariadb-dump --user=bot --password=botpw $DUMP_OPTIONS \
          --ignore-table="$DATABASE_NAME".sessions \
          "$DATABASE_NAME" >"$BACKUP_DIR"/"$DATABASE_NAME".sql

      DATABASE_NAME=shlink
      echo "Dumping MySQL Database $DATABASE_NAME"
      # shellcheck disable=SC2086
      docker exec miso-shlink-db \
          mariadb-dump --user=shlink --password=shlinkpw $DUMP_OPTIONS \
          --ignore-table="$DATABASE_NAME".sessions \
          "$DATABASE_NAME" >"$BACKUP_DIR"/"$DATABASE_NAME".sql

      echo "Uploading dumps to B2"

      restic -r "$BUCKET" backup "$BACKUP_DIR"

      echo "Forgetting old backups based on policy"
      RETENTION_POLICY="--keep-daily 7 --keep-weekly 4"
      # shellcheck disable=SC2086
      restic -r "$BUCKET" forget $RETENTION_POLICY

      echo "Pruning the bucket"
      restic -r "$BUCKET" prune

      # signal healthcheck.io that the backup ran fine
      curl -m 10 --retry 5 "https://hc-ping.com/$HC_PING_KEY/db-backup"
    '';
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

  disko.devices.disk.sda.device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_56638307";

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
      backup_env.owner = "root";
    };
  };

  systemd.services."miso-backup" = {
    path = [
      backupScript
    ]
    ++ (with pkgs; [
      curl
      restic
      docker-client
    ]);
    serviceConfig = {
      Type = "oneshot";
      EnvironmentFile = config.sops.secrets.backup_env.path;
      ExecStart = "backup /var/lib/miso/backups";
    };
  };

  systemd.timers."miso-backup" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 00:00:00";
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

  environment.systemPackages = [
    pkgs.busybox
    backupScript
  ];

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
