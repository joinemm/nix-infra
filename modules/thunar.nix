{ pkgs, ... }:
{
  services = {
    # smb
    gvfs.enable = true;
    avahi.enable = true;

    udisks2.mountOnMedia = true;
    tumbler.enable = true;
  };

  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin
      thunar-volman
      thunar-media-tags-plugin
    ];
  };

  environment.systemPackages = with pkgs; [
    webp-pixbuf-loader # thumbnails for .webp
    ffmpegthumbnailer # thumbnails for video files
    poppler # thumbnails for .pdf

    # smb
    gvfs
    glib
    smbclient-ng
    cifs-utils
    avahi
  ];
}
