{ config, pkgs, ... }:
{
  # This recovery environment runs before the encrypted NVMe is unlocked.
  boot.initrd = {
    availableKernelModules = [ "e1000e" ];
    systemd = {
      enable = true;
      network = {
        enable = true;
        networks."10-recovery" = {
          matchConfig.MACAddress = "30:56:0f:5e:ee:9e";
          networkConfig = {
            DHCP = "ipv4";
            IPv6AcceptRA = false;
            LinkLocalAddressing = "no";
          };
          dhcpV4Config.ClientIdentifier = "mac";
          linkConfig.RequiredForOnline = "routable";
        };
      };
    };
    network = {
      enable = true;
      ssh = {
        enable = true;
        port = 2222;
        # A separate key is intentional: initrd host keys live on the ESP.
        hostKeys = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
        authorizedKeys = map (
          key: ''restrict,pty,command="systemctl default" ${key}''
        ) config.users.users.${config.owner}.openssh.authorizedKeys.keys;
      };
    };
  };

  environment.systemPackages = with pkgs; [ cryptsetup ];
}
