{
  config,
  lib,
  mkBackup,
  pkgs,
  ...
}:
let
  domain = "dawarich.lab.joinemm.dev";

  databaseBackup = pkgs.writeShellApplication {
    name = "dawarich-database-backup";
    text = ''
      ${lib.getExe' pkgs.util-linux "runuser"} -u postgres -- \
        ${lib.getExe' config.services.postgresql.package "pg_dump"} \
          --clean \
          --if-exists \
          --create \
          --username=postgres \
          --dbname=${lib.escapeShellArg config.services.dawarich.database.name} \
        | ${lib.getExe pkgs.gzip}
    '';
  };
in
{
  sops.secrets = {
    dawarich-geocoding-env.owner = "dawarich";
    dawarich_oidc_client_secret = { };
  };
  sops.templates."dawarich-oidc.env" = {
    owner = "dawarich";
    content = "OIDC_CLIENT_SECRET=${config.sops.placeholder.dawarich_oidc_client_secret}";
  };

  services.dawarich = {
    enable = true;
    localDomain = domain;
    webPort = 3456;
    environment = {
      APPLICATION_PROTOCOL = "https";
      OIDC_CLIENT_ID = "dawarich";
      OIDC_ISSUER = "https://auth.lab.joinemm.dev";
      OIDC_PKCE_ENABLED = "true";
      OIDC_PROVIDER_NAME = "Authelia";
      OIDC_REDIRECT_URI = "https://${domain}/users/auth/openid_connect/callback";
    };
    extraEnvFiles = [
      config.sops.secrets.dawarich-geocoding-env.path
      config.sops.templates."dawarich-oidc.env".path
    ];
  };

  services.nginx.virtualHosts.${domain} = {
    useACMEHost = "lab.joinemm.dev";
    forceSSL = true;
  };

  services.restic.backups.dawarich = mkBackup "dawarich" {
    command = [ (lib.getExe databaseBackup) ];
    extraBackupArgs = [
      "--stdin-filename=dawarich.sql.gz"
    ];
  };

  systemd.services.restic-backups-dawarich = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };

  users.users.dawarich = {
    isSystemUser = true;
    extraGroups = [ "dawarich" ];
  };

  users.groups.dawarich = { };
}
