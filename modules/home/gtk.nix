{ pkgs, osConfig, ... }:
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
      theme = {
        name = "Dracula";
        package = pkgs.dracula-theme;
      };
      iconTheme = {
        name = "WhiteSur";
        package = pkgs.whitesur-icon-theme;
      };

      gtk3 = disableDecorations;
      gtk4 = disableDecorations;
    };
}
