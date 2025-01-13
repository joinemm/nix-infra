{ pkgs, config, ... }:
{
  systemd.tmpfiles.rules = [
    "f '${config.services.home-assistant.configDir}/automations.yaml' 0755 hass hass - -"
    "f '${config.services.home-assistant.configDir}/scenes.yaml' 0755 hass hass - -"
    "f '${config.services.home-assistant.configDir}/scripts.yaml' 0755 hass hass - -"
  ];

  services.home-assistant = {
    enable = true;

    extraComponents = [
      # Components required to complete the onboarding
      "analytics"
      "google_translate"
      "met"
      "radio_browser"
      "shopping_list"
      # Recommended for fast zlib compression
      # https://www.home-assistant.io/integrations/isal
      "isal"
      "unifiprotect"
      "mqtt"
      "zha"
      "mobile_app"
      "tuya"
    ];

    customComponents = with pkgs.home-assistant-custom-components; [
      adaptive_lighting
    ];

    extraPackages = ps: with ps; [ psycopg2 ];

    config = {
      # Includes dependencies for a basic setup
      # https://www.home-assistant.io/integrations/default_config/
      default_config = { };
      recorder.db_url = "postgresql://@/hass";
      http = {
        use_x_forwarded_for = true;
        trusted_proxies = [
          "127.0.0.1"
          "::1"
        ];
      };
      "automation ui" = "!include automations.yaml";
      "scene ui" = "!include scenes.yaml";
      "script ui" = "!include scripts.yaml";
    };
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "hass" ];
    ensureUsers = [
      {
        name = "hass";
        ensureDBOwnership = true;
      }
    ];
  };
}
