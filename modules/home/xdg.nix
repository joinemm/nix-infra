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
            browser = "glide.desktop";
            video-player = "mpv.desktop";
            image-viewer = "swayimg.desktop";
          in
          {
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
            "x-scheme-handler/mailto" = [ "userapp-Thunderbird-FSRFG3.desktop" ];
            "message/rfc822" = [ "userapp-Thunderbird-FSRFG3.desktop" ];
            "x-scheme-handler/mid" = [ "userapp-Thunderbird-FSRFG3.desktop" ];
            "x-scheme-handler/news" = [ "userapp-Thunderbird-LB3HG3.desktop" ];
            "x-scheme-handler/snews" = [ "userapp-Thunderbird-LB3HG3.desktop" ];
            "x-scheme-handler/nntp" = [ "userapp-Thunderbird-LB3HG3.desktop" ];
            "x-scheme-handler/feed" = [ "userapp-Thunderbird-YG0GG3.desktop" ];
            "application/rss+xml" = [ "userapp-Thunderbird-YG0GG3.desktop" ];
            "application/x-extension-rss" = [ "userapp-Thunderbird-YG0GG3.desktop" ];
            "x-scheme-handler/webcal" = [ "userapp-Thunderbird-04IDG3.desktop" ];
            "text/calendar" = [ "userapp-Thunderbird-04IDG3.desktop" ];
            "application/x-extension-ics" = [ "userapp-Thunderbird-04IDG3.desktop" ];
            "x-scheme-handler/webcals" = [ "userapp-Thunderbird-04IDG3.desktop" ];
            # other
            "inode/directory" = [ file-manager ];
            "text/csv" = [ editor ];
            "text/plain" = [ editor ];
            "application/pdf" = [ "sioyek.desktop" ];
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
