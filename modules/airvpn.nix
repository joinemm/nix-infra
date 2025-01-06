{ config, ... }:
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
}
