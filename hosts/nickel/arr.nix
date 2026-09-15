{
  lib,
  config,
  pkgs,
  inputs,
  mkBackup,
  ...
}:
let
  peerPort = 49035;
  jellyfinPort = 8096;
  autheliaAuth = ''
    auth_request /internal/authelia/authz;
    auth_request_set $redirection_url $upstream_http_location;
    error_page 401 =302 $redirection_url;
  '';
  autheliaLocation = {
    proxyPass = "http://127.0.0.1:9091/api/authz/auth-request";
    extraConfig = ''
      internal;
      proxy_pass_request_body off;
      proxy_set_header Content-Length "";
      proxy_set_header Connection "";
      proxy_set_header X-Original-Method $request_method;
      proxy_set_header X-Original-URL $scheme://$host$request_uri;
      proxy_set_header X-Forwarded-For $remote_addr;
    '';
  };
in
{
  imports = [
    inputs.nixarr.nixosModules.default
  ];

  sops.secrets = {
    "wireguard.conf".owner = "root";
    qui_oidc_client_secret = {
      owner = "qbittorrent";
      restartUnits = [ "qui.service" ];
    };
  };

  networking.firewall = {
    allowedTCPPorts = [
      peerPort
      jellyfinPort
    ];
    allowedUDPPorts = [
      peerPort
      jellyfinPort
    ];
  };

  nixarr.qbittorrent = {
    enable = true;
    inherit peerPort;
    vpn.enable = true;
    extraConfig = {
      BitTorrent = {
        "Session\\MaxActiveDownloads" = 10;
        "Session\\MaxActiveTorrents" = 20;
      };
    };
  };

  systemd.services.qui.environment = {
    QUI__OIDC_ENABLED = "true";
    QUI__OIDC_ISSUER = "https://auth.lab.joinemm.dev";
    QUI__OIDC_CLIENT_ID = "qui";
    QUI__OIDC_CLIENT_SECRET_FILE = config.sops.secrets.qui_oidc_client_secret.path;
    QUI__OIDC_REDIRECT_URL = "https://qbit.lab.joinemm.dev/api/auth/oidc/callback";
    QUI__OIDC_DISABLE_BUILT_IN_LOGIN = "true";
  };

  nixarr = {
    enable = true;
    exporters.enable = true;
    mediaDir = "/data/media";
    stateDir = "/var/lib/nixarr";
    mediaUsers = [ config.owner ];
  };

  systemd.services.jellyfin.serviceConfig = {
    UMask = lib.mkForce "0002"; # make jellyfin write files with group write access
  };

  services.jellyfin = {
    forceEncodingConfig = true;

    hardwareAcceleration = {
      enable = true;
      type = "qsv";
      device = "/dev/dri/renderD128";
    };

    transcoding = {
      enableHardwareEncoding = true;
      enableIntelLowPowerEncoding = true;
      enableSubtitleExtraction = true;
      enableToneMapping = true;
      throttleTranscoding = false;

      # Match the codec profiles exposed by the UHD 770's iHD driver.
      hardwareDecodingCodecs = {
        h264 = true;
        hevc = true;
        hevc10bit = true;
        hevcRExt10bit = true;
        hevcRExt12bit = true;
        mpeg2 = true;
        vc1 = true;
        vp8 = false;
        vp9 = true;
        av1 = true;
      };

      hardwareEncodingCodecs = {
        hevc = true;
        av1 = false; # AV1 hardware encoding requires a newer Intel GPU.
      };
    };
  };

  systemd.services.sonarr.environment.SONARR__AUTH__METHOD = "External";
  systemd.services.radarr.environment.RADARR__AUTH__METHOD = "External";

  nixarr = {
    jellyfin.enable = true; # 8096
    prowlarr.enable = true; # 9696
    radarr.enable = true; # 7878
    sonarr.enable = true; # 8989
    bazarr.enable = true; # 6767
    seerr.enable = true; # 5055
  };

  nixarr.vpn = {
    enable = true;
    wgConf = config.sops.secrets."wireguard.conf".path;
    exposeOnLAN = false;
    openUdpPorts = [ peerPort ];
    openTcpPorts = [ peerPort ];
    vpnTestService.enable = true;
  };

  nixarr.recyclarr = {
    enable = true;
    configFile = ./recyclarr.yml;
  };

  services.nginx.virtualHosts = {
    "qbit.lab.joinemm.dev" = {
      useACMEHost = "lab.joinemm.dev";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.nixarr.qbittorrent.webuiPort}";
        proxyWebsockets = true;
      };
    };

    "prowlarr.lab.joinemm.dev" = {
      useACMEHost = "lab.joinemm.dev";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.nixarr.prowlarr.port}";
        proxyWebsockets = true;
      };
    };

    "radarr.lab.joinemm.dev" = {
      useACMEHost = "lab.joinemm.dev";
      forceSSL = true;
      locations."/internal/authelia/authz" = autheliaLocation;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.nixarr.radarr.port}";
        proxyWebsockets = true;
        extraConfig = autheliaAuth;
      };
    };

    "sonarr.lab.joinemm.dev" = {
      useACMEHost = "lab.joinemm.dev";
      forceSSL = true;
      locations."/internal/authelia/authz" = autheliaLocation;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.nixarr.sonarr.port}";
        proxyWebsockets = true;
        extraConfig = autheliaAuth;
      };
    };

    "bazarr.lab.joinemm.dev" = {
      useACMEHost = "lab.joinemm.dev";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.nixarr.bazarr.port}";
        proxyWebsockets = true;
      };
    };

    "seerr.lab.joinemm.dev" = {
      useACMEHost = "lab.joinemm.dev";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.nixarr.seerr.port}";
        proxyWebsockets = true;
      };
    };

    "jellyfin.lab.joinemm.dev" = {
      useACMEHost = "lab.joinemm.dev";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString jellyfinPort}";
        extraConfig = ''
          proxy_buffering off;
        '';
      };
      locations."/socket" = {
        proxyPass = "http://127.0.0.1:${toString jellyfinPort}";
        proxyWebsockets = true;
      };
    };
  };

  hjem.users.${config.owner}.files = {
    ".config/recyclarr/recyclarr.yml".source = ./recyclarr.yml;
  };

  environment.systemPackages = with pkgs; [
    wireguard-tools
    intel-gpu-tools
    recyclarr
  ];

  services.restic.backups.arr = mkBackup "arr" {
    paths = [
      (config.nixarr.stateDir + "/bazarr")
      (config.nixarr.stateDir + "/jellyfin")
      (config.nixarr.stateDir + "/seerr")
      (config.nixarr.stateDir + "/prowlarr")
      (config.nixarr.stateDir + "/radarr")
      (config.nixarr.stateDir + "/sonarr")
    ];
    extraBackupArgs = [
      "--exclude='**/logs'"
      "--exclude='**/log'"
    ];
  };
}
