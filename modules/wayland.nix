{
  security.pam.services = {
    ly = {
      fprintAuth = false;
      u2fAuth = false;
      enableGnomeKeyring = true;
    };
    swaylock = {
      fprintAuth = false;
      u2fAuth = false;
    };
  };

  services.gnome.gnome-keyring.enable = true;

  systemd.services.display-manager.environment.XDG_CURRENT_DESKTOP = "X-NIXOS-SYSTEMD-AWARE";

  services.displayManager.ly = {
    enable = true;
    x11Support = false;
    settings = {
      allow_empty_password = false;
      clear_password = true;

      xinitrc = ""; # Hide xinitrc option (X11 not configured)
      setup_cmd = ""; # Don't use xsession-wrapper; fixes shell sessions
    };
  };
}
