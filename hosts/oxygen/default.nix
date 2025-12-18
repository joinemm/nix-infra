{
  self,
  lib,
  inputs,
  config,
  ...
}:
let
  volumePath = "/mnt/data";
in
{
  imports = lib.flatten [
    (with self.profiles; [
      core
      server
    ])
    (with self.nixosModules; [
      hetzner
      nginx
      tailscale
      syncthing
      nebula
    ])
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops
    inputs.nix-topology.nixosModules.default
    ../../disko/hetzner-osdisk.nix
    (import ../../disko/hetzner-block-storage.nix {
      id = "100958858";
      mountpoint = volumePath;
    })
    ./headscale.nix
    ./umami.nix
    ./your-spotify.nix
    ./weddingshare.nix
  ];

  disko.devices.disk.sda.device = "/dev/disk/by-path/pci-0000:06:00.0-scsi-0:0:0:0";

  networking.hostName = "oxygen";
  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "25.11";

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      radicale_auth.owner = "radicale";
      weddingshare_env.owner = "root";
      syncthing_password.owner = "root";
      syncthing_cert.owner = "root";
      syncthing_key.owner = "root";
      nebula_key.owner = config.nebula.user;
    };
  };

  nebula = {
    enable = true;
    cert = ./nebula.crt;
    isLighthouse = true;
    key = config.sops.secrets.nebula_key.path;
  };

  systemd.tmpfiles.rules = [
    "d /mnt/data/syncthing 0755 joonas users"
  ];

  services.syncthing = {
    dataDir = "${volumePath}/syncthing";
    settings.gui.insecureSkipHostcheck = true;

    guiPasswordFile = config.sops.secrets.syncthing_password.path;
    key = config.sops.secrets.syncthing_key.path;
    cert = config.sops.secrets.syncthing_cert.path;

    settings.folders = {
      "code".enable = true;
      "documents".enable = true;
      "notes".enable = true;
      "pictures".enable = true;
      "videos".enable = true;
      "work".enable = true;
      "projects".enable = true;
    };
  };

  services.radicale = {
    enable = true;
    settings = {
      server = {
        hosts = "127.0.0.1:5232";
      };
      auth = {
        type = "htpasswd";
        htpasswd_filename = config.sops.secrets.radicale_auth.path;
        htpasswd_encryption = "bcrypt";
      };
      storage = {
        filesystem_folder = "/var/lib/radicale/collections";
      };
    };
    rights = {
      root = {
        user = ".+";
        collection = "";
        permissions = "R";
      };

      principal = {
        user = ".+";
        collection = "{user}";
        permissions = "RW";
      };

      calendars = {
        user = ".+";
        collection = "{user}/[^/]+";
        permissions = "rw";
      };

      public = {
        user = ".*";
        collection = "public/[^/]+";
        permissions = "r";
      };
    };
  };

  services.weddingshare = {
    enable = true;
    environmentFile = config.sops.secrets.weddingshare_env.path;
    uploadsDir = volumePath + "/event-uploads";
    settings = {
      title = "EventShare";
      baseUrl = "eventshare.joinemm.dev";
    };
  };

  services.nginx.virtualHosts =
    let
      ssl = {
        enableACME = true;
        forceSSL = true;
      };
      mkRedirect =
        to:
        {
          locations."/" = {
            return = "302 ${to}";
          };
        }
        // ssl;
    in
    {
      "git.joinemm.dev" = {
        serverAliases = [ "github.joinemm.dev" ];
        locations = {
          "/" = {
            return = "302 https://github.com/joinemm";
          };
          "~ (?<repo>[^/\\s]+)" = {
            return = "302 https://github.com/joinemm/$repo";
          };
        };
      }
      // ssl;

      "sync.joinemm.dev" = {
        serverAliases = [ "syncthing.joinemm.dev" ];
        locations."/" = {
          proxyPass = "http://${config.services.syncthing.guiAddress}";
        };
      }
      // ssl;

      "files.joinemm.dev" = {
        extraConfig = ''
          client_max_body_size 5G;
        '';
        locations."/" = {
          proxyPass = "http://10.6.9.2:3210";
        };
      }
      // ssl;

      "digitalocean.joinemm.dev" = mkRedirect "https://m.do.co/c/7251aebbc5e0";

      "vultr.joinemm.dev" = mkRedirect "https://vultr.com/?ref=8569244-6G";

      "hetzner.joinemm.dev" = mkRedirect "https://hetzner.cloud/?ref=JkprBlQwg9Kp";

      "stream.joinemm.dev" = {
        locations."/" = {
          proxyPass = "http://10.6.9.2:8096";
          proxyWebsockets = true;
        };
      }
      // ssl;

      "jellyfin.joinemm.dev" = mkRedirect "https://stream.joinemm.dev" // ssl;

      "request.joinemm.dev" = {
        locations."/" = {
          proxyPass = "http://10.6.9.2:5055";
          proxyWebsockets = true;
        };
      }
      // ssl;

      "photos.joinemm.dev" = {
        locations."/" = {
          proxyPass = "http://10.6.9.2:2284";
          proxyWebsockets = true;
        };
      }
      // ssl;

      "dav.joinemm.dev" = {
        locations."/" = {
          proxyPass = "http://${config.services.radicale.settings.server.hosts}";
          extraConfig = ''
            proxy_pass_header Authorization;
          '';
        };
      }
      // ssl;

      "eventshare.joinemm.dev" = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:5000";
        };
      }
      // ssl;
    };

  networking.firewall.allowedUDPPorts = [ 4242 ];
}
