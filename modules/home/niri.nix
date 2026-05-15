{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    brightnessctl
    wlogout
  ];

  programs.niri.settings = {
    input = {
      keyboard = {
        xkb = {
          layout = "eu";
          options = "caps:super";
        };
        numlock = true;
        repeat-delay = 250;
        repeat-rate = 30;
      };

      touchpad = {
        tap = true;
        accel-speed = 0.0;
        accel-profile = "adaptive";
        natural-scroll = false;
        scroll-factor = 0.5;
        scroll-method = "two-finger";
      };

      mouse.accel-profile = "flat";
      trackpoint.accel-profile = "flat";

      focus-follows-mouse = {
        enable = true;
        max-scroll-amount = "0%";
      };
    };

    layout = {
      gaps = 16;
      center-focused-column = "never";
      preset-column-widths = [
        { proportion = 0.33333; }
        { proportion = 0.5; }
        { proportion = 0.66667; }
      ];
      default-column-width.proportion = 0.5;

      focus-ring = {
        width = 3;
        active.color = "#7fc8ff";
        inactive.color = "#505050";
      };

      border = {
        enable = true;
        width = 2;
        active.color = "#000000";
        inactive.color = "#000000";
        urgent.color = "#9b0000";
      };

      shadow = {
        enable = true;
        softness = 30;
        spread = 5;
        offset = {
          x = 0;
          y = 0;
        };
        color = "#0007";
      };

      struts = {
        left = 32;
        right = 32;
      };

      background-color = "transparent";
    };

    # Quickshell draws the desktop backdrop; keep that layer behind workspaces
    # and visible in the overview instead of treating it like a regular panel.
    layer-rules = [
      {
        matches = [ { namespace = "^quickshell$"; } ];
        place-within-backdrop = true;
      }
    ];

    # The shell backdrop already has depth, so the overview workspace shadow
    # just adds visual noise.
    overview.workspace-shadow.enable = false;

    # All terminal binds use footclient, which expects a long-running foot server.
    spawn-at-startup = [
      {
        argv = [
          "foot"
          "--server"
        ];
      }
    ];

    hotkey-overlay.skip-at-startup = true;
    # Prefer server-side decorations so niri can draw borders and rounded
    # corners around the actual window geometry.
    prefer-no-csd = true;
    screenshot-path = "~/pictures/screenshots/niri_%Y-%m-%d_%H-%M-%S.png";

    animations.slowdown = 1;

    window-rules = [
      {
        matches = [ { title = "^Picture-in-Picture$"; } ];
        open-floating = true;
      }
      {
        geometry-corner-radius = {
          top-left = 10.0;
          top-right = 10.0;
          bottom-right = 10.0;
          bottom-left = 10.0;
        };
        clip-to-geometry = true;
      }
      {
        # Steam notification windows have generated titles; pin them to a
        # stable corner instead of letting them float near the focused column.
        matches = [
          {
            app-id = "steam";
            title = "^notificationtoasts_\\d+_desktop$";
          }
        ];
        default-floating-position = {
          x = 10;
          y = 10;
          relative-to = "bottom-right";
        };
      }
      {
        # Make the active window cast target visibly different from a normal
        # focused window while screen sharing.
        matches = [ { is-window-cast-target = true; } ];
        focus-ring = {
          active.color = "#f38ba8";
          inactive.color = "#7d0d2d";
        };
        border.inactive.color = "#7d0d2d";
        shadow.color = "#7d0d2d70";
        tab-indicator = {
          active.color = "#f38ba8";
          inactive.color = "#7d0d2d";
        };
      }
    ];

    binds = {
      "Mod+Shift+Slash".action.show-hotkey-overlay = [ ];

      "Mod+Return" = {
        hotkey-overlay.title = "Open a Terminal: footclient";
        action.spawn = [
          "footclient"
          "--no-wait"
        ];
      };
      "Mod+Space" = {
        hotkey-overlay.title = "Run an Application: tofi-drun";
        action.spawn = [
          "tofi-drun"
          "--drun-launch=true"
        ];
      };
      "Mod+T" = {
        hotkey-overlay.title = "Open File Manager: thunar";
        action.spawn = "thunar";
      };
      "Super+Alt+L" = {
        hotkey-overlay.title = "Lock the Screen: dms";
        action.spawn = [
          "dms"
          "ipc"
          "call"
          "lock"
          "lock"
        ];
      };
      "Mod+Shift+S" = {
        hotkey-overlay.title = "Open Screenshot UI";
        action.screenshot = [ ];
      };
      "Mod+Backspace" = {
        hotkey-overlay.title = "Open Session Menu";
        action.spawn = "wlogout";
      };

      "XF86AudioRaiseVolume" = {
        allow-when-locked = true;
        action.spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+";
      };
      "XF86AudioLowerVolume" = {
        allow-when-locked = true;
        action.spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
      };
      "XF86AudioMute" = {
        allow-when-locked = true;
        action.spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
      };
      "XF86AudioMicMute" = {
        allow-when-locked = true;
        action.spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
      };
      "XF86AudioPrev".action.spawn = [
        "playerctl"
        "previous"
      ];
      "XF86AudioNext".action.spawn = [
        "playerctl"
        "next"
      ];
      "XF86AudioPlay".action.spawn = [
        "playerctl"
        "play-pause"
      ];
      "XF86AudioMedia".action.spawn = [
        "playerctl"
        "play-pause"
      ];

      "XF86MonBrightnessUp" = {
        allow-when-locked = true;
        action.spawn = [
          "brightnessctl"
          "--class=backlight"
          "set"
          "+10%"
        ];
      };
      "XF86MonBrightnessDown" = {
        allow-when-locked = true;
        action.spawn = [
          "brightnessctl"
          "--class=backlight"
          "set"
          "10%-"
        ];
      };
      "XF86Display".action.spawn = [
        "wlopm"
        "--toggle"
        "*"
      ];

      "Mod+O" = {
        repeat = false;
        action.toggle-overview = [ ];
      };
      "Mod+Q" = {
        repeat = false;
        action.close-window = [ ];
      };

      "Mod+Left".action.focus-column-left = [ ];
      "Mod+Down".action.focus-window-down = [ ];
      "Mod+Up".action.focus-window-up = [ ];
      "Mod+Right".action.focus-column-right = [ ];
      "Mod+H".action.focus-column-left = [ ];
      "Mod+J".action.focus-window-down = [ ];
      "Mod+K".action.focus-window-up = [ ];
      "Mod+L".action.focus-column-right = [ ];

      "Mod+Ctrl+Left".action.move-column-left = [ ];
      "Mod+Ctrl+Down".action.move-window-down = [ ];
      "Mod+Ctrl+Up".action.move-window-up = [ ];
      "Mod+Ctrl+Right".action.move-column-right = [ ];
      "Mod+Ctrl+H".action.move-column-left = [ ];
      "Mod+Ctrl+J".action.move-window-down = [ ];
      "Mod+Ctrl+K".action.move-window-up = [ ];
      "Mod+Ctrl+L".action.move-column-right = [ ];

      "Mod+Home".action.focus-column-first = [ ];
      "Mod+End".action.focus-column-last = [ ];
      "Mod+Ctrl+Home".action.move-column-to-first = [ ];
      "Mod+Ctrl+End".action.move-column-to-last = [ ];

      "Mod+Shift+Left".action.focus-monitor-left = [ ];
      "Mod+Shift+Down".action.focus-monitor-down = [ ];
      "Mod+Shift+Up".action.focus-monitor-up = [ ];
      "Mod+Shift+Right".action.focus-monitor-right = [ ];

      "Mod+Shift+Ctrl+Left".action.move-column-to-monitor-left = [ ];
      "Mod+Shift+Ctrl+Down".action.move-column-to-monitor-down = [ ];
      "Mod+Shift+Ctrl+Up".action.move-column-to-monitor-up = [ ];
      "Mod+Shift+Ctrl+Right".action.move-column-to-monitor-right = [ ];
      "Mod+Shift+Ctrl+H".action.move-column-to-monitor-left = [ ];
      "Mod+Shift+Ctrl+J".action.move-column-to-monitor-down = [ ];
      "Mod+Shift+Ctrl+K".action.move-column-to-monitor-up = [ ];
      "Mod+Shift+Ctrl+L".action.move-column-to-monitor-right = [ ];

      "Mod+Page_Down".action.focus-workspace-down = [ ];
      "Mod+Page_Up".action.focus-workspace-up = [ ];
      "Mod+U".action.focus-workspace-down = [ ];
      "Mod+I".action.focus-workspace-up = [ ];
      "Mod+Ctrl+Page_Down".action.move-column-to-workspace-down = [ ];
      "Mod+Ctrl+Page_Up".action.move-column-to-workspace-up = [ ];
      "Mod+Ctrl+U".action.move-column-to-workspace-down = [ ];
      "Mod+Ctrl+I".action.move-column-to-workspace-up = [ ];

      "Mod+Shift+Page_Down".action.move-workspace-down = [ ];
      "Mod+Shift+Page_Up".action.move-workspace-up = [ ];
      "Mod+Shift+U".action.move-workspace-down = [ ];
      "Mod+Shift+I".action.move-workspace-up = [ ];

      "Mod+WheelScrollDown" = {
        cooldown-ms = 150;
        action.focus-workspace-down = [ ];
      };
      "Mod+WheelScrollUp" = {
        cooldown-ms = 150;
        action.focus-workspace-up = [ ];
      };
      "Mod+Ctrl+WheelScrollDown" = {
        cooldown-ms = 150;
        action.move-column-to-workspace-down = [ ];
      };
      "Mod+Ctrl+WheelScrollUp" = {
        cooldown-ms = 150;
        action.move-column-to-workspace-up = [ ];
      };

      "Mod+WheelScrollRight".action.focus-column-right = [ ];
      "Mod+WheelScrollLeft".action.focus-column-left = [ ];
      "Mod+Ctrl+WheelScrollRight".action.move-column-right = [ ];
      "Mod+Ctrl+WheelScrollLeft".action.move-column-left = [ ];

      "Mod+Shift+WheelScrollDown".action.focus-column-right = [ ];
      "Mod+Shift+WheelScrollUp".action.focus-column-left = [ ];
      "Mod+Ctrl+Shift+WheelScrollDown".action.move-column-right = [ ];
      "Mod+Ctrl+Shift+WheelScrollUp".action.move-column-left = [ ];

      "Mod+TouchpadScrollDown" = {
        cooldown-ms = 250;
        action.focus-workspace-down = [ ];
      };
      "Mod+TouchpadScrollUp" = {
        cooldown-ms = 250;
        action.focus-workspace-up = [ ];
      };
      "Mod+TouchpadScrollRight" = {
        cooldown-ms = 250;
        action.focus-column-right = [ ];
      };
      "Mod+TouchpadScrollLeft" = {
        cooldown-ms = 250;
        action.focus-column-left = [ ];
      };

      "Mod+1".action.focus-workspace = 1;
      "Mod+2".action.focus-workspace = 2;
      "Mod+3".action.focus-workspace = 3;
      "Mod+4".action.focus-workspace = 4;
      "Mod+5".action.focus-workspace = 5;
      "Mod+6".action.focus-workspace = 6;
      "Mod+7".action.focus-workspace = 7;
      "Mod+8".action.focus-workspace = 8;
      "Mod+9".action.focus-workspace = 9;
      "Mod+Ctrl+1".action.move-column-to-workspace = 1;
      "Mod+Ctrl+2".action.move-column-to-workspace = 2;
      "Mod+Ctrl+3".action.move-column-to-workspace = 3;
      "Mod+Ctrl+4".action.move-column-to-workspace = 4;
      "Mod+Ctrl+5".action.move-column-to-workspace = 5;
      "Mod+Ctrl+6".action.move-column-to-workspace = 6;
      "Mod+Ctrl+7".action.move-column-to-workspace = 7;
      "Mod+Ctrl+8".action.move-column-to-workspace = 8;
      "Mod+Ctrl+9".action.move-column-to-workspace = 9;

      "Mod+BracketLeft".action.consume-or-expel-window-left = [ ];
      "Mod+BracketRight".action.consume-or-expel-window-right = [ ];

      "Mod+Comma".action.spawn = [
        "playerctl"
        "previous"
      ];
      "Mod+Period".action.spawn = [
        "playerctl"
        "next"
      ];

      "Mod+R".action.switch-preset-column-width = [ ];
      "Mod+Shift+R".action.switch-preset-window-height = [ ];
      "Mod+Ctrl+R".action.reset-window-height = [ ];
      "Mod+F".action.maximize-column = [ ];
      "Mod+Shift+F".action.fullscreen-window = [ ];
      "Mod+Ctrl+F".action.expand-column-to-available-width = [ ];

      "Mod+C".action.spawn = [
        "hyprpicker"
        "-a"
      ];
      "Mod+Shift+C".action.center-column = [ ];
      "Mod+Ctrl+C".action.center-visible-columns = [ ];

      "Mod+Minus".action.set-column-width = "-10%";
      "Mod+Equal".action.set-column-width = "+10%";
      "Mod+Shift+Minus".action.set-window-height = "-10%";
      "Mod+Shift+Equal".action.set-window-height = "+10%";

      "Mod+V".action.toggle-window-floating = [ ];
      "Mod+Shift+V".action.switch-focus-between-floating-and-tiling = [ ];
      "Mod+W".action.toggle-column-tabbed-display = [ ];

      "Print".action.screenshot-screen = [ ];
      "Shift+Print".action.screenshot-window = [ ];
      "F8".action.spawn = "save-replay";
      "Mod+Slash".action.spawn = [
        "playerctl"
        "play-pause"
      ];

      "Mod+Escape" = {
        allow-inhibiting = false;
        action.toggle-keyboard-shortcuts-inhibit = [ ];
      };
      "Mod+Shift+E".action.quit = [ ];
      "Ctrl+Alt+Delete".action.quit = [ ];
      "Mod+Shift+P".action.power-off-monitors = [ ];

      "Mod+E" = {
        hotkey-overlay.title = "Cast focused window";
        # The cast action needs the focused window id, so this uses niri's JSON
        # output instead of a plain action.
        action.spawn-sh = "niri msg action set-dynamic-cast-window --id $(niri msg -j focused-window | jq .id)";
      };
    };
  };
}
