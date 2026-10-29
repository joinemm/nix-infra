{
  services.audiobookshelf = {
    enable = true;
    group = "media";
  };

  systemd.tmpfiles.rules = [ "d /data/media/audiobooks 0775 audiobookshelf media - -" ];
  systemd.services.audiobookshelf.unitConfig.RequiresMountsFor = [ "/data/media/audiobooks" ];
}
