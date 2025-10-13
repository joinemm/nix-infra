{
  inputs,
  lib,
  self,
  ...
}:
let
  user = {
    name = "joonas";
    fullName = "Joonas Rautiola";
    email = "joonas@rautiola.co";
    gpgKey = "0x090EB48A4669AA54";
    sshKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGlFqSQFoSSuAS1IjmWBFXie329I5Aqf71QhVOnLTBG+ joonas@athens" # Laptop
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3h/Aj66ndKFtqpQ8H53tE9KbbO0obThC0qbQQKFQRr joonas@rome" # Desktop
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC0ONtbWZD6fMDQNWSiKLBUlkxJAVQ36jf3LbVEbba4M u0_a224@localhost" # Pixel 8
    ];
    home = "/home/${user.name}";
  };
  specialArgs = {
    inherit inputs user self;
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
