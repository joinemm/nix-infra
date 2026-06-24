{
  pkgs,
  ...
}:
{
  services.awww.enable = true;

  home.packages = [
    (pkgs.writeShellScriptBin "setbg" ''
      set -euo pipefail
      awww img --transition-type grow --transition-duration 1 --transition-fps 60 "$1"
    '')
  ];
}
