{
  pkgs,
  ...
}:
{
  services.swww.enable = true;

  home.packages = [
    (pkgs.writeShellScriptBin "setbg" ''
      set -euo pipefail
      swww img "$1"
    '')
  ];
}
