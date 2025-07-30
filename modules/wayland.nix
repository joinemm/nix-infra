{ lib, pkgs, ... }:
{
  security.pam.services = {
    hyprlock.fprintAuth = false; # use hyprlock's built in fprint implementation
    ly = {
      enableGnomeKeyring = true;
      fprintAuth = false;
      u2fAuth = false;
    };
  };

  services.xserver.enable = lib.mkForce false;

  systemd.services.display-manager.environment.XDG_CURRENT_DESKTOP = "X-NIXOS-SYSTEMD-AWARE";

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  programs.river = {
    enable = true;
    xwayland.enable = true;
  };

  services.displayManager = {
    enable = true;
    ly.enable = true;
  };
}
