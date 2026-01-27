{ lib, config, ... }:
with lib;
let
  cfg = config.services.easyeffects;
  cfgdir = ".local/share/easyeffects";
in
{
  options = {
    services.easyeffects.presets = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            device = mkOption { type = types.str; };
            type = mkOption {
              type = types.enum [
                "input"
                "output"
              ];
            };
            profile = mkOption { type = types.str; };
            file = mkOption { type = types.path; };
            description = mkOption {
              type = types.str;
              default = "Created by Home Manager";
            };
          };
        }
      );
    };
  };
  config = {
    home.file = lib.mergeAttrsList (
      map (
        {
          device,
          type,
          profile,
          file,
          description,
        }:
        let
          name = builtins.head (lib.splitString "." (builtins.baseNameOf file));
        in
        {
          "${cfgdir}/${type}/${name}.json".source = file;
          "${cfgdir}/autoload/${type}/${device}.json".text = builtins.toJSON {
            inherit device;
            device-description = description;
            device-profile = profile;
            preset-name = name;
          };
        }
      ) cfg.presets
    );
  };
}
