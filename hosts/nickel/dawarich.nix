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
  services.dawarich = {
    enable = true;
    localDomain = domain;
    webPort = 3456;
    environment.APPLICATION_PROTOCOL = "https";
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
