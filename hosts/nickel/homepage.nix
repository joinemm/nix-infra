{ config, ... }:
{
  sops.secrets.homepage_env.owner = "root";

  services.homepage-dashboard = {
    enable = true;
    allowedHosts = "lab.joinemm.dev";
    environmentFile = config.sops.secrets.homepage_env.path;
    settings = {
      layout = [
        {
          "Media" = {
            style = "row";
            columns = "2";
          };
          "System" = {
            style = "row";
            columns = "1";
          };
        }
      ];
    };
    services = [
      {
        "Media" = [
          {
            audiobookshelf = {
              icon = "audiobookshelf.png";
              href = "https://audio.lab.joinemm.dev";
              widget = {
                type = "audiobookshelf";
                url = "http://127.0.0.1:${toString config.services.audiobookshelf.port}";
                key = "{{HOMEPAGE_VAR_AUDIOBOOKSHELF_KEY}}";
              };
            };
          }
          {
            radarr = {
              icon = "radarr.png";
              href = "https://radarr.lab.joinemm.dev";
              widget = {
                type = "radarr";
                url = "http://127.0.0.1:7878";
                key = "{{HOMEPAGE_VAR_RADARR_KEY}}";
              };
            };
          }
          {
            sonarr = {
              icon = "sonarr.png";
              href = "https://sonarr.lab.joinemm.dev";
              widget = {
                type = "sonarr";
                url = "http://127.0.0.1:8989";
                key = "{{HOMEPAGE_VAR_SONARR_KEY}}";
              };
            };
          }
          {
            jellyfin = {
              icon = "jellyfin.png";
              href = "https://jellyfin.lab.joinemm.dev";
              widget = {
                type = "jellyfin";
                url = "http://127.0.0.1:8096";
                key = "{{HOMEPAGE_VAR_JELLYFIN_KEY}}";
                enableBlocks = true;
                enableUser = true;
                showEpisodeNumber = true;
              };
            };
          }
        ];
      }
      {
        "System" = [
          {
            scrutiny = {
              icon = "scrutiny.png";
              href = "https://scrutiny.lab.joinemm.dev";
              widget = {
                type = "scrutiny";
                url = "http://127.0.0.1:${toString config.services.scrutiny.settings.web.listen.port}";
              };
            };
          }
        ];
      }
    ];
  };

}
