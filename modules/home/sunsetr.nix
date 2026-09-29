{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:
let
  sunsetr = inputs.sunsetr.packages.${pkgs.stdenv.hostPlatform.system}.sunsetr;
in
lib.mkMerge [
  {
    home.packages = [
      sunsetr # cli
    ];

    # `sunsetr set` atomically replaces this file for manual adjustments. Force
    # recreation on activation so Home Manager can restore the declared baseline.
    xdg.configFile."sunsetr/sunsetr.toml" = {
      force = true;
      text = ''
        backend = "wayland"
        transition_mode = "finish_by"
        smoothing = true
        startup_duration = 0.5
        shutdown_duration = 0.5

        day_temp = 6500
        night_temp = 2000
        day_gamma = 100
        night_gamma = 100

        sunset = "22:00:00"
        sunrise = "07:00:00"
        transition_duration = 30
      '';
    };

    # The same preset command toggles this neutral profile back to the default schedule
    xdg.configFile."sunsetr/presets/disabled/sunsetr.toml" = {
      force = true;
      text = ''
        transition_mode = "static"
        static_temp = 6500
        static_gamma = 100
      '';
    };

    systemd.user.services.sunsetr = {
      Unit.After = [ "graphical-session.target" ];
      Install.WantedBy = [ "graphical-session.target" ];
      Service = {
        ExecStart = "${sunsetr}/bin/sunsetr";
        Restart = "on-failure";
        RestartSec = 2;
      };
    };
  }
  (lib.mkIf config.programs.noctalia.enable {
    programs.noctalia.settings = {
      widget.nightlight-toggle = {
        type = "custom_button";
        glyph = "moon";
        tooltip = "Toggle night light schedule";
        actions.left = ''
          sunsetr preset "$(sunsetr preset list | head -2 | grep -v "$(sunsetr preset active)")"
        '';
      };
      bar.default.end = [
        "nightlight-toggle"
      ];
    };
  })
]
