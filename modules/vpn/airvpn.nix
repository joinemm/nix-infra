{ }:
let
  airvpnProfile =
    { id, remote }:
    {
      connection = {
        inherit id;
        type = "vpn";
        autoconnect = false;
      };

      vpn = {
        service-type = "org.freedesktop.NetworkManager.openvpn";
        connection-type = "tls";
        inherit remote;
        dev = "tun";
        ca = "${./airvpn-ca.pem}";
        cert = "${./airvpn-client.pem}";
        key = config.sops.secrets.airvpn-client-key.path;
        tls-crypt = config.sops.secrets.airvpn-tls-crypt.path;
        auth = "SHA512";
        remote-cert-tls = "server";
        push-peer-info = "yes";
        comp-lzo = "no-by-default";
        data-ciphers = "AES-256-GCM:AES-256-CBC:AES-192-GCM:AES-192-CBC:AES-128-GCM:AES-128-CBC";
        data-ciphers-fallback = "AES-256-CBC";
      };

      ipv4.method = "auto";
      ipv6.method = "disabled";
    };
in
{
  sops.secrets = {
    airvpn-client-key.owner = "root";
    airvpn-tls-crypt.owner = "root";
  };

  networking.networkmanager.ensureProfiles.profiles = {
    AirVPNEurope = airvpnProfile {
      id = "AirVPN Europe";
      remote = "europe3.vpn.airdns.org:443";
    };

    AirVPNAmerica = airvpnProfile {
      id = "AirVPN America";
      remote = "us3.vpn.airdns.org:443";
    };
  };
}
