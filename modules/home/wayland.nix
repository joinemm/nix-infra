{
  lib,
  config,
  user,
  pkgs,
  ...
}:
{
  systemd.user.services.swaybg = {
    Install.WantedBy = [ config.wayland.systemd.target ];
    Service = {
      ExecStart = "${lib.getExe pkgs.swaybg} -m fill -i /home/${user.name}/.wallpaper";
      Restart = "on-failure";
    };
    # TODO: restart on ~/.wallpaper change
  };

  systemd.user.services.way-displays = {
    Install.WantedBy = [ config.wayland.systemd.target ];
    Service = {
      ExecStart = "${lib.getExe pkgs.way-displays}";
      Restart = "on-failure";
    };
  };

  home.packages = with pkgs; [
    way-displays
    satty
    grim
    slurp
    wl-clipboard
    hyprpicker
    wlopm
  ];

  services.avizo.enable = true;

  programs.tofi = {
    enable = true;
    settings = {
      width = "100%";
      height = "100%";
      border-width = 0;

      outline-width = 0;
      padding-left = "35%";
      padding-top = "35%";

      result-spacing = 20;
      num-results = 5;
      font = "monospace";
      background-color = "#000A";
    };
  };

  services.mako = {
    enable = true;
    settings = {
      sort = "-time";
      layer = "overlay";
      background-color = "#1e1e2e";
      width = 400;
      height = 200;
      border-size = 0;
      border-color = "#6C3483";
      border-radius = 0;
      icons = true;
      max-icon-size = 64;
      default-timeout = 5000;
      ignore-timeout = 0;
      font = "monospace 12";
      margin = 16;
      padding = "12,20";

      "urgency=low" = {
        border-color = "#444444";
      };

      "urgency=normal" = {
        border-color = "#6F8FDB";
      };

      "urgency=critical" = {
        border-color = "#ff5555";
        default-timeout = 0;
      };
    };
  };

  xdg.configFile."satty/config.toml".source = pkgs.writers.writeTOML "config.toml" {
    general = {
      fullscreen = true;
      early-exit = true;
      initial-tool = "brush";
      copy-command = "wl-copy";
      default-hide-toolbars = true;
    };
  };

}
