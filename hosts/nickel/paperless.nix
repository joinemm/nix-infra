{
  config,
  mkBackup,
  pkgs,
  ...
}:
let
  storagePaths = [
    config.services.paperless.mediaDir
    config.services.paperless.consumptionDir
    "${config.services.paperless.mediaDir}/documents/thumbnails"
  ];
  oidcProviders = {
    openid_connect = {
      SCOPE = [
        "openid"
        "profile"
        "email"
        "groups"
      ];
      OAUTH_PKCE_ENABLED = true;
      APPS = [
        {
          provider_id = "authelia";
          name = "Authelia";
          client_id = "paperless";
          secret = config.sops.placeholder.paperless_oidc_client_secret;
          settings = {
            server_url = "https://auth.lab.joinemm.dev";
            token_auth_method = "client_secret_basic";
          };
        }
      ];
    };
  };
in
{
  sops.secrets = {
    paperless_admin_password.owner = config.services.paperless.user;
    paperless_oidc_client_secret.owner = config.services.paperless.user;
  };
  sops.templates."paperless-oidc.env" = {
    owner = config.services.paperless.user;
    content = ''
      PAPERLESS_SOCIALACCOUNT_PROVIDERS='${builtins.toJSON oidcProviders}'
    '';
  };

  services.paperless = {
    enable = true;
    dataDir = "/var/lib/paperless";
    mediaDir = "/data/documents/media";
    consumptionDir = "/data/documents/consume";
    database.createLocally = true;
    domain = "paperless.lab.joinemm.dev";
    configureNginx = true;
    passwordFile = config.sops.secrets.paperless_admin_password.path;
    environmentFile = config.sops.templates."paperless-oidc.env".path;

    settings = {
      PAPERLESS_ADMIN_USER = "admin";
      PAPERLESS_CONSUMER_RECURSIVE = true;
      PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
      PAPERLESS_SOCIAL_ACCOUNT_SYNC_GROUPS = true;
      PAPERLESS_SOCIAL_ACCOUNT_SYNC_SUPERUSER_GROUP = "superuser";
      PAPERLESS_SOCIAL_ACCOUNT_SYNC_STAFF_GROUP = "admin";
    };

    exporter = {
      enable = true;
      onCalendar = null;
      directory = "/data/backups/paperless";
    };
  };

  systemd.tmpfiles.rules =
    map (user: "d ${config.services.paperless.consumptionDir}/${user} 0700 paperless paperless - -")
      [
        "joonas"
        "julia"
      ];

  systemd.services.paperless-storage-setup = {
    unitConfig.RequiresMountsFor = [
      config.services.paperless.mediaDir
      config.services.paperless.consumptionDir
    ];
    after = [ "systemd-tmpfiles-setup.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.coreutils}/bin/install -d -m 0700 -o paperless -g paperless \
        /var/lib/paperless/thumbnails \
        ${config.services.paperless.mediaDir}/documents
      # Keep the documents parent writable; systemd creates the bind target.
      ${pkgs.coreutils}/bin/chown paperless:paperless ${config.services.paperless.mediaDir}
      ${pkgs.coreutils}/bin/chmod 0700 ${config.services.paperless.mediaDir}
    '';
  };

  services.nginx.virtualHosts."paperless.lab.joinemm.dev" = {
    useACMEHost = "lab.joinemm.dev";
    forceSSL = true;
  };

  services.restic.backups.paperless = mkBackup "paperless" {
    paths = [
      config.services.paperless.exporter.directory
    ];
  };

  systemd.services.restic-backups-paperless = {
    requires = [ "paperless-exporter.service" ];
    after = [ "paperless-exporter.service" ];
  };
  fileSystems."${config.services.paperless.mediaDir}/documents/thumbnails" = {
    device = "/var/lib/paperless/thumbnails";
    fsType = "none";
    options = [
      "bind"
      "noauto"
      "nofail"
      "x-systemd.requires=paperless-storage-setup.service"
    ];
  };
  systemd.services.paperless-consumer.unitConfig.RequiresMountsFor = storagePaths;
  systemd.services.paperless-scheduler.unitConfig.RequiresMountsFor = storagePaths;
  systemd.services.paperless-task-queue.unitConfig.RequiresMountsFor = storagePaths;
  systemd.services.paperless-web.unitConfig.RequiresMountsFor = storagePaths;
  systemd.services.paperless-exporter.unitConfig.RequiresMountsFor = storagePaths ++ [
    config.services.paperless.exporter.directory
  ];
}
