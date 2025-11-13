{
  lib,
  pkgs,
  self,
  ...
}:
let
  idlehack = self.packages.${pkgs.system}.idlehack;
in
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
      lockTimeout = 5 * 60;
      suspendTimeout = 15 * 60;
      blankTimeout = 10;

      screenLocker = lib.getExe pkgs.hyprlock;

      screenOn = "${lib.getExe pkgs.wlopm} --on '*' && ${lib.getExe pkgs.brightnessctl} -d tpacpi::kbd_backlight s 2";
      screenOff = "${lib.getExe pkgs.wlopm} --off '*' && ${lib.getExe pkgs.brightnessctl} -d tpacpi::kbd_backlight s 0";
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
          timeout = lockTimeout;
          command = "${lib.getExe' pkgs.systemd "loginctl"} lock-session";
        }
        {
          timeout = lockTimeout + blankTimeout;
          command = screenOff;
          resumeCommand = screenOn;
        }
        {
          timeout = suspendTimeout;
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

  home.packages = [ idlehack ];

  systemd.user.services.idlehack = {
    Service = {
      Environment = "PATH=${
        lib.makeBinPath [
          pkgs.systemd
          pkgs.coreutils
          idlehack
        ]
      }";
      ExecStart = lib.getExe idlehack;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
