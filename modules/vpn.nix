{
  pkgs,
  config,
  ...
}:
{
  sops.secrets = {
    airvpn_private_key.owner = "root";
    airvpn_preshared_key.owner = "root";
  };

  networking.wg-quick.interfaces."airvpn" = {
    autostart = false;
    address = [
      "10.138.209.189/32"
      "fd7d:76ee:e68f:a993:36:bd75:6ac8:7c65/128"
    ];
    privateKeyFile = config.sops.secrets.airvpn_private_key.path;
    dns = [
      "10.128.0.1"
      "fd7d:76ee:e68f:a993::1"
    ];

    peers = [
      {
        publicKey = "PyLCXAQT8KkM4T+dUsOQfn+Ub3pGxfGlxkIApuig+hk=";
        presharedKeyFile = config.sops.secrets.airvpn_preshared_key.path;
        endpoint = "europe3.vpn.airdns.org:1637";
        allowedIPs = [
          "0.0.0.0/0"
          "::/0"
        ];
      }
    ];
  };

  # work vpns

  services.openvpn.servers = {
    ficolo = {
      autoStart = false;
      config = "config ${config.users.default.home}/work/tii/credentials/ficolo-vpn.ovpn";
    };
  };

  networking.openconnect.interfaces = {
    tii = {
      autoStart = false;
      gateway = "access.tii.ae";
      protocol = "gp";
      user = "joonas.rautiola";
      passwordFile = "${config.users.default.home}/work/tii/credentials/tiivpn-password";
    };
  };

  systemd.services.openfortivpn-office = {
    description = "Office VPN";
    after = [ "network.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.openfortivpn}/bin/openfortivpn --config ${config.users.default.home}/work/tii/credentials/office-vpn.config";
      Restart = "always";
      Type = "notify";
    };
  };

  # TII nameserver is not reliable
  # networking.hosts = {
  #   "10.151.12.79" = [ "confluence.tii.ae" ];
  #   "10.151.12.77" = [ "jira.tii.ae" ];
  # };

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "vpn" ''
      case $1 in
      "tii") systemctl "$2" openconnect-tii.service ;;
      "office") systemctl "$2" openfortivpn-office.service ;;
      "ficolo") systemctl "$2" openvpn-ficolo.service ;;
      "air") systemctl "$2" wg-quick-airvpn.service ;;
      *) echo "Invalid VPN: $1\nVPNs: tii, office, ficolo, air" && exit 1 ;;
      esac
    '')
  ];
}
