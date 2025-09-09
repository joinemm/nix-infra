{
  perSystem =
    { pkgs, ... }:
    {
      packages = {
        rpi-export = pkgs.callPackage ./rpi-export { };
        blocky-ui = pkgs.callPackage ./blocky-ui { };
        actual-server = pkgs.callPackage ./actual-server { };
        traggo = pkgs.callPackage ./traggo { };
      };
    };
}
