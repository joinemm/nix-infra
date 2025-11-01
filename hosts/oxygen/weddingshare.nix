{
  pkgs,
  self,
  lib,
  config,
  ...
}:
let
  inherit (self.packages.${pkgs.system}) weddingshare;
  cfg = config.services.weddingshare;
in
{
  options.services.weddingshare = {
    enable = lib.mkEnableOption "Enable weddingshare service";
    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
    };
    uploadsDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/WeddingShare/uploads";
    };
    settings = {
      title = lib.mkOption {
        type = lib.types.str;
        default = "WeddingShare";
      };
      baseUrl = lib.mkOption {
        type = lib.types.str;
        default = "localhost:5000";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    users = {
      users.weddingshare = {
        isSystemUser = true;
        group = "weddingshare";
      };
      groups.weddingshare = { };
    };

    systemd.tmpfiles.rules = [
      "L+ /var/lib/WeddingShare/wwwroot 0770 weddingshare weddingshare - ${weddingshare}/lib/WeddingShare/wwwroot"
      "d ${cfg.uploadsDir} 0770 weddingshare weddingshare - -"
      "d /var/lib/WeddingShare/custom_resources 0770 weddingshare weddingshare - -"
      "d /var/lib/WeddingShare/thumbnails 0770 weddingshare weddingshare - -"
      (lib.mkIf (
        cfg.uploadsDir != "/var/lib/WeddingShare/uploads"
      ) "L+ /var/lib/WeddingShare/uploads 0770 weddingshare weddingshare - ${cfg.uploadsDir}")
    ];

    systemd.services.weddingshare = {
      wantedBy = [ "multi-user.target" ];
      environment = {
        DOTNET_ENVIRONMENT = "Production";
        DATABASE_TYPE = "sqlite";
        ACCOUNT_OWNER_LOG_PASSWORD = "false";

        # override any manual config with env variables
        DATABASE_SYNC_FROM_CONFIG = "true";
        POLICIES_ENABLED = "false";
        TITLE = cfg.settings.title;
        BASE_URL = cfg.settings.baseUrl;
      };
      serviceConfig = {
        User = "weddingshare";
        Group = "weddingshare";
        Restart = "always";
        ExecStart = "${weddingshare}/bin/WeddingShare";
        StateDirectory = "WeddingShare";
        WorkingDirectory = "/var/lib/WeddingShare";
        EnvironmentFile = cfg.environmentFile;
      };
    };
  };
}
