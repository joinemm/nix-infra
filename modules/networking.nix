{
  pkgs,
  user,
  config,
  ...
}:
{
  sops.secrets.wifi-env.group = "networkmanager";

  networking = {
    networkmanager = {
      enable = true;
      wifi = {
        backend = "wpa_supplicant";
        powersave = true;
      };

      ensureProfiles = {
        environmentFiles = [
          config.sops.secrets.wifi-env.path
        ];
        profiles = {
          Waifu = {
            connection = {
              id = "Waifu";
              type = "wifi";
            };
            ipv4 = {
              method = "auto";
            };
            ipv6 = {
              addr-gen-mode = "default";
              method = "auto";
            };
            proxy = { };
            wifi = {
              mode = "infrastructure";
              ssid = "Waifu";
            };
            wifi-security = {
              auth-alg = "open";
              key-mgmt = "wpa-psk";
              psk = "$WIFI_PASSWORD_WAIFU";
            };
          };
        };
      };
    };

    firewall.enable = true;
  };

  services.resolved = {
    enable = true;
    # extraConfig = ''
    #   Cache=no
    # '';
  };

  systemd.services.NetworkManager-wait-online.enable = false;
  systemd.services.NetworkManager-dispatcher.enable = false;

  users.users."${user.name}".extraGroups = [ "networkmanager" ];

  environment.systemPackages = with pkgs; [ wirelesstools ];
}
