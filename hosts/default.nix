{
  inputs,
  lib,
  self,
  ...
}:
let
  specialArgs = {
    inherit inputs self;
  };
in
{
  flake.nixosConfigurations = {
    carbon = lib.nixosSystem {
      inherit specialArgs;
      modules = [ ./carbon ];
    };
    cobalt = lib.nixosSystem {
      inherit specialArgs;
      modules = [ ./cobalt ];
    };
    oxygen = lib.nixosSystem {
      inherit specialArgs;
      modules = [ ./oxygen ];
    };
    misobot = lib.nixosSystem {
      inherit specialArgs;
      modules = [ ./misobot ];
    };
    zinc = lib.nixosSystem {
      inherit specialArgs;
      modules = [ ./zinc ];
    };
    nickel = lib.nixosSystem {
      inherit specialArgs;
      modules = [ ./nickel ];
    };
  };
}
