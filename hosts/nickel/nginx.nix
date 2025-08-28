{ config, user, ... }:
{
  # https://github.com/Radarr/Radarr/issues/5549#issuecomment-743980409
  services.nginx.proxyTimeout = "180s";

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
      "fs.${labDomain}" = labCert // {
        locations."/".proxyPass = "http://127.0.0.1:${toString config.services.copyparty.settings.p}";
      };
      "deluge.${labDomain}" = labCert // {
        locations."/".proxyPass = "http://127.0.0.1:${toString config.services.deluge.web.port}";
      };
      "prowlarr.${labDomain}" = labCert // {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.nixarr.prowlarr.port}";
          proxyWebsockets = true;
        };
      };
      "radarr.${labDomain}" = labCert // {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.nixarr.radarr.port}";
          proxyWebsockets = true;
        };
      };
      "sonarr.${labDomain}" = labCert // {
        locations."/" = {
          proxyPass = "http://127.0.0.1:8989";
          proxyWebsockets = true;
        };
      };
      "bazarr.${labDomain}" = labCert // {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.nixarr.bazarr.port}";
          proxyWebsockets = true;
        };
      };
      "jellyseerr.${labDomain}" = labCert // {
        locations."/".proxyPass = "http://127.0.0.1:${toString config.nixarr.jellyseerr.port}";
      };
      "jellyfin.${labDomain}" = labCert // {
        locations."/".proxyPass = "http://127.0.0.1:8096";
      };
      "webdav.${labDomain}" = labCert // {
        locations."/".proxyPass = "http://127.0.0.1:9999";
        extraConfig = ''
          client_max_body_size 0;
        '';
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
      "unifi.${labDomain}" = labCert // {
        locations."/" = {
          proxyPass = "https://localhost:8443";
          proxyWebsockets = true;
        };
      };
      "mealie.${labDomain}" = labCert // {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString config.services.mealie.port}";
        };
      };
      "traggo.${labDomain}" = labCert // {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString 3030}";
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
