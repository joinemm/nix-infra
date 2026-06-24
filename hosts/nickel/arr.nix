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
in
{
  imports = [
    inputs.nixarr.nixosModules.default
  ];

  sops.secrets = {
    "wireguard.conf".owner = "root";
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
    extraConfig = { };
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
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.nixarr.radarr.port}";
        proxyWebsockets = true;
      };
    };

    "sonarr.lab.joinemm.dev" = {
      useACMEHost = "lab.joinemm.dev";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.nixarr.sonarr.port}";
        proxyWebsockets = true;
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
