{
  config,
  lib,
  pkgs,
  self,
  ...
}:

let
  cfg = config.services.floppy;
  inherit (cfg) package;
  redisService = "redis-floppy.service";
  environment = {
    BACKUP_DIR = cfg.backupDir;
    DEBUG = "False";
    DEMO_ACCOUNT_ENABLED = "False";
    FLOPPY_DATA_DIR = cfg.dataDir;
    FLOPPY_REDIS_MAXMEMORY = "0";
    LOG_DIR = cfg.logDir;
    REDIS_URL = "redis://127.0.0.1:${toString cfg.redis.port}";
  }
  // lib.mapAttrs (
    _: value: if lib.isBool value then lib.boolToString value else toString value
  ) cfg.settings;
  dependencies = lib.optional cfg.redis.createLocally redisService;
  serviceConfig = {
    User = "floppy";
    Group = "floppy";
    WorkingDirectory = "${package}/lib/floppy";
    EnvironmentFile = lib.optional (cfg.environmentFile != null) cfg.environmentFile;
    Restart = "on-failure";
    RestartSec = "5s";
    UMask = "0027";
  };
in
{
  options.services.floppy = {
    enable = lib.mkEnableOption "Floppy media tracker";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.floppy;
      defaultText = lib.literalExpression "self.packages.\${pkgs.stdenv.hostPlatform.system}.floppy";
      description = "Floppy package to use.";
    };

    environmentFile = lib.mkOption {
      type = with lib.types; nullOr path;
      default = null;
      example = "/run/secrets/floppy.env";
      description = ''
        Environment file containing at least Floppy's required SECRET value.
        This file can also contain provider API keys and other sensitive settings.
      '';
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/floppy/db";
      description = "Directory containing the SQLite database and other persistent data.";
    };

    backupDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/floppy/backups";
      description = "Directory containing Floppy exports and database snapshots.";
    };

    logDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/log/floppy";
      description = "Directory containing Floppy's application log.";
    };

    settings = lib.mkOption {
      type =
        with lib.types;
        attrsOf (oneOf [
          bool
          int
          str
        ]);
      default = { };
      example = {
        ALLOWED_HOSTS = "floppy.example.com";
        REGISTRATION = false;
        URLS = "https://floppy.example.com";
        USE_X_FORWARDED = true;
      };
      description = ''
        Non-secret environment variables passed to Floppy. Put secrets in
        services.floppy.environmentFile to keep them out of the Nix store.
      '';
    };

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "Address on which Nginx exposes Floppy.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8000;
      description = "Port on which Nginx exposes Floppy.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to open the Floppy port in the firewall.";
    };

    nginx.virtualHost = lib.mkOption {
      type = lib.types.str;
      default = "floppy";
      description = "Name of the Nginx virtual host used for Floppy.";
    };

    redis = {
      createLocally = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to create a local Redis instance for Floppy.";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 6380;
        description = "Port of the local Redis instance, or the port used by the default REDIS_URL.";
      };

      maxMemory = lib.mkOption {
        type = lib.types.str;
        default = "256mb";
        description = "Memory limit for the local Redis instance.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.environmentFile != null;
        message = "services.floppy.environmentFile must point to a file containing SECRET.";
      }
    ];

    users = {
      users.floppy = {
        isSystemUser = true;
        group = "floppy";
        home = cfg.dataDir;
      };
      groups.floppy = { };
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 floppy floppy - -"
      "d ${cfg.backupDir} 0750 floppy floppy - -"
      "d ${cfg.logDir} 0750 floppy floppy - -"
    ];

    services.redis.servers.floppy = lib.mkIf cfg.redis.createLocally {
      enable = true;
      bind = "127.0.0.1";
      port = cfg.redis.port;
      appendOnly = true;
      save = [ ];
      settings = {
        maxmemory = cfg.redis.maxMemory;
        maxmemory-policy = "volatile-lru";
      };
    };

    systemd.services = {
      floppy = {
        description = "Floppy media tracker";
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ] ++ dependencies;
        after = [ "network-online.target" ] ++ dependencies;
        inherit environment;
        serviceConfig = serviceConfig // {
          ExecStartPre = "${package}/bin/floppy-manage migrate --noinput";
          ExecStart = "${package}/bin/floppy --bind 127.0.0.1:8001";
        };
      };

      floppy-celery = {
        description = "Floppy background worker";
        wantedBy = [ "multi-user.target" ];
        requires = [ "floppy.service" ];
        after = [ "floppy.service" ];
        partOf = [ "floppy.service" ];
        environment = environment // {
          FLOPPY_PROCESS_ROLE = "background";
        };
        serviceConfig = serviceConfig // {
          ExecStart = "${package}/bin/floppy-celery --app config worker --beat --scheduler django --queues celery,interactive,discover --hostname=celery@%H --loglevel INFO --without-mingle --without-gossip";
        };
      };
    };

    services.nginx = {
      enable = true;
      virtualHosts.${cfg.nginx.virtualHost} = {
        listen = [
          {
            addr = cfg.listenAddress;
            inherit (cfg) port;
          }
        ];
        extraConfig = ''
          client_max_body_size 512M;
          add_header X-Frame-Options "SAMEORIGIN" always;
          add_header X-Content-Type-Options "nosniff" always;
          add_header Referrer-Policy "no-referrer-when-downgrade" always;
        '';
        locations = {
          "/" = {
            proxyPass = "http://127.0.0.1:8001";
            recommendedProxySettings = true;
          };
          "/static/" = {
            alias = "${package}/lib/floppy/staticfiles/";
            extraConfig = ''
              expires 30d;
              add_header Cache-Control "public";
            '';
          };
        };
      };
    };

    networking.firewall.allowedTCPPorts = lib.optional cfg.openFirewall cfg.port;
  };
}
