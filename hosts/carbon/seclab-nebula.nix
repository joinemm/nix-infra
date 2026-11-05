{ config, pkgs, ... }:
let
  serviceUser = config.systemd.services."nebula@seclab".serviceConfig.User;
in
{
  sops.secrets = {
    seclab_nebula_cert = {
      owner = serviceUser;
      restartUnits = [ "nebula@seclab.service" ];
    };
    seclab_nebula_key = {
      owner = serviceUser;
      restartUnits = [ "nebula@seclab.service" ];
    };
  };

  environment.systemPackages = [ pkgs.nebula ];
  services.nebula.networks.seclab = {
    enable = true;
    cert = config.sops.secrets.seclab_nebula_cert.path;
    key = config.sops.secrets.seclab_nebula_key.path;
    ca = ./seclab-ca.crt;
    lighthouses = [ "10.43.43.1" ];
    staticHostMap."10.43.43.1" = [ "172.164.242.94:4242" ];
    relays = [ "10.43.43.1" ];
    listen.port = 4242;
    settings = {
      punchy = {
        punch = true;
        respond = true;
      };
      pki.disconnect_invalid = true;
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
  };
  networking.firewall.trustedInterfaces = [ "nebula.seclab" ];
}
