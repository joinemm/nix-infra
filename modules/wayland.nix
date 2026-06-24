{
  security.pam.services = {
    ly = {
      fprintAuth = false;
      u2fAuth = false;
    };
  };

  systemd.services.display-manager.environment.XDG_CURRENT_DESKTOP = "X-NIXOS-SYSTEMD-AWARE";

  services.displayManager.ly = {
    enable = true;
    x11Support = false;
    settings = {
      bigclock = "en";
      allow_empty_password = false;
      animation = "gameoflife";
      clear_password = true;
    };
  };
}
