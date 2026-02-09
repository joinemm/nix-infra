{
  inputs,
  user,
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
        name = lib.removeSuffix ".nix" (builtins.baseNameOf x);
        value = x;
      })
      [
        # directores
        ./discord
        ./easyeffects
        ./polybar
        ./waybar
        ./xmonad
        # files in alphabetical order
        ./common.nix
        ./chromium.nix
        ./dunst.nix
        ./thunderbird.nix
        ./firefox.nix
        ./fish.nix
        ./flameshot.nix
        ./foot.nix
        ./gaming.nix
        ./git.nix
        ./gpg.nix
        ./gtk.nix
        ./hidpi.nix
        ./screenlocker.nix
        ./imv.nix
        ./kdeconnect.nix
        ./laptop.nix
        ./mpv.nix
        ./neovim.nix
        ./picom.nix
        ./redshift.nix
        ./river.nix
        ./rofi.nix
        ./sioyek.nix
        ./ssh.nix
        ./starship.nix
        ./swaybg.nix
        ./wayland.nix
        ./wezterm.nix
        ./xdg.nix
        ./xinitrc.nix
        ./xresources.nix
        ./yazi.nix
        ./zathura.nix
        ./zen.nix
        ./zsh.nix
        ./sops.nix
        ./swww.nix
        ./glide.nix
        ./gpu-screen-recorder.nix
      ]
  );

  x11Modules = {
    inherit (homeModules)
      polybar
      xmonad
      dunst
      picom
      redshift
      rofi
      xinitrc
      xresources
      ;
  };

  waylandModules = {
    inherit (homeModules)
      wayland
      river
      foot
      screenlocker
      waybar
      swww
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
      glide
      fish
      thunderbird
      sioyek
      starship
      sops
      gpu-screen-recorder
      zen
      chromium
      ;
  };
in
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager = {
    extraSpecialArgs = {
      inherit user inputs self;
    };
    users."${user.name}" = {
      imports =
        (lib.attrValues defaultModules)
        ++ (
          if config.services.xserver.enable then
            (lib.attrValues x11Modules)
          else
            (lib.attrValues waylandModules)
        );
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

  users.users."${user.name}".shell = pkgs.fish;
  programs.fish.enable = true;
}
