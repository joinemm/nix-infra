{
  pkgs,
  config,
  osConfig,
  ...
}:
{
  home = {
    pointerCursor = {
      package = pkgs.phinger-cursors;
      name = "phinger-cursors-light";
      size = 24;
      x11.enable = osConfig.services.xserver.enable;
      gtk.enable = true;
    };
  };

  gtk =
    let
      # https://codeberg.org/river/wiki#how-do-i-disable-gtk-decorations-e-g-title-bar
      disableDecorations = {
        extraConfig = {
          gtk-dialogs-use-header = false;
        };
        extraCss = # css
          ''
            /* No (default) title bar on wayland */
            headerbar.default-decoration {
              margin-bottom: 50px;
              margin-top: -100px;
            }

            /* rm -rf window shadows */
            window.csd,             /* gtk4? */
            window.csd decoration { /* gtk3 */
              box-shadow: none;
            }
          '';
      };
    in
    {
      enable = true;

      gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";

      font = {
        name = "Inter";
        package = pkgs.google-fonts.override { fonts = [ "Inter" ]; };
        size = 10;
      };

      iconTheme = {
        name = "WhiteSur";
        package = pkgs.whitesur-icon-theme;
      };

      theme = {
        name = "adw-gtk3-dark";
        package = pkgs.adw-gtk3;
      };

      # gtk3 = disableDecorations;
      # gtk4 = disableDecorations;
    };
}
