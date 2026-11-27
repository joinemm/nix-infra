{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages = {
        installer-iso =
          (inputs.nixpkgs.lib.nixosSystem {
            specialArgs = { inherit inputs; };
            modules = [
              ../modules/installer.nix
              { nixpkgs.hostPlatform = pkgs.stdenv.hostPlatform.system; }
            ];
          }).config.system.build.isoImage;

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
