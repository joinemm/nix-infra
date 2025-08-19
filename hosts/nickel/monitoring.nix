{
  config,
  ...
}:
{
  services.prometheus.exporters.node.enable = true;

  services.prometheus = {
    enable = true;
    port = 9090;
    listenAddress = "0.0.0.0";
    checkConfig = true;
    globalConfig.scrape_interval = "15s";

    scrapeConfigs = [
      {
        job_name = "local";
        static_configs = [
          {
            targets = [
              "127.0.0.1:${toString config.services.prometheus.exporters.node.port}"
              "192.0.1.3:9110"
              "192.0.1.3:9100"
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
        http_port = 3000;
        http_addr = "0.0.0.0";
      };

      # allow html for blocky panel with buttons
      panels.disable_sanitize_html = true;

      # disable telemetry
      analytics = {
        reporting_enabled = false;
        feedback_links_enabled = false;
      };
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
}
