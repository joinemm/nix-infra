{ lib, ... }:
let
  homeModules = lib.listToAttrs (
    map
      (x: {
        name = lib.removeSuffix ".nix" (baseNameOf x);
        value = x;
      })
      [
        ./discord
        ./easyeffects
        ./waybar
        ./dms
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

  defaultModules = lib.attrValues {
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
in
{
  inherit homeModules;

  nixosModule =
    {
      inputs,
      pkgs,
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

      # KDE connect firewall rules
      networking.firewall = rec {
        allowedTCPPortRanges = [
          {
            from = 1714;
            to = 1764;
          }
        ];
        allowedUDPPortRanges = allowedTCPPortRanges;
      };

      # Set fish as default shell
      users.defaultUserShell = pkgs.fish;
      programs.fish.enable = true;
    };
}
