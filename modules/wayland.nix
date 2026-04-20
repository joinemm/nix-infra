{ lib, ... }:
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

  services.displayManager = {
    enable = true;
    ly = {
      enable = true;
      x11Support = false;
      settings = {
        animation = "matrix";
      };
    };
  };
}
