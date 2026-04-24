{
  config,
  ...
}:
{
  # https://github.com/Radarr/Radarr/issues/5549#issuecomment-743980409
  services.nginx.proxyTimeout = "180s";

  # set global max body size to unlimited, this applies to the http->https redirect blocks
  # that get generated when using forceSSL=true
  services.nginx.clientMaxBodySize = "0";

  # map local port to the vpn port so it's accessible from localhost
  services.nginx.virtualHosts =
    let
      labDomain = "lab.joinemm.dev";
      labCert = {
        useACMEHost = "lab.joinemm.dev";
        forceSSL = true;
      };
    in
    {
      "webdav.${labDomain}" = labCert // {
        locations."/".proxyPass = "http://127.0.0.1:9999";
        extraConfig = ''
          client_max_body_size 0;
          proxy_request_buffering off;
          client_body_buffer_size 1024k;
        '';
      };
      "scrutiny.${labDomain}" = labCert // {
        locations."/".proxyPass =
          "http://127.0.0.1:${toString config.services.scrutiny.settings.web.listen.port}";
      };
      "unifi.${labDomain}" = labCert // {
        locations."/" = {
          proxyPass = "https://localhost:8443";
          proxyWebsockets = true;
        };
      };
      "traggo.${labDomain}" = labCert // {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString 3030}";
        };
      };
      "kimai.${labDomain}" = labCert;
    };

  users.users.nginx.extraGroups = [ "acme" ];

  security.acme = {
    certs."lab.joinemm.dev" = {
      domain = "lab.joinemm.dev";
      extraDomainNames = [ "*.lab.joinemm.dev" ];
      dnsProvider = "cloudflare";
      dnsPropagationCheck = true;
      environmentFile = config.sops.secrets.cloudflare_env.path;
    };
  };
}
