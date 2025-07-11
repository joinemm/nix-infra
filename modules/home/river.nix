{ lib, pkgs, ... }:
{
  wayland.systemd.target = "river-session.target";

  wayland.windowManager.river = {
    enable = true;
    systemd.enable = true;
    xwayland.enable = true;

    systemd.variables = [ "--all" ];
    extraSessionVariables = {
      XDG_CURRENT_DESKTOP = "river";
      XDG_SESSION_DESKTOP = "river";
      XDG_SESSION_TYPE = "wayland";
    };

    settings =
      with lib;
      let
        numTags = 9;
        listToAttrSet = list: listToAttrs (imap (i: nameValuePair (toString i)) list);
        tagMap = foldl' (x: _: x ++ [ (last x * 2) ]) [ 1 ] (genList (_: [ 1 ]) (numTags - 1));
        tagMapStrSet = listToAttrSet (map toString tagMap);
      in
      {
        extraSessionVariables = {
          MOZ_ENABLE_WAYLAND = 1;
          SDL_VIDEODRIVER = "wayland";
          QT_QPA_PLATFORM = "wayland";
          QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
          NIXOS_OZONE_WL = 1;
          GDK_BACKEND = "wayland";
        };
        default-layout = "bsp-layout";
        spawn = [
          "'${lib.getExe pkgs.river-bsp-layout} --inner-gap 10 --outer-gap 10 --split-perc 0.5'"
        ];
        focus-follows-cursor = "always";
        set-cursor-warp = "on-focus-change";

        border-width = 3;
        border-color-focused = "0xFAB387";

        keyboard-layout = "-options caps:super eu";
        set-repeat = "30 250";

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
        };

        map = {
          normal =
            (concatMapAttrs (index: tag: {
              "Super ${index}" = "set-focused-tags ${tag}";
              "Super+Shift ${index}" = "set-view-tags ${tag}";
              "Super+Control ${index}" = "toggle-focused-tags ${tag}";
            }) tagMapStrSet)
            // {
              # program hotkeys
              "Super Return" = "spawn footclient";
              "Super W" = "spawn zen";
              "Super C" = "spawn 'hyprpicker -a'";
              "Super Space" = "spawn 'tofi-drun --drun-launch=true'";
              "Super+Shift S" = "spawn 'grim -g \"$(slurp)\" -t ppm - | satty --filename -'";
              "Super Escape" = "spawn wlogout";

              # window control
              "Super Q" = "close";
              "Super F" = "toggle-fullscreen";
              "Super V" = "toggle-float";
              "Super H" = "focus-view left";
              "Super J" = "focus-view down";
              "Super K" = "focus-view up";
              "Super L" = "focus-view right";
              "Super+Shift H" = "swap left";
              "Super+Shift J" = "swap down";
              "Super+Shift K" = "swap up";
              "Super+Shift L" = "swap right";

              # media control
              "None XF86AudioMute" = "spawn 'volumectl toggle-mute'";
              "None XF86AudioMicMute" = "spawn 'volumectl -m toggle-mute'";
              "None XF86AudioPrev" = "spawn 'playerctl previous'";
              "None XF86AudioNext" = "spawn 'playerctl next'";
              "None XF86AudioPlay" = "spawn 'playerctl play-pause'";
              "None XF86AudioMedia" = "spawn 'playerctl play-pause'";
              "Super Comma" = "spawn 'playerctl previous'";
              "Super Period" = "spawn 'playerctl next'";
              "Super Slash" = "spawn 'playerctl play-pause'";

              # other F keys
              "None XF86Display" = ''spawn "wlopm --toggle '*'"'';
            };

          "-repeat normal" = {
            "Super BracketLeft" = "send-layout-cmd bsp-layout '--dec-vsplit .01'";
            "Super BracketRight" = "send-layout-cmd bsp-layout '--inc-vsplit .01'";

            "None XF86AudioRaiseVolume" = "spawn 'volumectl -u up'";
            "None XF86AudioLowerVolume" = "spawn 'volumectl -u down'";
            "None XF86MonBrightnessUp" = "spawn 'lightctl up'";
            "None XF86MonBrightnessDown" = "spawn 'lightctl down'";
          };
        };

        rule-add = {
          # server side decorations for everything
          "ssd" = "";
        };
      };
  };

}
