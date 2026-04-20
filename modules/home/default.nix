{
  inputs,
  lib,
  pkgs,
  self,
  config,
  ...
}:
let
  homeModules = lib.listToAttrs (
    map
      (x: {
        name = lib.removeSuffix ".nix" (baseNameOf x);
        value = x;
      })
      [
        # directores
        ./discord
        ./easyeffects
        ./waybar
        ./dms
        # files in alphabetical order
        ./common.nix
        ./chromium.nix
        ./thunderbird.nix
        ./firefox.nix
        ./fish.nix
        ./flameshot.nix
        ./foot.nix
        ./gaming.nix
        ./git.nix
        ./gpg.nix
        ./gtk.nix
        ./screenlocker.nix
        ./imv.nix
        ./kdeconnect.nix
        ./laptop.nix
        ./mpv.nix
        ./neovim.nix
        ./river.nix
        ./sioyek.nix
        ./ssh.nix
        ./starship.nix
        ./swaybg.nix
        ./wayland.nix
        ./wezterm.nix
        ./xdg.nix
        ./yazi.nix
        ./zathura.nix
        ./zen.nix
        ./zsh.nix
        ./sops.nix
        ./swww.nix
        ./glide.nix
        ./niri.nix
        ./dsearch.nix
        ./gammastep.nix
        ./mako.nix
        ./tofi.nix
        ./swayimg.nix
      ]
  );

  waylandModules = {
    inherit (homeModules)
      wayland
      foot
      niri
      dms
      dsearch
      gammastep
      mako
      tofi
      swayimg
      ;
  };

  defaultModules = {
    inherit (homeModules)
      discord
      easyeffects
      common
      gaming
      git
      gpg
      gtk
      imv
      mpv
      neovim
      ssh
      wezterm
      xdg
      yazi
      fish
      thunderbird
      sioyek
      starship
      sops
      zen
      ;
  };
in
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager = {
    extraSpecialArgs = {
      inherit inputs self;
    };
    users."${config.owner}" = {
      imports = (lib.attrValues defaultModules) ++ (lib.attrValues waylandModules);
    };
    useGlobalPkgs = true;
    useUserPackages = true;

    # TODO: use this instead of imports
    sharedModules = [ ];
  };

  networking.firewall = rec {
    allowedTCPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
    allowedUDPPortRanges = allowedTCPPortRanges;
  };

  users.defaultUserShell = pkgs.fish;
  programs.fish.enable = true;
}
