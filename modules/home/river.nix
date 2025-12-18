{
  lib,
  pkgs,
  user,
  ...
}:
let
  # like flameshot but faster
  screenshot = pkgs.writeShellApplication {
    name = "screenshot";
    runtimeInputs = with pkgs; [
      grim
      slurp
      swappy
      wl-clipboard
    ];
    text = ''
      if [[ $# -ge 1 ]] && [[ "$1" == "full" ]]; then
        grim - | swappy -f -
        exit 0
      fi

      # no negative numbers please
      clamp () {
        echo "$(( $1 < 0 ? 0 : $1 ))"
      }

      # remove the riverctl rule when we're done
      cleanup() {
        riverctl rule-del -app-id swappy position
      }
      trap cleanup EXIT

      # select geometry
      G="$(slurp -o)"
      IFS=' ,' read -r X Y _ <<<"$G"

      # add riverctl rule for window positioning if the position is not zero
      # (ie. slurp was used to select a region and not the whole screen)
      if [ "$X" != 0 ] || [ "$Y" != 0 ]; then
        riverctl rule-add -app-id swappy position "$(clamp $((X - 10)))" "$(clamp $((Y - 58)))"
      fi

      # take the screenshot and pass it to swappy for editing
      grim -g "$G" - | swappy -f -
    '';
  };
  screencast = pkgs.writeShellApplication {
    name = "screencast";
    runtimeInputs = with pkgs; [
      procps
      wf-recorder
      libnotify
      coreutils
      slurp
    ];
    text = ''
      if pgrep -x "wf-recorder"; then
        notify-send "Stopping recording"
        kill -2 $(pgrep wf-recorder)
      else
        G="$(slurp -o)"
        notify-send "Starting to record"
        wf-recorder -y -g "$G" -f "${user.home}/videos/screencast/$(date '+%Y-%m-%d-%H-%M-%S').mp4"
      fi
    '';
  };
in
{
  wayland.systemd.target = "river-session.target";

  xdg.configFile."swappy/config".text = ''
    [Default]
    save_dir=${user.home}/pictures/screenshots
    save_filename_format=%Y%m%d-%H%M%S.png
    line_size=3
    text_size=18
    text_font=monospace
    paint_mode=brush
    early_exit=true
  '';

  home.packages =
    (with pkgs; [
      pulseaudio
      way-displays
      wlogout
      river-bsp-layout
    ])
    ++ [
      screenshot
      screencast
    ];

  # https://codeberg.org/river/river/issues/1023#issuecomment-2272214
  xdg.portal.config.river = {
    default = [ "gtk" ];
    "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
    "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
    "org.freedesktop.impl.portal.Inhibit" = [ "none" ];
  };

  wayland.windowManager.river = {
    enable = true;
    systemd.enable = true;
    xwayland.enable = true;

    extraSessionVariables = {
      XDG_CURRENT_DESKTOP = "river";
      XDG_SESSION_DESKTOP = "river";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
    };

    settings =
      with lib;
      let
        numTags = 9;
        listToAttrSet = list: listToAttrs (imap (i: nameValuePair (toString i)) list);
        tagMap = foldl' (x: _: x ++ [ (last x * 2) ]) [ 1 ] (genList (_: [ 1 ]) (numTags - 1));
        tagMapStrSet = listToAttrSet (map toString tagMap);
        run = cmd: "spawn \"${cmd}\"";
        spawn-once = cmd: args: "'pgrep -f ${cmd} && ${cmd} ${args}'";
      in
      {
        spawn = [
          (spawn-once "river-bsp-layout" "--inner-gap 3 --outer-gap 6 --split-perc 0.5")
          (spawn-once "way-displays" "")
          (spawn-once "foot" "--server")
        ];

        default-layout = "bsp-layout";
        focus-follows-cursor = "normal";
        border-width = 3;
        border-color-focused = "0xFAB387";
        border-color-unfocused = "0x000000";
        border-color-urgent = "0xFF5555";
        keyboard-layout = "-options caps:super eu";
        set-repeat = "30 250";
        allow-tearing = "enabled";

        input = {
          "pointer-1267-12793-ELAN067C:00_04F3:31F9_Touchpad" = {
            tap = "enabled";
            scroll-factor = "0.5";
            accel-profile = "adaptive";
            pointer-accel = "-0.1";
            click-method = "clickfinger";
          };
          "pointer-2-10-TPPS/2_Elan_TrackPoint" = {
            accel-profile = "flat";
          };

          # Lamzu Thorn
          "pointer-13652-*" = {
            accel-profile = "flat";
            scroll-factor = "1.5";
          };

          # Keychron M5
          "pointer-13364-*" = {
            accel-profile = "flat";
            scroll-factor = "1";
          };
        };

        rule-add = {
          # server side decorations for everything
          "ssd" = "";
        };

        map-pointer.normal = {
          "Super BTN_LEFT" = "move-view";
          "Super BTN_RIGHT" = "resize-view";
          "Super BTN_MIDDLE" = "toggle-float";
        };

        map.normal =
          (concatMapAttrs (index: tag: {
            "Super ${index}" = "set-focused-tags ${tag}";
            "Super+Shift ${index}" = "set-view-tags ${tag}";
            "Super+Control ${index}" = "toggle-focused-tags ${tag}";
          }) tagMapStrSet)
          // {
            # program hotkeys
            "Super Return" = run "footclient --no-wait";
            "Super W" = run "glide";
            "Super R" = run "thunar";
            "Super C" = run "hyprpicker -a";
            "Super L" = run "systemctl lock-session";
            "Super Space" = run "tofi-drun --drun-launch=true";
            "Super+Shift S" = run "screenshot";
            "Super+Shift+Alt S" = run "screencast";
            "None Print" = run "screenshot full";
            "Shift Print" = run "screencast";
            "Super Escape" = run "wlogout";
            "Super Backspace" = run "wlogout";

            # window control
            "Super Q" = "close";
            "Super F" = "toggle-fullscreen";
            "Super V" = "toggle-float";
            "Super Tab" = "focus-view next";
            "Super+Shift Tab" = "focus-view previous";
            "Super+Alt Tab" = "swap next";
            "Super+Shift+Alt Tab" = "swap previous";
            "Super+Shift Page_up" = "send-to-output next";
            "Super+Shift Page_down" = "send-to-output previous";

            # media control
            "None XF86AudioMute" = run "pactl set-sink-mute @DEFAULT_SINK@ toggle";
            "None XF86AudioMicMute" = run "pactl set-source-mute @DEFAULT_SINK@ toggle";
            "None XF86AudioPrev" = run "playerctl previous";
            "None XF86AudioNext" = run "playerctl next";
            "None XF86AudioPlay" = run "playerctl play-pause";
            "None XF86AudioMedia" = run "playerctl play-pause";
            "Super Comma" = run "playerctl previous";
            "Super Period" = run "playerctl next";
            "Super Slash" = run "playerctl play-pause";

            # other F keys
            "None XF86Display" = run "wlopm --toggle '*'";

            "None F8" = run "pkill -SIGUSR1 -f gpu-screen-recorder";
          };

        map."-repeat normal" = {
          "Super BracketLeft" = "send-layout-cmd bsp-layout '--dec-vsplit .01'";
          "Super BracketRight" = "send-layout-cmd bsp-layout '--inc-vsplit .01'";
          "Super+Shift BracketLeft" = "send-layout-cmd bsp-layout '--dec-hsplit .01'";
          "Super+Shift BracketRight" = "send-layout-cmd bsp-layout '--inc-hsplit .01'";

          "None XF86AudioRaiseVolume" = run "pactl set-sink-volume @DEFAULT_SINK@ +5%";
          "None XF86AudioLowerVolume" = run "pactl set-sink-volume @DEFAULT_SINK@ -5%";
          "None XF86MonBrightnessUp" = run "brightnessctl s +5%";
          "None XF86MonBrightnessDown" = run "brightnessctl s 5%-";
        };
      };
  };

}
