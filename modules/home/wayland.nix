{
  pkgs,
  ...
}:
{
  home.sessionVariables = {
    XDG_SESSION_TYPE = "wayland";
    # running steam with this breaks steam overlay
    # SDL_VIDEO_DRIVER = "wayland";
    QT_QPA_PLATFORM = "wayland";
    MOZ_ENABLE_WAYLAND = 1;
    NIXOS_OZONE_WL = 1;
    GDK_BACKEND = "wayland";

    LS_COLORS = "$(${pkgs.vivid}/bin/vivid generate dracula)";
  };

  home.packages = with pkgs; [
    wl-clipboard
    hyprpicker
    wlopm
    wf-recorder
    slurp
  ];

  programs.swayimg = {
    enable = true;
    settings = {
      general = {
        overlay = "no";
      };
      viewer = {
        window = "#000000";
      };
      list = {
        order = "mtime";
        reverse = "yes";
        all = "yes";
      };
      info = {
        info_timeout = 1;
      };
      "keys.viewer" = {
        ScrollUp = "zoom +5";
        ScrollDown = "zoom -5";
        j = "prev_file";
        k = "next_file";
        Left = "prev_file";
        Right = "next_file";
        b = "exec setbg \"%\"";
      };
      "keys.gallery" = {
        ScrollUp = "thumb +20";
        ScrollDown = "thumb -20";
        j = "page_down";
        k = "page_up";
      };
    };
  };

  programs.tofi = {
    enable = true;
    settings = {
      width = "100%";
      height = "100%";
      border-width = 0;

      outline-width = 0;
      padding-left = "35%";
      padding-top = "35%";

      result-spacing = 20;
      num-results = 5;
      font = "monospace";
      background-color = "#000A";
    };
  };

  services.mako = {
    enable = true;
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

  services.gammastep = {
    enable = true;
    tray = true;
    temperature = {
      day = 6500;
      night = 3000;
    };
    duskTime = "20:30-21:00";
    dawnTime = "7:30-8:00";
  };
}
