{ self, ... }:
{
  flake.githubActions.matrix = {
    host = builtins.attrNames self.nixosConfigurations;
  };

  flake.ci-targets = {
    packages = self.packages.x86_64-linux;
    hosts = builtins.mapAttrs (_name: cfg: cfg.config.system.build.toplevel) self.nixosConfigurations;
  };
}
