{ lib, pkgs, ... }:
let
  mirrorIntegratedDisplay = pkgs.writeShellApplication {
    name = "mirror-integrated-display";
    runtimeInputs = with pkgs; [
      coreutils
      jq
      libnotify
      niri
      tofi
      wl-mirror
    ];
    text = ''
      pid_file="''${XDG_RUNTIME_DIR:?}/mirror-integrated-display.pid"
      mirror_title="nix-infra-integrated-display-mirror"

      if [[ -r "$pid_file" ]]; then
        read -r mirror_pid < "$pid_file" || true
        managed_instance=false

        if [[ "$mirror_pid" =~ ^[0-9]+$ ]] \
          && kill -0 "$mirror_pid" 2>/dev/null \
          && [[ -r "/proc/$mirror_pid/cmdline" ]]; then
          while IFS= read -r -d "" argument; do
            if [[ "$argument" == "$mirror_title" ]]; then
              managed_instance=true
              break
            fi
          done < "/proc/$mirror_pid/cmdline"
        fi

        if [[ "$managed_instance" == true ]]; then
          kill "$mirror_pid"
          rm -f -- "$pid_file"
          notify-send "Screen mirroring" "Mirror stopped"
          exit 0
        fi

        rm -f -- "$pid_file"
      fi

      outputs="$(niri msg --json outputs)"

      source_output="$(
        jq -r '
          to_entries[]
          | select((.key | startswith("eDP-")) and .value.logical != null)
          | .key
        ' <<< "$outputs" | head -n1
      )"

      if [[ -z "$source_output" ]]; then
        notify-send "Screen mirroring" "No active integrated display found"
        exit 1
      fi

      mapfile -t target_outputs < <(
        jq -r '
          to_entries[]
          | select((.key | startswith("eDP-") | not) and .value.logical != null)
          | .key
        ' <<< "$outputs"
      )

      case "''${#target_outputs[@]}" in
        0)
          notify-send "Screen mirroring" "No active external display found"
          exit 1
          ;;
        1)
          target_output="''${target_outputs[0]}"
          ;;
        *)
          target_output="$(
            printf '%s\n' "''${target_outputs[@]}" \
              | tofi --prompt-text="Mirror to: "
          )" || exit 0
          [[ -n "$target_output" ]] || exit 0
          ;;
      esac

      wl-mirror \
        --title "$mirror_title" \
        --fullscreen-output "$target_output" \
        "$source_output" &
      mirror_pid=$!
      printf '%s\n' "$mirror_pid" > "$pid_file"

      cleanup() {
        if [[ -r "$pid_file" ]]; then
          read -r recorded_pid < "$pid_file" || true
          if [[ "$recorded_pid" == "$mirror_pid" ]]; then
            rm -f -- "$pid_file"
          fi
        fi
      }
      trap cleanup EXIT

      wait "$mirror_pid"
    '';
  };
