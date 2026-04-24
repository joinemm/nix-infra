{ lib, config, ... }:
let
  backupArgs = {
    initialize = true;

    environmentFile = config.sops.secrets.restic_env.path;
    repositoryFile = config.sops.secrets.restic_repo.path;
    passwordFile = config.sops.secrets.restic_password.path;

    pruneOpts = [
      "--keep-daily 3"
      "--keep-weekly 2"
      "--keep-monthly 1"
    ];

    timerConfig = {
      OnCalendar = "daily";
      RandomizedDelaySec = "5h";
    };

    extraBackupArgs = [
      "--host ${config.networking.hostName}"
    ];
  };

  mkBackup =
    name: attrs:
    lib.mkMerge [
      backupArgs
      {
        pruneOpts = lib.mkAfter [ "--tag ${name}" ];
        extraBackupArgs = lib.mkAfter [ "--tag ${name}" ];
      }
      attrs
    ];
in
{
  _module.args.mkBackup = mkBackup;

  sops.secrets = {
    restic_env.owner = "root";
    restic_repo.owner = "root";
    restic_password.owner = "root";
  };
}
