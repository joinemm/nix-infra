{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      self',
      ...
    }:
    {
      packages = rec {
        firmware = inputs.zmk-nix.legacyPackages.${pkgs.system}.buildSplitKeyboard {
          name = "kyria-firmware";
          board = "nice_nano_v2";
          shield = "kyria_rev3_%PART%";
          zephyrDepsHash = "sha256-3fuPyz2aRKxpAOYndy9MkCgH0sixj4YKX8m+pPXn/K8=";

          src = lib.sourceFilesBySuffices ./kyria [
            ".conf"
            ".keymap"
            ".yml"
          ];
        };
        flash = inputs.zmk-nix.packages.${pkgs.system}.flash.override { inherit firmware; };
        zmk-update = inputs.zmk-nix.packages.${pkgs.system}.update;

        draw-keymap = pkgs.callPackage ./draw-keymap.nix {
          inherit (self'.packages) keymap-drawer;
          src = ./kyria;
          keymap = "kyria_rev3.keymap";
        };
      };
    };
}
