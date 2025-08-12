{
  perSystem =
    { pkgs, ... }:
    {
      packages = {
        rpi-export = pkgs.callPackage ./rpi-export { };
        blocky-ui = pkgs.callPackage ./blocky-ui { };
        actual-server = pkgs.callPackage ./actual-server { };
        keymap-drawer = pkgs.python3Packages.callPackage ./keymap-drawer { };
      };
    };
}
