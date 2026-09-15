{ config, mkBackup, ... }:
{
  sops.secrets.immich_oidc_client_secret = {
    owner = config.services.immich.user;
    restartUnits = [ "immich-server.service" ];
  };

  services.immich = {
    enable = true;
    host = "127.0.0.1";
    environment = {
      TZ = "Europe/Helsinki";
      IMMICH_TELEMETRY_INCLUDE = "all"; # expose all prometheus metrics
    };
    settings = {
      oauth = {
        enabled = true;
        clientId = "immich";
        clientSecret._secret = config.sops.secrets.immich_oidc_client_secret.path;
        issuerUrl = "https://auth.lab.joinemm.dev";
        autoLaunch = true;
        buttonText = "Login with Authelia";
        tokenEndpointAuthMethod = "client_secret_basic";
      };
      server = {
        externalDomain = "https://photos.joinemm.dev";
      };
      passwordLogin.enabled = false;
      newVersionCheck.enabled = false;
      storageTemplate = {
        enabled = true;
        template = "{{y}}/{{MM}}-{{MMMM}}/{{filename}}";
      };
    };
  };

  users.default.extraGroups = [ "immich" ];

  services.immich-public-proxy = {
    enable = true;
    openFirewall = true;
    port = 2284;
    immichUrl = "http://127.0.0.1:${toString config.services.immich.port}";
    settings = {
      ipp = {
        downloadOriginalPhoto = true;
        showGalleryTitle = true;
        allowDownloadAll = true;
      };
      lightGallery = {
        controls = true;
        download = true;
        mobileSettings = {
          showCloseIcon = true;
          download = true;
          controls = false;
        };
      };
    };
  };

  services.nginx.virtualHosts."immich.lab.joinemm.dev" = {
    useACMEHost = "lab.joinemm.dev";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.immich.port}";
      proxyWebsockets = true;
    };
    extraConfig = ''
      client_max_body_size 0;
      proxy_buffering off;
      proxy_request_buffering off;
      client_body_buffer_size 1024k;
    '';
  };

  services.restic.backups.immich = mkBackup "immich" {
    paths = [ config.services.immich.mediaLocation ];
  };
}
