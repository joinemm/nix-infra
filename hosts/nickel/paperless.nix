{ config, mkBackup, ... }:
{
  sops.secrets.paperless_admin_password.owner = config.services.paperless.user;

  services.paperless = {
    enable = true;
    dataDir = "/data/paperless";
    mediaDir = "/data/paperless/media";
    consumptionDir = "/data/paperless/consume";
    database.createLocally = true;
    domain = "paperless.lab.joinemm.dev";
    configureNginx = true;
    passwordFile = config.sops.secrets.paperless_admin_password.path;

    settings.PAPERLESS_ADMIN_USER = "admin";

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
