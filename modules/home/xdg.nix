{
  lib,
  config,
  ...
}:
{
  xdg = {
    enable = true;

    userDirs =
      let
        home = config.home.homeDirectory;
      in
      {
        enable = true;
        desktop = home;
        templates = home;
        publicShare = home;
        documents = home + "/documents";
        download = home + "/downloads";
        music = home + "/music";
        pictures = home + "/pictures";
        videos = home + "/videos";
      };

    # https://discourse.nixos.org/t/home-manager-and-the-mimeapps-list-file-on-plasma-kde-desktops/37694/7
    configFile."mimeapps.list" = lib.mkIf config.xdg.mimeApps.enable { force = true; };

    mimeApps =
      let
        file-manager = "thunar.desktop";
        editor = "nvim.desktop";
        browser = "zen-beta.desktop";
        video-player = "mpv.desktop";
        image-viewer = "swayimg.desktop";
        email = "userapp-Thunderbird-FSRFG3.desktop";
        associations = {
          # images
          "image/gif" = [ image-viewer ];
          "image/jpeg" = [ image-viewer ];
          "image/png" = [ image-viewer ];
          "image/webp" = [ image-viewer ];
          # videos
          "video/mp4" = [ video-player ];
          "video/webm" = [ video-player ];
          "video/x-matroska" = [ video-player ];
          # browser
          "text/html" = [ browser ];
          "x-scheme-handler/http" = [ browser ];
          "x-scheme-handler/https" = [ browser ];
          "x-scheme-handler/chrome" = [ browser ];
          "application/x-extension-htm" = [ browser ];
          "application/x-extension-html" = [ browser ];
          "application/x-extension-shtml" = [ browser ];
          "application/xhtml+xml" = [ browser ];
          "application/x-extension-xhtml" = [ browser ];
          "application/x-extension-xht" = [ browser ];
          # thunderbird
          "x-scheme-handler/mailto" = [ email ];
          "message/rfc822" = [ email ];
          "x-scheme-handler/mid" = [ email ];
          "x-scheme-handler/news" = [ email ];
          "x-scheme-handler/snews" = [ email ];
          "x-scheme-handler/nntp" = [ email ];
          "x-scheme-handler/feed" = [ email ];
          "application/rss+xml" = [ email ];
          "application/x-extension-rss" = [ email ];
          "x-scheme-handler/webcal" = [ email ];
          "text/calendar" = [ email ];
          "application/x-extension-ics" = [ email ];
          "x-scheme-handler/webcals" = [ email ];
          # other
          "inode/directory" = [ file-manager ];
          "text/csv" = [ editor ];
          "text/plain" = [ editor ];
          "application/pdf" = [ "sioyek.desktop" ];
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
