{
  inputs,
  lib,
  config,
  ...
}:
let
  idleFadeSeconds = 5;
  screenOffTimeout = 10 * 60;
  lockTimeout = 10 * 60 + 10;
  suspendTimeout = 20 * 60;
in
{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  programs.noctalia = {
    enable = true;
    systemd.enable = true;

    settings = {
      audio = {
        # Avoid keeping the audio stream awake to save battery when no audio is needed
        enable_sounds = false;
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
        margin_edge = 10;
        concave_edge_corners = false;
        scale = 1.1;
        start = [
          "control-center"
          "tray"
          "workspaces"
          "date"
          "privacy"
        ];
        widget_spacing = 10;
      };

      brightness = {
        minimum_brightness = 0.10;
      };

      calendar = {
        enabled = true;
        # Noctalia currently cannot use webcal accounts: https://github.com/noctalia-dev/noctalia/issues/3294
        account = lib.mapAttrs (
          name: acc:
          {
            inherit name;
            provider = "custom";
            type = "caldav";
            color = if acc.primary or false then "primary" else "tertiary";
            server_url = acc.remote.url;
          }
          // lib.optionalAttrs (acc.remote.userName != null) {
            username = acc.remote.userName;
          }
        ) (lib.filterAttrs (_: acc: acc.remote.type == "caldav") config.accounts.calendar.accounts);
      };

      control_center = {
        sidebar = "full";
        shortcuts = [
          { type = "caffeine"; }
          { type = "wifi"; }
          { type = "notification"; }
          { type = "power_profile"; }
          { type = "bluetooth"; }
          { type = "wallpaper"; }
        ];
      };

      desktop_widgets.enabled = false;

      idle = {
        behavior_order = [
          "screen-off"
          "lock"
          "suspend"
        ];
        pre_action_fade_seconds = idleFadeSeconds;

        behavior = {
          screen-off = {
            action = "screen_off";
            enabled = true;
            timeout = screenOffTimeout - idleFadeSeconds;
          };
          lock = {
            # Noctalia's own lockscreen is disabled; start the external locker directly.
            action = "command";
            command = "loginctl lock-session";
            enabled = true;
            timeout = lockTimeout - idleFadeSeconds;
          };
          suspend = {
            # The Swayidle before-sleep hook locks before every suspend route.
            action = "suspend";
            enabled = true;
            timeout = suspendTimeout - idleFadeSeconds;
          };
        };
      };

      location.auto_locate = true;

      lockscreen = {
        enabled = false;
        fingerprint = false;
      };

      shell = {
        clipboard_confirm_clear_history = false;
        screen_time_enabled = true;
        settings_show_advanced = true;
        screen_corners.enabled = true;
        polkit_agent = true;

        screenshot = {
          annotate = true;
          confirm_region = true;
          directory = "/home/joonas/pictures/screenshots";
          skip_annotate_on_copy_save = true;
        };

        panel = {
          clipboard_placement = "attached";
          open_near_click_clipboard = true;
          open_near_click_control_center = true;
          open_near_click_session = true;
          open_near_click_wallpaper = true;
        };

        session.actions = [
          {
            enabled = true;
            action = "logout";
            variant = "default";
            shortcut = "l";
          }
          {
            enabled = true;
            action = "suspend";
            variant = "default";
            shortcut = "s";
          }
          {
            enabled = true;
            action = "command";
            command = "systemctl reboot --firmware-setup";
            glyph = "settings-filled";
            label = "BIOS";
            variant = "secondary";
            shortcut = "b";
          }
          {
            enabled = true;
            action = "reboot";
            variant = "destructive";
            shortcut = "r";
          }
          {
            enabled = true;
            action = "shutdown";
            variant = "destructive";
            label = "Power off";
            shortcut = "p";
          }
        ];
      };

      theme = {
        source = "wallpaper";
        templates = {
          builtin_ids = [
            "foot"
            "niri"
          ];
          community_ids = [ "zen-browser" ];
        };
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
        tray = {
          capsule = true;
          hidden = [ "nm-applet" ];
        };
      };

      osd.kinds.lock_keys = false;

      # disable notification sound on apps that already have sounds built in
      notification.filter = {
        slack = {
          enabled = true;
          match = "slack";
          play_sound = false;
        };
        discord = {
          enabled = true;
          match = "vesktop";
          play_sound = false;
        };
      };
    };
  };
}
