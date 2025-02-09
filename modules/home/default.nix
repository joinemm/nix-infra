{
  inputs,
  user,
  lib,
  pkgs,
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
        ./discord
        ./easyeffects
        ./polybar
        ./xmonad
        ./common.nix
        ./dunst.nix
        ./firefox.nix
        ./flameshot.nix
        ./gaming.nix
        ./git.nix
        ./gpg.nix
        ./gtk.nix
        ./imv.nix
        ./kdeconnect.nix
        ./mpv.nix
        ./neovim.nix
        ./picom.nix
        ./redshift.nix
        ./rofi.nix
        ./ssh-personal.nix
        ./ssh-work.nix
        ./wezterm.nix
        ./xdg.nix
        ./xinitrc.nix
        ./xresources.nix
        ./yazi.nix
        ./zathura.nix
        ./zen.nix
        ./fish.nix
        ./email.nix
      ]
  );
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
      imports = lib.flatten [
        (lib.attrValues homeModules)
      ];
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
