{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ inputs.niks3.nixosModules.niks3-auto-upload ];

  config = lib.mkMerge [
    {
      nix.settings.extra-substituters = [
        "https://cache.joinemm.dev"
      ];

      nix.settings.extra-trusted-public-keys = [
        "cache.joinemm.dev:/xB27CZPB5kZqhM265ExqoHKW3Cltn2R3OZaerATqo4="
      ];

      environment.systemPackages = [
        inputs.niks3.packages.${pkgs.stdenv.hostPlatform.system}.niks3
      ];

      services.niks3-auto-upload = {
        enable = lib.mkDefault false; # enabled on per-host basis
        serverUrl = "https://niks3.joinemm.dev";
        authTokenFile = config.sops.secrets.niks3-api-token.path;
      };
    }
    (lib.mkIf config.services.niks3-auto-upload.enable {
      sops.secrets.niks3-api-token = {
        owner = "root";
        restartUnits = [ "niks3-auto-upload.service" ];
      };
    })
  ];
}
