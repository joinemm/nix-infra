{
  pkgs,
  osConfig,
  lib,
  ...
}:
{
  home.packages = [
    # fix for https://github.com/flameshot-org/flameshot/issues/3329
    (pkgs.writeShellScriptBin "flameshot-copy-fix" ''
      flameshot $@
      wl-copy < /tmp/screenshot.png
      mv /tmp/screenshot.png ~/pictures/screenshots/$(date "+%Y-%m-%d_%H-%M-%S").png
    '')
  ];

  services = {
    flameshot = {
      enable = true;
      package = pkgs.flameshot.override { enableWlrSupport = !osConfig.services.xserver.enable; };
      settings = {
        General = {
          saveAfterCopy = true;
          savePath = "/tmp";
          filenamePattern = "screenshot";

          disabledTrayIcon = true;
          showStartupLaunchMessage = false;
          disabledGrimWarning = true;

          uiColor = "#FAB387";
          contrastUiColor = "#F7768E";
        };
      };
    };
  };

  # we don't need tray
  systemd.user.services.flameshot.Unit.Requires = lib.mkForce [ ];
  systemd.user.services.flameshot.Unit.After = lib.mkForce [ "graphical-session.target" ];
}
