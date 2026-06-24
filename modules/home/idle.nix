{
  lib,
  pkgs,
  self,
  ...
}:
let
  inherit (self.packages.${pkgs.stdenv.hostPlatform.system}) idlehack;
in
{
  services.swayidle =
    let
      lockTimeout = 5 * 60;
      suspendTimeout = 15 * 60;
      blankTimeout = 10;

      screenLockerName = "hyprlock";
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
      events = {
        before-sleep = "${lib.getExe' pkgs.systemd "loginctl"} lock-session";
        lock = "${lib.getExe' pkgs.procps "pidof"} ${screenLockerName} || ${screenLocker}";
        unlock = screenOn;
        after-resume = screenOn;
      };
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
