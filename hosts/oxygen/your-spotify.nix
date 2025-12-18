{ config, pkgs, ... }:
{
  sops.secrets.spotify_client_secret.owner = "root";

  environment.systemPackages = with pkgs; [
    mongosh
  ];

  services.your_spotify =
    let
      domain = "fm.joinemm.dev";
    in
    {
      enable = true;
      package = pkgs.your_spotify.overrideAttrs (
        final: _: {
          version = "git";
          src = pkgs.fetchFromGitHub {
            owner = "Yooooomi";
            repo = "your_spotify";
            rev = "bb8dc001ce6e43fa1f301008e9bee37b01a10aa9";
            hash = "sha256-eVKBrYE6U80G1SS/7nIl4fZb2BELb9lQizKcdcEIJIM=";
          };

          offlineCache = pkgs.fetchYarnDeps {
            yarnLock = final.src + "/yarn.lock";
            hash = "sha256-JP5enfy8yyMjZpp0U72S0uR5zJkhpvxog38icOBtQRQ=";
          };
        }
      );
      settings = {
        PORT = 8081;
        SPOTIFY_PUBLIC = "8e870cbcc8d54fb8ad1ae8c33878b7f6";
        CLIENT_ENDPOINT = "https://${domain}";
        API_ENDPOINT = "https://${domain}/api";
      };
      spotifySecretFile = config.sops.secrets.spotify_client_secret.path;
      nginxVirtualHost = domain;
    };

  # used by your_spotify
  services.mongodb = {
    enable = true;
    package = pkgs.mongodb-ce;
  };

  # recommended mongodb tweaks
  systemd.services.mongodb.serviceConfig.LimitNOFILE = 64000;
  systemd.services.mongodb.environment.GLIBC_TUNABLES = "glibc.pthread.rseq=0";

  services.nginx.virtualHosts."fm.joinemm.dev" = {
    enableACME = true;
    forceSSL = true;
    # imported spotify history files can be very large
    extraConfig = ''
      client_max_body_size 0;
    '';
    locations."/api/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.your_spotify.settings.PORT}/";
      extraConfig = ''
        proxy_set_header X-Script-Name /api;
        proxy_pass_header Authorization;
      '';
    };
  };
}
