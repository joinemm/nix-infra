{ inputs, ... }:

{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  programs.noctalia = {
    enable = true;

    systemd.enable = true;

    settings = {
      audio = {
        enable_sounds = true;
      };

      bar.default = {
        end = [
          "media"
          "wallpaper"
          "notifications"
          "clipboard"
          "network"
          "bluetooth"
          "volume"
          "brightness"
          "battery"
          "session"
        ];
        font_family = "monospace";
        margin_ends = 10;
        scale = 1.1;
        start = [
          "control-center"
          "tray"
          "workspaces"
          "date"
        ];
        widget_spacing = 10;
      };

      calendar = {
        enabled = true;
        account.primary = {
          name = "Personal";
          provider = "custom";
          type = "caldav";
          server_url = "https://dav.joinemm.dev/joonas/2a465ca7-ebea-45ff-db4d-61eb39cf6631";
          username = "joonas";
        };
      };

      control_center.sidebar = "full";

      desktop_widgets.enabled = false;

      idle = {
        behavior_order = [
          "screen-off"
          "lock"
          "lock-and-suspend"
        ];
        pre_action_fade_seconds = 3;

        behavior = {
          screen-off = {
            action = "screen_off";
            enabled = true;
            timeout = 540;
          };
          lock = {
            action = "lock";
            enabled = true;
            timeout = 600;
          };
          lock-and-suspend = {
            action = "lock_and_suspend";
            enabled = true;
            timeout = 1200;
          };
        };
      };

      location.auto_locate = true;
      lockscreen.fingerprint = false;

      shell = {
        clipboard_confirm_clear_history = false;
        screen_time_enabled = true;
        settings_show_advanced = true;
        screen_corners.enabled = true;

        panel = {
          clipboard_placement = "attached";
          open_near_click_clipboard = true;
          open_near_click_control_center = true;
          open_near_click_session = true;
          open_near_click_wallpaper = true;
        };
      };

      theme = {
        source = "wallpaper";
        templates.builtin_ids = [
          "foot"
          "niri"
        ];
        templates.community_ids = [ "zen-browser" ];
      };

      wallpaper.directory = "/home/joonas/pictures/wallpapers";

      widget = {
        date.format = "{:%A %d.%m.}";
        control-center.glyph = "layout-filled";
        media = {
          art_size = 20;
          hide_when_no_media = true;
          max_length = 350;
          title_scroll = "on_hover";
        };
        tray.capsule = true;
      };
    };
  };
}
