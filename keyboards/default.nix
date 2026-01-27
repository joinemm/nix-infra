{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    {
      packages = rec {
        firmware = inputs.zmk-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system}.buildSplitKeyboard {
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
        flash = inputs.zmk-nix.packages.${pkgs.stdenv.hostPlatform.system}.flash.override {
          inherit firmware;
        };
        zmk-update = inputs.zmk-nix.packages.${pkgs.stdenv.hostPlatform.system}.update;

        draw-keymap = pkgs.callPackage ./draw-keymap.nix {
          src = ./kyria;
          keymap = "kyria_rev3.keymap";
        };

        qmk-flash = pkgs.writeShellApplication {
          name = "qmk-flash";
          text = builtins.readFile ./qmk-flash.sh;
          runtimeInputs = with pkgs; [ dfu-programmer ];
        };
      };
    };
}
