{
  user,
  lib,
  config,
  ...
}:
{
  xdg = {
    enable = true;

    userDirs = {
      enable = true;
      desktop = "${user.home}";
      templates = "${user.home}";
      publicShare = "${user.home}";
      documents = "${user.home}/documents";
      download = "${user.home}/downloads";
      music = "${user.home}/music";
      pictures = "${user.home}/pictures";
      videos = "${user.home}/videos";
    };

    desktopEntries = {
      "transmission-magnet" = {
        name = "Transmission add torrent";
        exec = ''add-torrent %u'';
        mimeType = [ "x-scheme-handler/magnet" ];
      };
    };

    # https://discourse.nixos.org/t/home-manager-and-the-mimeapps-list-file-on-plasma-kde-desktops/37694/7
    configFile."mimeapps.list" = lib.mkIf config.xdg.mimeApps.enable { force = true; };

    mimeApps =
      let
        associations =
          let
            file-manager = "thunar.desktop";
            editor = "nvim.desktop";
            browser = "zen-beta.desktop";
            video-player = "mpv.desktop";
            image-viewer = "swayimg.desktop";
          in
          {
            "application/pdf" = [ "sioyek.desktop" ];
            "image/gif" = [ image-viewer ];
            "image/jpeg" = [ image-viewer ];
            "image/png" = [ image-viewer ];
            "image/webp" = [ image-viewer ];
            "inode/directory" = [ file-manager ];
            "text/csv" = [ editor ];
            "text/html" = [ browser ];
            "text/plain" = [ editor ];
            "video/mp4" = [ video-player ];
            "video/webm" = [ video-player ];
            "video/x-matroska" = [ video-player ];
            "x-scheme-handler/http" = [ browser ];
            "x-scheme-handler/https" = [ browser ];
            "x-scheme-handler/chrome" = [ browser ];
            "application/x-extension-htm" = [ browser ];
            "application/x-extension-html" = [ browser ];
            "application/x-extension-shtml" = [ browser ];
            "application/xhtml+xml" = [ browser ];
            "application/x-extension-xhtml" = [ browser ];
            "application/x-extension-xht" = [ browser ];
            "x-scheme-handler/magnet" = [ "transmission-magnet.desktop" ];
            "x-scheme-handler/prusaslicer" = [ "PrusaSlicerURLProtocol.desktop" ];
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = [
              "libreoffice-writer.desktop"
            ];
          };
      in
      {
        enable = true;
        defaultApplications = associations;
        associations.added = associations;
      };
  };
}
