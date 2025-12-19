{
  inputs,
  user,
  config,
  pkgs,
  ...
}:
{
  imports = [
    inputs.copyparty.nixosModules.default
  ];

  sops.secrets.copyparty_password.owner = "copyparty";

  services.copyparty = {
    enable = true;
    package = inputs.copyparty.packages.${pkgs.stdenv.hostPlatform.system}.default;

    settings = {
      i = "0.0.0.0";
      p = 3210;
      shr = "/shared";
      shr-adm = user.name;
    };

    accounts = {
      "${user.name}" = {
        passwordFile = config.sops.secrets.copyparty_password.path;
      };
    };

    volumes = {
      "/" = {
        path = "/data/copyparty";
        access = {
          rw = [ user.name ];
        };
      };
      "/public" = {
        path = "/data/copyparty/public";
        access = {
          r = "*";
          rw = [ user.name ];
        };
      };
    };

    openFilesLimit = 8192;
  };
}
