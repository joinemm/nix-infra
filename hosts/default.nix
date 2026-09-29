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

  mkHost =
    modules:
    lib.nixosSystem {
      inherit specialArgs modules;
    };
in
{
  flake.nixosConfigurations = {
    carbon = mkHost [ ./carbon ];
    cobalt = mkHost [ ./cobalt ];
    oxygen = mkHost [ ./oxygen ];
    misobot = mkHost [ ./misobot ];
    zinc = mkHost [ ./zinc ];
    nickel = mkHost [ ./nickel ];
  };
}
