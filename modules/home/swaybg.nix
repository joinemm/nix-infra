{
  user,
  pkgs,
  config,
  lib,
  ...
}:
let
  wallpaperPath = "${user.home}/.wallpaper";
in
{
  systemd.user.services.swaybg = {
    Install.WantedBy = [ config.wayland.systemd.target ];
    Service.ExecStart = "${lib.getExe pkgs.swaybg} -m fill -i ${wallpaperPath}";
  };

  systemd.user.services.swaybg-watcher = {
    Install.WantedBy = [ config.wayland.systemd.target ];
    Service = {
      Type = "oneshot";
      ExecStart = "systemctl --user restart swaybg.service";
    };
  };

  systemd.user.paths.swaybg-watcher = {
    Install.WantedBy = [ config.wayland.systemd.target ];
    Path.PathModified = "${wallpaperPath}";
  };

  home.packages = [
    (pkgs.writeShellScriptBin "setbg" ''
      set -eu
      cp -f "$1" ${wallpaperPath}
    '')
  ];
}
