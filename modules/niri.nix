{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.niri.nixosModules.niri
  ];
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = false;
    wlr.enable = true;
    config = {
      common = {
        default = [
          "gtk"
          "gnome"
        ];
      };
      niri = {
        default = [
          "gtk"
          "gnome"
        ];
      };
    };
    extraPortals = [
      pkgs.xdg-desktop-portal-wlr
      pkgs.xdg-desktop-portal-gtk
    ];
  };
  systemd.user.services = {
    xdg-desktop-portal = {
      after = [ "xdg-desktop-autostart.target" ];
    };

    xdg-desktop-portal-gtk = {
      after = [ "xdg-desktop-autostart.target" ];
    };

    xdg-desktop-portal-gnome = {
      after = [ "xdg-desktop-autostart.target" ];
    };

    niri-flake-polkit = {
      after = [ "xdg-desktop-autostart.target" ];
    };
  };

  nixpkgs.overlays = [ inputs.niri.overlays.niri ];
  programs.niri = {
    enable = true;
    package = pkgs.niri-unstable;
  };

  environment.systemPackages = with pkgs; [
    xwayland-satellite # XWayland compatibility for apps/games
    nautilus
  ];
}
