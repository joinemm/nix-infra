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
  ];

  disko.devices.disk.sda.device = "/dev/disk/by-path/pci-0000:06:00.0-scsi-0:0:0:0";

  networking.hostName = "oxygen";
  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "24.05";

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      radicale_auth.owner = "radicale";
    };
  };

  services.syncthing = {
    dataDir = "${volumePath}/syncthing";
    guiAddress = "0.0.0.0:8384";
    settings.gui = {
      user = "admin";
      # bcrypt hash until https://github.com/NixOS/nixpkgs/pull/290485 is merged
      password = "$2b$05$K03dR3Dhq92nHU6wpyH5f.4VYAnry8eDzvXiYfcRf1qZhsI4DymxO";
    };
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
        hosts = [
          "0.0.0.0:5232"
          "[::]:5232"
        ];
      };
      auth = {
        type = "htpasswd";
        htpasswd_filename = config.sops.secrets.radicale_auth.path;
        htpasswd_encryption = "autodetect";
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
          proxyPass = "http://127.0.0.1:8384";
        };
      }
      // ssl;

      "files.joinemm.dev" = {
        extraConfig = ''
          client_max_body_size 5G;
        '';
        locations."/" = {
          proxyPass = "http://100.64.0.7:3210";
        };
      }
      // ssl;

      "digitalocean.joinemm.dev" = mkRedirect "https://m.do.co/c/7251aebbc5e0";

      "vultr.joinemm.dev" = mkRedirect "https://vultr.com/?ref=8569244-6G";

      "hetzner.joinemm.dev" = mkRedirect "https://hetzner.cloud/?ref=JkprBlQwg9Kp";

      "stream.joinemm.dev" = {
        locations."/" = {
          proxyPass = "http://100.64.0.7:8096";
          proxyWebsockets = true;
        };
      }
      // ssl;

      "jellyfin.joinemm.dev" = mkRedirect "https://stream.joinemm.dev" // ssl;

      "request.joinemm.dev" = {
        locations."/" = {
          proxyPass = "http://100.64.0.7:5055";
          proxyWebsockets = true;
        };
      }
      // ssl;

      "photos.joinemm.dev" = {
        locations."/" = {
          proxyPass = "http://100.64.0.7:2284";
          proxyWebsockets = true;
        };
      }
      // ssl;

      "dav.joinemm.dev" = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:5232";
          extraConfig = ''
            proxy_pass_header Authorization;
          '';
        };
      }
      // ssl;
    };
}
