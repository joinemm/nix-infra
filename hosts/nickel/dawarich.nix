{
  config,
  lib,
  mkBackup,
  pkgs,
  ...
}:
let
  domain = "dawarich.lab.joinemm.dev";

  # Drop override when nixpkgs#530697 lands in unstable
  # https://nixpkgs-tracker.ocfox.me/?pr=530697
  dawarichNixpkgs = pkgs.fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "51112299a9d0dfd771cbd1bc81a475245ccc6979";
    hash = "sha256-gnPebfMpdqngjhk9TX27ASnvxuqSOlE5nDK7C6YEsbg=";
  };

  dawarichPackage = pkgs.callPackage (dawarichNixpkgs + "/pkgs/by-name/da/dawarich/package.nix") { };

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
    package = dawarichPackage;
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
