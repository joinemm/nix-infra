{ self, lib, ... }:
let
  inherit (self.inputs) deploy-rs;

  x86 = {
    oxygen = {
      hostname = "65.21.249.145";
      profiles.system = {
        user = "root";
        path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.oxygen;
      };
    };
    misobot = {
      hostname = "5.161.235.21";
      profiles.system = {
        user = "root";
        path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.misobot;
      };
    };
    nickel = {
      hostname = "100.64.0.7";
      profiles.system = {
        user = "root";
        path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.nickel;
      };
    };
  };

  aarch64 = {
    zinc = {
      hostname = "100.64.0.3";
      profiles.system = {
        user = "root";
        path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.zinc;
      };
    };
  };
in
{
  flake = {
    deploy.nodes = x86 // aarch64;

    # This is used in a script to list all nodes
    deploy.list = lib.attrsets.mapAttrs (_: value: value.hostname) (x86 // aarch64);

    checks = {
      x86_64-linux = deploy-rs.lib.x86_64-linux.deployChecks { nodes = x86; };
      aarch64-linux = deploy-rs.lib.aarch64-linux.deployChecks { nodes = aarch64; };
    };
  };
}
