{
  pkgs,
  lib,
  config,
  ...
}:
{
  services.postgresql = {
    enable = true;
    authentication = lib.mkForce ''
      local all all trust
    '';
    ensureDatabases = [
      "headscale"
    ];
    ensureUsers = [
      {
        name = "headscale";
        ensureDBOwnership = true;
      }
    ];
  };
  services.headscale = {
    enable = true;
    port = 8085;
    settings = {
      server_url = "https://portal.joinemm.dev";
      metrics_listen_addr = "127.0.0.1:8095";
      prefixes = {
        v4 = "100.64.0.0/10";
        v6 = "fd7a:115c:a1e0::/48";
      };
      database = {
        type = "postgres";
        postgres = {
          host = "/run/postgresql";
          name = "headscale";
          user = "headscale";
        };
      };
      dns = {
        override_local_dns = true;
        base_domain = "tail.net";
        magic_dns = true;
        nameservers.global = [ "100.64.0.3" ];
      };
      unix_socket_permission = "0770";
      disable_check_updates = true;
    };
  };

  environment.systemPackages = with pkgs; [
    headscale
  ];

  users.default.extraGroups = [
    "headscale"
  ];

  services.nginx.virtualHosts."portal.joinemm.dev" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.headscale.port}";
      proxyWebsockets = true;
    };
  };
}
