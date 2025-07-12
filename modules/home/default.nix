{
  inputs,
  user,
  lib,
  pkgs,
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
        ./dunst.nix
        ./email.nix
        ./firefox.nix
        ./fish.nix
        ./flameshot.nix
        ./foot.nix
        ./gaming.nix
        ./git.nix
        ./gpg.nix
        ./gtk.nix
        ./hidpi.nix
        ./hyprlock.nix
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
        ./ssh-personal.nix
        ./ssh-work.nix
        ./starship.nix
        ./wayland.nix
        ./wezterm.nix
        ./xdg.nix
        ./xinitrc.nix
        ./xresources.nix
        ./yazi.nix
        ./zathura.nix
        ./zen.nix
        ./zsh.nix
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
      hyprlock
      waybar
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
      ssh-personal
      ssh-work
      wezterm
      xdg
      yazi
      zen
      fish
      email
      sioyek
      flameshot
      ;
  };
in
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  environment.extraInit =
    let
      homeManagerSessionVars = "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh";
    in
    "[[ -f ${homeManagerSessionVars} ]] && source ${homeManagerSessionVars}";

  home-manager = {
    extraSpecialArgs = {
      inherit user inputs;
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
