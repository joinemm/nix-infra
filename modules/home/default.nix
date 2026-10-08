{ lib, ... }:
let
  homeModules = lib.listToAttrs (
    map
      (x: {
        name = lib.removeSuffix ".nix" (baseNameOf x);
        value = x;
      })
      [
        ./discord.nix
        ./easyeffects
        ./common.nix
        ./direnv.nix
        ./thunderbird.nix
        ./fish.nix
        ./foot.nix
        ./gaming.nix
        ./git.nix
        ./gpg.nix
        ./gtk.nix
        ./imv.nix
        ./laptop.nix
        ./minecraft.nix
        ./mpv.nix
        ./neovim.nix
        ./sioyek.nix
        ./ssh.nix
        ./starship.nix
        ./sunsetr.nix
        ./swaylock.nix
        ./wayland.nix
        ./xdg.nix
        ./yazi.nix
        ./zen.nix
        ./zellij.nix
        ./zsh.nix
        ./sops.nix
        ./niri.nix
        ./dsearch.nix
        ./tofi.nix
        ./swayimg.nix
        ./noctalia.nix
        ./home-manager.nix
      ]
  );

  defaultModules = lib.attrValues {
    inherit (homeModules)
      discord
      easyeffects
      common
      direnv
      gaming
      git
      gpg
      gtk
      imv
      minecraft
      mpv
      neovim
      ssh
      xdg
      yazi
      fish
      thunderbird
      sioyek
      starship
      sunsetr
      swaylock
      sops
      zen
      zellij
      wayland
      foot
      niri
      dsearch
      tofi
      swayimg
      noctalia
      home-manager
      ;
  };
in
{
  inherit homeModules;

  nixosModule =
    {
      inputs,
      self,
      config,
      ...
    }:
    {
      imports = [ inputs.home-manager.nixosModules.home-manager ];

      home-manager = {
        extraSpecialArgs = {
          inherit inputs self;
        };
        users."${config.owner}" = {
          imports = defaultModules;
        };
        useGlobalPkgs = true;
        useUserPackages = true;
      };
    };
}
