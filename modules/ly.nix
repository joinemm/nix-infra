{ lib, config, ... }: {
  services.displayManager.ly = rec {
    enable = true;
    x11Support = false;
    settings = {
      allow_empty_password = false;
      clear_password = true;
    }
    // (lib.optionalAttrs (!x11Support) {
      xinitrc = ""; # Hide xinitrc option (X11 not configured)
      setup_cmd = ""; # Don't use xsession-wrapper; fixes shell sessions
    });
  };

  systemd.services.display-manager.environment.XDG_CURRENT_DESKTOP = "X-NIXOS-SYSTEMD-AWARE";

  # Ly delegates authentication to the login PAM stack. Require a password
  # there so GNOME Keyring receives it and can unlock the login keyring.
  security.pam.services.login = {
    fprintAuth = false;
    u2fAuth = false;
    enableGnomeKeyring = config.services.gnome.gnome-keyring.enable;
  };
}
