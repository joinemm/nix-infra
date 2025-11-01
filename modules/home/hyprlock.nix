{ lib, pkgs, ... }:
{
  programs.hyprlock = {
    enable = true;

    settings = {
      general = {
        hide_cursor = true;
      };

      auth.fingerprint = {
        enabled = true;
        ready_message = "<span>  </span>";
        present_message = ''<span foreground='##94E2D5'>  </span>'';
      };

      label = [
        {
          text = "$FPRINTPROMPT";
          font_size = 50;
          position = "-6, 0"; # the unicode symbol is slightly out of center
        }
        {
          text = "$TIME";
          valign = "top";
          halign = "left";
          position = "15, -10";
        }
        {
          text = ''cmd[update:10000] echo "$(${lib.getExe' pkgs.coreutils "cat"} /sys/class/power_supply/BAT0/capacity)%"'';
          valign = "top";
          halign = "right";
          position = "-15, -10";
        }
      ];

      input-field = {
        position = "0, -70";
        outline_thickness = 0;
        dots_size = 0.2;
        fade_on_empty = false;
        swap_font_color = true;
        placeholder_text = "";
        font_family = "monospace";
        font_color = "rgba(254, 254, 254, 1.0)";
        inner_color = "rgba(0, 0, 0, 0.0)";
        check_color = "rgba(148, 226, 213, 1.0)";
      };
    };
  };

  services.swayidle =
    let
      lockTimeout = 1 * 60; # 300 seconds
      suspendTimeout = 2 * 60; # 900 seconds

      screenLocker = lib.getExe pkgs.hyprlock;

      screenOn = "${lib.getExe pkgs.wlopm} --on '*'";
      screenOff = "${lib.getExe pkgs.wlopm} --off '*'";
    in
    {
      enable = true;
      extraArgs = [ ];
      timeouts = [
        {
          timeout = lockTimeout - 5;
          command = "${lib.getExe' pkgs.libnotify "notify-send"} 'Locking in 5 seconds' -t 5000";
        }
        {
          timeout = lockTimeout; # 300 seconds (5 minutes)
          command = "${lib.getExe' pkgs.systemd "loginctl"} lock-session";
        }
        {
          timeout = lockTimeout + 10;
          command = screenOff;
          resumeCommand = screenOn;
        }
        {
          timeout = suspendTimeout; # 900 seconds (15 minutes)
          command = "${lib.getExe' pkgs.systemd "systemctl"} suspend";
          resumeCommand = screenOn;
        }
      ];
      events = [
        {
          event = "before-sleep";
          command = "${lib.getExe' pkgs.systemd "loginctl"} lock-session";
        }
        {
          event = "lock";
          command = "${lib.getExe' pkgs.procps "pidof"} hyprlock || ${screenLocker}";
        }
        {
          event = "unlock";
          command = screenOn;
        }
        {
          event = "after-resume";
          command = screenOn;
        }
      ];
    };

  services.hypridle = {
    enable = false;
    settings =
      let
        lockTimeout = 5 * 60;
        blankTimeout = 10;
        suspendTimeout = 15 * 60;
        screenLocker = "hyprlock";
        screenOn = "wlopm --on '*'";
        screenOff = "wlopm --off '*'";
      in
      {
        general = {
          # If lockscreen is not running start it (prevents multiple lockers).
          # Hypridle does not count fingerprint activity as resuming,
          # so the screen will stay blank if no other keys are touched.
          # Hyprlock blocks until it's unlocked, so to fix this
          # we can wake the screen on unlock by chaining a wlopm call to it.
          # We can't use on_unlock_cmd without hyprland-lock-notify-v1 protocol,
          # and river does not implement it
          lock_cmd = "pidof ${screenLocker} || { ${screenLocker} && ${screenOn}; }";
          before_sleep_cmd = "loginctl lock-session";
        };
        listener = [
          {
            timeout = lockTimeout;
            on-timeout = "loginctl lock-session && ${screenOff}";
            on-resume = screenOn;
          }
          {
            # screen locked but still inactive for blankTimeout -> screen off
            timeout = lockTimeout + blankTimeout;
            on-timeout = screenOff;
            on-resume = screenOn;
          }
          {
            # screen was woken up but not unlocked, blank again after blankTimeout
            # if lockscreen is still active
            timeout = blankTimeout;
            on-timeout = "pidof ${screenLocker} && ${screenOff}";
            on-resume = screenOn;
          }
          {
            timeout = suspendTimeout;
            on-timeout = "systemctl suspend";
          }
        ];
      };
  };

}
