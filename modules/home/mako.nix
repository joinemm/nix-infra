{
  services.mako = {
    enable = false;
    settings = {
      sort = "-time";
      layer = "overlay";
      background-color = "#1e1e2e";
      width = 400;
      height = 200;
      border-size = 0;
      border-color = "#6C3483";
      border-radius = 0;
      icons = true;
      max-icon-size = 64;
      default-timeout = 5000;
      ignore-timeout = 0;
      font = "monospace 12";
      margin = 16;
      padding = "12,20";

      "urgency=low" = {
        border-color = "#444444";
      };

      "urgency=normal" = {
        border-color = "#6F8FDB";
      };

      "urgency=critical" = {
        border-color = "#ff5555";
        default-timeout = 0;
      };
    };
  };
}