in
{
  home.packages = with pkgs; [
    brightnessctl
    wlogout
  ];

  xdg.desktopEntries.mirror-integrated-display = {
    name = "Toggle Integrated Display Mirror";
    genericName = "Screen Mirror";
    comment = "Start or stop mirroring the integrated display to an external monitor";
    icon = "video-display";
    exec = lib.getExe mirrorIntegratedDisplay;
    terminal = false;
    categories = [ "Utility" ];
  };

  programs.niri.extraConfig = ''
    include optional=true "noctalia.kdl"
  '';

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
        matches = [ { namespace = "^noctalia-wallpaper"; } ];
        place-within-backdrop = true;
      }
    ];

    # The shell backdrop already has depth, so the overview workspace shadow
    # just adds visual noise.
    overview.workspace-shadow.enable = false;

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
        geometry-corner-radius =
          let
            radius = 20.0;
          in
          {
            top-left = radius;
            top-right = radius;
            bottom-right = radius;
            bottom-left = radius;
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
        hotkey-overlay.title = "Open File Manager: nautilus";
        action.spawn = "nautilus";
      };
      "Super+Shift+L" = {
        hotkey-overlay.title = "Lock the Screen";
        action.spawn-sh = "loginctl lock-session";
      };
      "Mod+Shift+S" = {
        hotkey-overlay.title = "Open Screenshot UI";
        action.spawn = [
          "noctalia"
          "msg"
          "screenshot-region"
        ];
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
        "--player=spotify,%any"
        "previous"
      ];
      "XF86AudioNext".action.spawn = [
        "playerctl"
        "--player=spotify,%any"
        "next"
      ];
      "XF86AudioPlay".action.spawn = [
        "playerctl"
        "--player=spotify,%any"
        "play-pause"
      ];
      "XF86AudioMedia".action.spawn = [
        "playerctl"
        "--player=spotify,%any"
        "play-pause"
      ];

      "XF86MonBrightnessUp" = {
        allow-when-locked = true;
        action.spawn = [
          "brightnessctl"
          "--class=backlight"
          "set"
          "10%+"
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
      "Shift+XF86MonBrightnessUp".action.spawn = [
        "sunsetr"
        "set"
        "current_temp+=500"
      ];
      "Shift+XF86MonBrightnessDown".action.spawn = [
        "sunsetr"
        "set"
        "current_temp-=500"
      ];
      "XF86Display".action.spawn = [
        "niri"
        "msg"
        "action"
        "power-off-monitors"
      ];

      "Mod+O" = {
        repeat = false;
        action.toggle-overview = [ ];
      };
      "Mod+Q" = {
        repeat = false;
        action.close-window = [ ];
      };

      "Mod+Left".action.focus-column-or-monitor-left = [ ];
      "Mod+Down".action.focus-window-or-monitor-down = [ ];
      "Mod+Up".action.focus-window-or-monitor-up = [ ];
      "Mod+Right".action.focus-column-or-monitor-right = [ ];
      "Mod+H".action.focus-column-or-monitor-left = [ ];
      "Mod+J".action.focus-window-or-monitor-down = [ ];
      "Mod+K".action.focus-window-or-monitor-up = [ ];
      "Mod+L".action.focus-column-or-monitor-right = [ ];

      "Mod+Alt+Left".action.move-column-left-or-to-monitor-left = [ ];
      "Mod+Alt+Down".action.move-column-to-monitor-down = [ ];
      "Mod+Alt+Up".action.move-column-to-monitor-up = [ ];
      "Mod+Alt+Right".action.move-column-right-or-to-monitor-right = [ ];
      "Mod+Alt+H".action.move-column-left-or-to-monitor-left = [ ];
      "Mod+Alt+J".action.move-column-to-monitor-down = [ ];
      "Mod+Alt+K".action.move-column-to-monitor-up = [ ];
      "Mod+Alt+L".action.move-column-right-or-to-monitor-right = [ ];

      "Mod+Home".action.focus-column-first = [ ];
      "Mod+End".action.focus-column-last = [ ];
      "Mod+Alt+Home".action.move-column-to-first = [ ];
      "Mod+Alt+End".action.move-column-to-last = [ ];

      "Mod+Shift+Left".action.focus-monitor-left = [ ];
      "Mod+Shift+Down".action.focus-monitor-down = [ ];
      "Mod+Shift+Up".action.focus-monitor-up = [ ];
      "Mod+Shift+Right".action.focus-monitor-right = [ ];
      "Mod+Shift+H".action.focus-monitor-left = [ ];
      "Mod+Shift+J".action.focus-monitor-down = [ ];
      "Mod+Shift+K".action.focus-monitor-up = [ ];
      "Mod+Shift+L".action.focus-monitor-right = [ ];

      "Mod+Page_Down".action.focus-workspace-down = [ ];
      "Mod+Page_Up".action.focus-workspace-up = [ ];
      "Mod+U".action.focus-workspace-down = [ ];
      "Mod+I".action.focus-workspace-up = [ ];
      "Mod+Alt+Page_Down".action.move-column-to-workspace-down = [ ];
      "Mod+Alt+Page_Up".action.move-column-to-workspace-up = [ ];
      "Mod+Alt+U".action.move-column-to-workspace-down = [ ];
      "Mod+Alt+I".action.move-column-to-workspace-up = [ ];

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
      "Mod+Alt+WheelScrollDown" = {
        cooldown-ms = 150;
        action.move-column-to-workspace-down = [ ];
      };
      "Mod+Alt+WheelScrollUp" = {
        cooldown-ms = 150;
        action.move-column-to-workspace-up = [ ];
      };

      "Mod+WheelScrollRight".action.focus-column-right = [ ];
      "Mod+WheelScrollLeft".action.focus-column-left = [ ];
      "Mod+Alt+WheelScrollRight".action.move-column-right = [ ];
      "Mod+Alt+WheelScrollLeft".action.move-column-left = [ ];

      "Mod+Shift+WheelScrollDown".action.focus-column-right = [ ];
      "Mod+Shift+WheelScrollUp".action.focus-column-left = [ ];

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
      "Mod+Alt+1".action.move-column-to-workspace = 1;
      "Mod+Alt+2".action.move-column-to-workspace = 2;
      "Mod+Alt+3".action.move-column-to-workspace = 3;
      "Mod+Alt+4".action.move-column-to-workspace = 4;
      "Mod+Alt+5".action.move-column-to-workspace = 5;
      "Mod+Alt+6".action.move-column-to-workspace = 6;
      "Mod+Alt+7".action.move-column-to-workspace = 7;
      "Mod+Alt+8".action.move-column-to-workspace = 8;
      "Mod+Alt+9".action.move-column-to-workspace = 9;

      "Mod+BracketLeft".action.consume-or-expel-window-left = [ ];
      "Mod+BracketRight".action.consume-or-expel-window-right = [ ];

      "Mod+Comma".action.spawn = [
        "playerctl"
        "--player=spotify,%any"
        "previous"
      ];
      "Mod+Period".action.spawn = [
        "playerctl"
        "--player=spotify,%any"
        "next"
      ];
      "Mod+Slash".action.spawn = [
        "playerctl"
        "--player=spotify,%any"
        "play-pause"
      ];

      "Mod+R".action.switch-preset-column-width = [ ];
      "Mod+Shift+R".action.switch-preset-window-height = [ ];
      "Mod+Alt+R".action.reset-window-height = [ ];
      "Mod+F".action.maximize-column = [ ];
      "Mod+Shift+F".action.fullscreen-window = [ ];
      "Mod+Alt+F".action.expand-column-to-available-width = [ ];

      "Mod+C".action.spawn = [
        "hyprpicker"
        "-a"
      ];
      "Mod+Shift+C".action.center-column = [ ];
      "Mod+Alt+C".action.center-visible-columns = [ ];

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
