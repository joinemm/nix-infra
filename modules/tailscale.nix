{ lib, ... }:
{
  services.tailscale = {
    enable = true;
    useRoutingFeatures = lib.mkDefault "client";
    disableUpstreamLogging = true;
  };

  # Use key-based OpenSSH over Tailscale without exposing port 22 on
  # physical network interfaces. localhost remains accessible.
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];
}
