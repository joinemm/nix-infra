{ config, pkgs, ... }:
{
  sops.secrets.plausible_secret_key_base.owner = "root";

  services.plausible = {
    enable = true;
    server = {
      port = 8000;
      baseUrl = "https://traffic.joinemm.dev";
      secretKeybaseFile = config.sops.secrets.plausible_secret_key_base.path;
    };

    database = {
      clickhouse.setup = true;
    };
  };

  environment.etc."clickhouse-server/users.d/disable-logging.xml".text = ''
    <clickhouse>
      <profiles>
        <default>
          <log_queries>0</log_queries>
          <log_query_threads>0</log_query_threads>
        </default>
      </profiles>
    </clickhouse>
  '';

  systemd.services.clickhouse-cleanup = {
    path = with pkgs; [
      clickhouse
    ];
    script = ''
      clickhouse-client -q "SELECT name FROM system.tables WHERE name LIKE '%log%';" | xargs -I{} clickhouse-client -q "TRUNCATE TABLE system.{};"
    '';
    serviceConfig = {
      Type = "oneshot";
    };
  };

  systemd.timers.clickhouse-cleanup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 00:00:00";
    };
  };

  services.nginx.virtualHosts."traffic.joinemm.dev" =
    let
      plausibleAddr = "http://127.0.0.1:${toString config.services.plausible.server.port}";
      extraConfig = "proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;";
    in
    {
      enableACME = true;
      forceSSL = true;
      serverAliases = [ "plausible.joinemm.dev" ];

      locations."/" = {
        proxyPass = plausibleAddr;
        proxyWebsockets = true;
        inherit extraConfig;
      };

      locations."/visit.js" = {
        proxyPass = "${plausibleAddr}/js/script.outbound-links.js";
        inherit extraConfig;
      };
    };
}
