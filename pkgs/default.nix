{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages = {
        rpi-export = pkgs.callPackage ./rpi-export { };
        blocky-ui = pkgs.callPackage ./blocky-ui { };
        weddingshare = pkgs.callPackage ./weddingshare { };
        hypruler = pkgs.callPackage ./hypruler { };
        dev-manager-desktop = pkgs.callPackage ./dev-manager-desktop { };
        floppy = pkgs.callPackage ./floppy {
          inherit (inputs)
            floppy-src
            pyproject-build-systems
            pyproject-nix
            uv2nix
            ;
        };
      };
    };
}
