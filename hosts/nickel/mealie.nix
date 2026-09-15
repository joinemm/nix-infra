{ config, ... }:
{
  sops.secrets.mealie_oidc_client_secret = { };
  sops.templates."mealie-oidc.env".content =
    "OIDC_CLIENT_SECRET=${config.sops.placeholder.mealie_oidc_client_secret}";

  services.mealie = {
    enable = true;

    listenAddress = "127.0.0.1";
    port = 9000;
    database.createLocally = true;
    credentialsFile = config.sops.templates."mealie-oidc.env".path;

    settings = {
      BASE_URL = "https://mealie.lab.joinemm.dev";
      OIDC_AUTH_ENABLED = true;
      OIDC_CONFIGURATION_URL = "https://auth.lab.joinemm.dev/.well-known/openid-configuration";
      OIDC_CLIENT_ID = "mealie";
      OIDC_ADMIN_GROUP = "admin";
      OIDC_PROVIDER_NAME = "Authelia";
    };
  };

  services.nginx.virtualHosts."mealie.lab.joinemm.dev" = {
    useACMEHost = "lab.joinemm.dev";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.mealie.port}";
    };
  };
}
