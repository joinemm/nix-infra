{
  pkgs,
  config,
  ...
}:
{
  imports = [
    ./mullvad.nix
    ./airvpn.nix
  ];
  sops.secrets = {
    vpn-secrets.owner = "root";
  };

  # OpenConnect needs a NetworkManager secret agent to obtain a fresh login cookie.
  programs.nm-applet.enable = true;

  networking.hosts = {
    "10.151.12.79" = [ "confluence.tii.ae" ];
  };

  networking.networkmanager = {
    plugins = with pkgs; [
      networkmanager-openconnect
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
            service-type = "org.freedesktop.NetworkManager.openconnect";
            gateway = "109.204.204.138:10443";
            protocol = "fortinet";
            cookie-flags = "2";
            gateway-flags = "2";
            gwcert-flags = "2";
          };

          vpn-secrets = {
            "form:_login:username" = "joonas.rautiola@ssrc.fi";
            # Derived from the server certificate matching the old trusted-cert.
            "certificate:109.204.204.138:10443" =
              "sha256:286e145c0ae0965a7183d5f068909a00612ea2db1c4a2aaa427b79995567b7a6";
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
