{
  config,
  lib,
  ...
}:
lib.mkMerge [
  {
    i18n = {
      defaultLocale = "fi_FI.UTF-8";
      extraLocaleSettings = {
        LC_MESSAGES = "en_US.UTF-8";
      };
      supportedLocales = [
        "en_US.UTF-8/UTF-8"
        "fi_FI.UTF-8/UTF-8"
        "ja_JP.UTF-8/UTF-8" # required by some japanese games
      ];
    };

    # mkDefault makes it overrideable by automatic-timezoned
    time.timeZone = lib.mkDefault "Europe/Helsinki";

    services.automatic-timezoned.enable = !config.services.geoclue2.enableStatic;

    services.geoclue2 = {
      enable = lib.mkDefault true;
      # Stationary machines share the home location; mobile hosts opt out.
      enableStatic = lib.mkDefault true;
    };

    # GeoClue 2.8 requires an explicit IP backend; nixpkgs omits this section.
    # can be removed once https://github.com/NixOS/nixpkgs/pull/548689 is merged
    environment.etc = lib.mkIf config.services.geoclue2.enable {
      "geoclue/geoclue.conf".text = lib.mkAfter ''

        [ip]
        enable=${lib.boolToString (!config.services.geoclue2.enableStatic)}
        method=ichnaea
      '';
    };
  }
  (lib.mkIf (config.services.geoclue2.enable && config.services.geoclue2.enableStatic) {
    # https://www.mankier.com/5/geoclue#Static_Location_File
    sops.secrets.geolocation = {
      sopsFile = ../secrets/geolocation.yaml;
      owner = "geoclue";
      group = "geoclue";
      mode = "0600";
      restartUnits = [ "geoclue.service" ];
    };

    # Replace nixpkgs' generated file so coordinates never enter the Nix store.
    environment.etc.geolocation = lib.mkForce {
      source = config.sops.secrets.geolocation.path;
    };
  })
]
