{ config, mkBackup, ... }:
let
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
    dataDir = "/data/paperless";
    mediaDir = "/data/paperless/media";
    consumptionDir = "/data/paperless/consume";
    database.createLocally = true;
    domain = "paperless.lab.joinemm.dev";
    configureNginx = true;
    passwordFile = config.sops.secrets.paperless_admin_password.path;
    environmentFile = config.sops.templates."paperless-oidc.env".path;

    settings = {
      PAPERLESS_ADMIN_USER = "admin";
      PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
      PAPERLESS_SOCIAL_ACCOUNT_SYNC_GROUPS = true;
      PAPERLESS_SOCIAL_ACCOUNT_SYNC_SUPERUSER_GROUP = "superuser";
      PAPERLESS_SOCIAL_ACCOUNT_SYNC_STAFF_GROUP = "admin";
    };

    exporter = {
      enable = true;
      onCalendar = null;
    };
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
}
