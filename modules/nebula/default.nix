{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.nebula;
  networkName = "milkyway";
  lighthouseAddress = "10.6.9.1";
  serviceUser = config.systemd.services."nebula@${networkName}".serviceConfig.User or "root";
in
{
  options.nebula = {
    enable = lib.mkEnableOption "Enable Nebula network";
    isLighthouse = lib.mkEnableOption "Is this node a lighthouse?";

    cert = lib.mkOption {
      type = lib.types.path;
      default = "";
      description = "Path to the certificate file";
    };

    key = lib.mkOption {
      type = lib.types.path;
      default = "";
      description = "Path to the key file";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = serviceUser;
      readOnly = true;
      description = "Used to access the user that the nebula service is run as, don't change";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      nebula
      dig
    ];

    services.nebula.networks."${networkName}" = lib.mkMerge [
      {
        enable = true;
        enableReload = true;
        inherit (cfg) cert key isLighthouse;
        ca = ./ca.crt;

        settings.punchy = {
          punch = true;
          respond = true;
        };

        firewall = {
          outbound = [
            {
              port = "any";
              proto = "any";
              host = "any";
            }
          ];
          inbound = [
            {
              port = "any";
              proto = "icmp";
              host = "any";
            }
          ];
        };
      }
      (
        if cfg.isLighthouse then
          { }
        else
          {
            lighthouses = [ lighthouseAddress ];
            staticHostMap = {
              "${lighthouseAddress}" = [ "65.21.249.145:4242" ];
            };
          }
      )
    ];

    # don't stack nixos firewall on top of the nebula firewall
    networking.firewall.trustedInterfaces = [ "nebula.${networkName}" ];
  };
}
