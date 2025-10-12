{ config, ... }:
{
  sops.secrets.umami_secret.owner = "root";

  services.umami = {
    enable = true;
    createPostgresqlDatabase = true;
    settings = {
      APP_SECRET_FILE = config.sops.secrets.umami_secret.path;
      DISABLE_TELEMETRY = true;
      PORT = 8800;
    };
  };

  services.nginx.virtualHosts."umami.joinemm.dev" = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.umami.settings.PORT}";
      proxyWebsockets = true;
      extraConfig = "proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;";
    };
  };
}
