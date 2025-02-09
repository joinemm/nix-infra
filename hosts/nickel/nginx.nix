{ config, user, ... }:
{
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
      # proxy from vpn confinement to localhost
      "127.0.0.1:${toString config.services.deluge.web.port}" = {
        listen = [
          {
            addr = "0.0.0.0";
            inherit (config.services.deluge.web) port;
          }
        ];
        locations."/" = {
          proxyWebsockets = true;
          proxyPass = "http://${config.vpnNamespaces.wg.namespaceAddress}:${toString config.services.deluge.web.port}";
        };
      };

      # proxies on domain with https, only accessible within local network
      "${labDomain}" = labCert // {
        locations."/".proxyPass =
          "http://127.0.0.1:${toString config.services.homepage-dashboard.listenPort}";
      };
      "deluge.${labDomain}" = labCert // {
        locations."/".proxyPass = "http://127.0.0.1:${toString config.services.deluge.web.port}";
      };
      "prowlarr.${labDomain}" = labCert // {
        locations."/".proxyPass = "http://127.0.0.1:9696";
      };
      "radarr.${labDomain}" = labCert // {
        locations."/".proxyPass = "http://127.0.0.1:7878";
      };
      "sonarr.${labDomain}" = labCert // {
        locations."/".proxyPass = "http://127.0.0.1:8989";
      };
      "bazarr.${labDomain}" = labCert // {
        locations."/".proxyPass = "http://127.0.0.1:6767";
      };
      "jellyseerr.${labDomain}" = labCert // {
        locations."/".proxyPass = "http://127.0.0.1:5055";
      };
      "jellyfin.${labDomain}" = labCert // {
        locations."/".proxyPass = "http://127.0.0.1:8096";
      };
      "immich.${labDomain}" = labCert // {
        locations."/".proxyPass = "http://127.0.0.1:${toString config.services.immich.port}";
        extraConfig = ''
          client_max_body_size 0;
        '';
      };
      "scrutiny.${labDomain}" = labCert // {
        locations."/".proxyPass =
          "http://127.0.0.1:${toString config.services.scrutiny.settings.web.listen.port}";
      };
      "status.${labDomain}" = labCert // {
        locations."/".proxyPass = "http://127.0.0.1:${toString config.services.gatus.settings.web.port}";
      };
      "home.${labDomain}" = labCert // {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.home-assistant.config.http.server_port}";
          proxyWebsockets = true;
        };
      };
      "audio.${labDomain}" = labCert // {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.audiobookshelf.port}";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_redirect http:// $scheme://;
            client_max_body_size 0;
          '';
        };
      };
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

  security.acme = {
    acceptTerms = true;
    defaults.email = user.email;
  };
}
