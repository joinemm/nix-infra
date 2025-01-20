{ pkgs, user, ... }:
{
  services.openvpn.servers = {
    ficolo = {
      autoStart = false;
      config = "config ${user.home}/work/tii/credentials/ficolo-vpn.ovpn";
    };
  };

  networking.openconnect.interfaces = {
    tii = {
      autoStart = false;
      gateway = "access.tii.ae";
      protocol = "gp";
      user = "joonas.rautiola";
      passwordFile = "${user.home}/work/tii/credentials/tiivpn-password";
    };
  };

  systemd.services.openfortivpn-office = {
    description = "Office VPN";
    after = [ "network.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.openfortivpn}/bin/openfortivpn --config ${user.home}/work/tii/credentials/office-vpn.config";
      Restart = "always";
      Type = "notify";
    };
  };

  nix.settings = {
    extra-substituters = [
      "https://prod-cache.vedenemo.dev?priority=43"
      "https://ghaf-dev.cachix.org?priority=44"
    ];
    extra-trusted-public-keys = [
      "prod-cache.vedenemo.dev~1:JcytRNMJJdYJVQCYwLNsrfVhct5dhCK2D3fa6O1WHOI="
      "ghaf-dev.cachix.org-1:S3M8x3no8LFQPBfHw1jl6nmP8A7cVWKntoMKN3IsEQY="
    ];
  };

  networking.hosts = {
    "10.151.12.79" = [ "confluence.tii.ae" ];
    "10.151.12.77" = [ "jira.tii.ae" ];
  };
}
