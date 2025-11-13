{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      oldPkgs = import inputs.nixpkgs-stable { inherit (pkgs) system; };
    in
    {
      packages = {
        rpi-export = pkgs.callPackage ./rpi-export { };
        blocky-ui = pkgs.callPackage ./blocky-ui { };
        actual-server = pkgs.callPackage ./actual-server { };
        weddingshare = pkgs.callPackage ./weddingshare { };
        idlehack = pkgs.callPackage ./idlehack { };
        glide-browser = pkgs.callPackage ./glide-browser { };
        traggo = oldPkgs.callPackage ./traggo { }; # needs go 1.23 which is end-of-life
      };
    };
}
