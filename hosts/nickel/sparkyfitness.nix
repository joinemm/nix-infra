{
  config,
  inputs,
  lib,
  mkBackup,
  pkgs,
  ...
}:
let
  domain = "fitness.lab.joinemm.dev";
  sparkyfitnessPackages = inputs.sparkyfitness.packages.${pkgs.stdenv.hostPlatform.system};

  databaseBackup = pkgs.writeShellApplication {
    name = "sparkyfitness-database-backup";
    text = ''
      ${lib.getExe' pkgs.util-linux "runuser"} -u postgres -- \
        ${lib.getExe' config.services.postgresql.package "pg_dump"} \
          --clean \
          --if-exists \
          --create \
          --username=postgres \
          --dbname=${lib.escapeShellArg config.services.sparkyfitness.database.name} \
        | ${lib.getExe pkgs.gzip}
    '';
  };

  databaseDump = "/run/restic-backups-sparkyfitness/sparkyfitness.sql.gz";
in
{
  imports = [
    inputs.sparkyfitness.nixosModules.default
  ];

  sops.secrets.sparkyfitness-env.owner = "root";

  services.sparkyfitness = {
    enable = true;
    backendPackage = sparkyfitnessPackages.sparkyfitness-server;
    frontendPackage = sparkyfitnessPackages.sparkyfitness-frontend;
    frontendUrl = "https://${domain}";
    environmentFile = config.sops.secrets.sparkyfitness-env.path;

    garmin.package = sparkyfitnessPackages.sparkyfitness-garmin;
    nginx.virtualHost = domain;
  };

  services.nginx.virtualHosts.${domain} = {
    useACMEHost = "lab.joinemm.dev";
    forceSSL = true;
  };

  services.restic.backups.sparkyfitness = mkBackup "sparkyfitness" {
    paths = [
      databaseDump
      "${config.services.sparkyfitness.stateDir}/uploads"
    ];
    backupPrepareCommand = ''
      umask 077
      ${lib.getExe databaseBackup} > ${databaseDump}
    '';
    backupCleanupCommand = ''
      ${lib.getExe' pkgs.coreutils "rm"} -f ${databaseDump}
    '';
  };

  systemd.services.restic-backups-sparkyfitness = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };
}
