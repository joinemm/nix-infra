{
  config,
  lib,
  pkgs,
  ...
}:
let
  tokenFile = config.sops.secrets.webos_devmode_session_token.path;
in
{
  sops.secrets.webos_devmode_session_token.owner = "root";

  systemd.services.webos-devmode-renew = {
    description = "Renew LG webOS developer mode session";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    script = ''
      token="$(${lib.getExe' pkgs.coreutils "tr"} -d '\n' < ${tokenFile})"
      ${lib.getExe pkgs.curl} --fail --silent --show-error "https://developer.lge.com/secure/ResetDevModeSession.dev?sessionToken=$token"
    '';

    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  systemd.timers.webos-devmode-renew = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 03:00:00";
      Persistent = true;
      RandomizedDelaySec = "30m";
    };
  };
}
