{
  services.mullvad-vpn = {
    enable = true;
    gui.enable = true;
  };

  # requires nixos firewall to use nftables
  networking.nftables.tables.excludeTraffic = {
    family = "inet";
    content = ''
      chain excludeOutgoing {
        type route hook output priority 0; policy accept;
        ip daddr 100.64.0.0/10 ct mark set 0x00000f41 meta mark set 0x6d6f6c65;
      }
    '';
  };
}
