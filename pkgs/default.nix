{
  perSystem =
    { pkgs, ... }:
    {
      packages = {
        rpi-export = pkgs.callPackage ./rpi-export { };
        blocky-ui = pkgs.callPackage ./blocky-ui { };
        weddingshare = pkgs.callPackage ./weddingshare { };
        idlehack = pkgs.callPackage ./idlehack { };
        hypruler = pkgs.callPackage ./hypruler { };
      };
    };
}
