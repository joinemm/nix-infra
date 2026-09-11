{
  pkgs,
  config,
  ...
}:
{
  sops.secrets = {
    vpn-secrets.owner = "root";
  };

  networking.hosts = {
    "10.151.12.79" = [ "confluence.tii.ae" ];
  };

  networking.networkmanager = {
    plugins = with pkgs; [
      networkmanager-openconnect
      networkmanager-fortisslvpn
      networkmanager-openvpn
    ];
    ensureProfiles = {
      environmentFiles = [
        config.sops.secrets.vpn-secrets.path
      ];

      profiles = {
        OfficeVPN = {
          connection = {
            id = "Office";
            type = "vpn";
            autoconnect = false;
          };

          vpn = {
            service-type = "org.freedesktop.NetworkManager.fortisslvpn";
            gateway = "109.204.204.138:10443";
            user = "joonas.rautiola@ssrc.fi";
            trusted-cert = "aac5a1e0e81f2e8438a6dba8f705807d47d76ad747e084ae7b3959460f6ed08f";
          };

          vpn-secrets = {
            password = "$OFFICE_VPN_PASSWORD";
          };

          ipv4 = {
            method = "auto";
            never-default = true;
            ignore-auto-dns = true;
            dns = "172.18.16.137";
          };

          ipv6.method = "disabled";
        };

        TIIVPN = {
          connection = {
            id = "TII";
            type = "vpn";
            autoconnect = false;
          };

          vpn = {
            service-type = "org.freedesktop.NetworkManager.openconnect";
            gateway = "access.tii.ae";
            protocol = "gp";
            user = "joonas.rautiola";
          };

          vpn-secrets = {
            password = "$TII_VPN_PASSWORD";
          };

          ipv4 = {
            method = "auto";
            never-default = true;
          };

          ipv6.method = "disabled";
        };
      };
    };
  };
}
