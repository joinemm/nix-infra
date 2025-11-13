{
  pkgs,
  lib,
  ...
}:
{
  services.swww.enable = true;

  # https://github.com/nix-community/home-manager/pull/8160
  systemd.user.services.swww.Service.Environment = [
    "PATH=$PATH:${lib.makeBinPath [ pkgs.swww ]}"
  ];

  home.packages = [
    (pkgs.writeShellScriptBin "setbg" ''
      set -euo pipefail
      swww img --transition-type grow --transition-duration 1 --transition-fps 60 "$1"
    '')
  ];
}
