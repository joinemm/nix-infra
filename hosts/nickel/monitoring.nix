{
  config,
  ...
}:
{
  services.prometheus = {
    enable = true;
    port = 9090;
    listenAddress = "0.0.0.0";
    checkConfig = true;
    globalConfig.scrape_interval = "15s";

    scrapeConfigs = [
      {
        job_name = "node_exporter";
        static_configs = [
          {
            targets = [
              "127.0.0.1:${toString config.services.prometheus.exporters.node.port}"
            ];
          }
        ];
      }
      {
        job_name = "immich";
        static_configs = [
          {
            targets = [
              "127.0.0.1:8081"
            ];
          }
        ];
      }
      {
        job_name = "nixarr";
        static_configs = [
          {
            targets = [
              "127.0.0.1:${toString config.nixarr.radarr.exporter.port}"
              "127.0.0.1:${toString config.nixarr.sonarr.exporter.port}"
              "127.0.0.1:${toString config.nixarr.prowlarr.exporter.port}"
              "127.0.0.1:${toString config.nixarr.wireguard.exporter.port}"
            ];
          }
        ];
      }
    ];
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        domain = "grafana.lab.joinemm.dev";
        http_port = 3000;
        http_addr = "0.0.0.0";
        root_url = "https://grafana.lab.joinemm.dev/";
      };

      # allow html for blocky panel with buttons
      panels.disable_sanitize_html = true;

      # disable telemetry
      analytics = {
        reporting_enabled = false;
        feedback_links_enabled = false;
      };

      security.secret_key = "6e181acc464d46c15a3e4f905fd566c876bb9d32d7e6055289251b184c356bf5";
    };

    provision.datasources.settings.datasources = [
      {
        isDefault = true;
        name = "prometheus";
        type = "prometheus";
        url = "http://${config.services.prometheus.listenAddress}:${toString config.services.prometheus.port}";
      }
    ];
  };

  services.nginx.virtualHosts."grafana.lab.joinemm.dev" = {
    useACMEHost = "lab.joinemm.dev";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}";
    };
    locations."/api/live/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}";
      proxyWebsockets = true;
    };
  };

  services.nginx.virtualHosts."prometheus.lab.joinemm.dev" = {
    useACMEHost = "lab.joinemm.dev";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.prometheus.port}";
    };
  };
}
