{ inputs, ... }:
{
  imports = [
    inputs.flake-root.flakeModule
    inputs.treefmt-nix.flakeModule
  ];

  perSystem =
    { config, ... }:
    {
      treefmt.config = {
        inherit (config.flake-root) projectRootFile;

        programs = {
          nixfmt.enable = true;
          deadnix.enable = true;
          statix.enable = true;
          shellcheck.enable = true;
          shellcheck.excludes = [ ".envrc" ];
          jsonfmt.enable = true;
        };
      };

      formatter = config.treefmt.build.wrapper;
    };
}
