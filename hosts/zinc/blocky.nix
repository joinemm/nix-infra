{ pkgs, config, ... }:
{
  networking.firewall =
    let
      allowed = [
        config.services.blocky.settings.ports.http
        config.services.blocky.settings.ports.dns
      ];
    in
    {
      allowedTCPPorts = allowed;
      allowedUDPPorts = allowed;
    };

  services.blocky = {
    enable = true;
    settings = {
      prometheus.enable = true;

      ports = {
        dns = 53;
        http = 4000;
      };

      queryLog = {
        type = "postgresql";
        target = "user=blocky password=blocky host=/run/postgresql dbname=blocky sslmode=disable";
      };

      upstreams = {
        groups = {
          default = [
            # Cloudflare DNS over TLS
            "tcp-tls:1.1.1.1:853"
            "tcp-tls:1.0.0.1:853"
          ];
        };
      };

      customDNS = {
        mapping = {
          # access point pings this domain
          unifi = "192.168.1.4";

          # home network
          "router.lan" = "192.168.1.1";
          "ap.lan" = "192.168.1.2";
          "pi.lan" = "192.168.1.3";
          "nas.lan" = "192.168.1.4";
          "lab.joinemm.dev" = "192.168.1.4";
        };
      };

      # Use rDNS to ask the router dnsmasq service for client hostnames
      # https://dev.to/zer0ed/install-adguard-home-on-edgerouter-x-including-local-hostname-resoluion-using-dnsmasq-2hmc
      clientLookup = {
        upstream = "192.168.1.1:5353";
        singleNameOrder = [ 1 ];
        clients = {
          # local network
          router = [ "192.168.1.1" ];
          access-point = [ "192.168.1.2" ];
          roborock = [ "192.168.1.109" ];
          # tailscale addresses
          rome = [ "100.64.0.2" ];
          kyoto = [ "100.64.0.3" ];
          athens = [ "100.64.0.4" ];
          pixel = [ "100.64.0.5" ];
          thebes = [ "100.64.0.7" ];
        };
      };

      bootstrapDns = {
        upstream = "https://one.one.one.one/dns-query";
        ips = [
          "1.1.1.1"
          "1.0.0.1"
          "8.8.8.8"
        ];
      };

      caching = {
        minTime = "5m";
        maxTime = "30m";
        prefetching = true;
      };

      blocking = {
        loading.refreshPeriod = "12h";

        clientGroupsBlock = {
          default = [
            "ads"
            "security"
          ];
        };

        denylists = {
          ads = [ "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/pro.txt" ];
          security = [
            "https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/wildcard/tif.medium.txt"
            "https://blocklistproject.github.io/Lists/smart-tv.txt"
          ];
        };

        allowlists = {
          ads = [
            (pkgs.writeText "whitelist.txt" ''
              # this is where whitelisted domains would go
            '')
          ];
        };
      };
    };
  };
}
