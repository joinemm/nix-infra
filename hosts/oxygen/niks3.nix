{ config, inputs, ... }:
{
  imports = [
    inputs.niks3.nixosModules.default
  ];
  sops.secrets =
    let
      niks3Secret = {
        owner = "niks3";
        restartUnits = [
          "niks3.service"
          "niks3-gc.service"
        ];
      };
    in
    {
      niks3-api-token = niks3Secret;
      niks3-signing-key = niks3Secret;
      niks3-s3-access-key = niks3Secret;
      niks3-s3-secret-key = niks3Secret;
    };

  services.niks3 = {
    enable = true;
    httpAddr = "127.0.0.1:5751";

    apiTokenFile = config.sops.secrets.niks3-api-token.path;
    signKeyFiles = [ config.sops.secrets.niks3-signing-key.path ];

    s3 = {
      endpoint = "d9af84873d09ccab2e91fdae76eb0a54.r2.cloudflarestorage.com";
      bucket = "binarycache";
      region = "auto";
      useSSL = true;
      accessKeyFile = config.sops.secrets.niks3-s3-access-key.path;
      secretKeyFile = config.sops.secrets.niks3-s3-secret-key.path;
    };

    gc = {
      enable = true;
      olderThan = "336h"; # 2 weeks
      failedUploadsOlderThan = "6h";
      schedule = "daily";
      randomizedDelaySec = 1800;
    };

    # Generates a landing page with usage instructions and public keys.
    # This requires exposing the bucket publicly on this URL,
    # as well as the following cloudflare URL rewrite rule:
    # match filter: (http.host eq "cache.joinemm.dev" and http.request.uri.path eq "/")
    # static rewrite to: /index.html
    cacheUrl = "https://cache.joinemm.dev";

    # Accept GitHub Actions OIDC tokens
    oidc.providers.github = {
      issuer = "https://token.actions.githubusercontent.com";
      audience = "https://${config.services.niks3.nginx.domain}";
      boundClaims = {
        repository_owner = [ "joinemm" ];
      };
    };

    nginx = {
      enable = true;
      # Domain for the niks3 server, not for the binary cache.
      # This is used by `niks3 push`
      domain = "niks3.joinemm.dev";
    };
  };
}
