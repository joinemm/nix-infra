{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.gpu-screen-recorder;

  onSaveScript = pkgs.writeShellScript "sc" ''
    ${lib.getExe' pkgs.libnotify "notify-send"} "Saved replay" "$1"
  '';
in
{
  options.services.gpu-screen-recorder = {
    enable = lib.mkEnableOption "GPU Screen Recorder replay buffer";

    display = lib.mkOption {
      type = lib.types.str;
      default = "screen";
      example = "DP-1";
      description = "The display to record (monitor name, screen, focused, portal, or region)";
    };

    quality = lib.mkOption {
      type = lib.types.enum [
        "medium"
        "high"
        "very_high"
        "ultra"
      ];
      default = "ultra";
      description = "Video quality";
    };

    replayDuration = lib.mkOption {
      type = lib.types.int;
      default = 60;
      description = "Replay buffer size in seconds";
    };

    outputDirectory = lib.mkOption {
      type = lib.types.str;
      default = "${config.xdg.userDirs.videos}/replay";
      description = "Directory to save replay clips";
    };

    audioDevices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "default_output|default_input" ];
      example = [ "default_output|default_input" ];
      description = "List of audio devices to record. Use | to merge multiple sources into one track.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.gpu-screen-recorder-replay = {
      Unit = {
        Description = "GPU Screen Recorder Replay Buffer";
        After = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = ''
          ${lib.getExe pkgs.gpu-screen-recorder} \
            -w ${cfg.display} \
            -v no \
            -fm vfr \
            ${lib.concatMapStringsSep " " (device: "-a '${device}'") cfg.audioDevices} \
            -c mkv \
            -q ${cfg.quality} \
            -r ${toString cfg.replayDuration} \
            -o "${cfg.outputDirectory}" \
            -sc "${onSaveScript}"
        '';
        Restart = "on-failure";
        RestartSec = "5s";
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
