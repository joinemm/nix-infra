{ config, ... }:
{
  services.mealie = {
    enable = true; # TODO: fails to build right now

    listenAddress = "127.0.0.1";
    port = 9000;
    database.createLocally = true;

    settings = {
      BASE_URL = "https://mealie.lab.joinemm.dev";
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
