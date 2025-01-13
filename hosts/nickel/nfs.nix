{ config, lib, ... }:
{
  systemd.tmpfiles.rules = [
    "d /data 0755 root root"
    "d /srv/nfs 0775 nfs users"
  ];

  # Bind mount /data/share into /srv/nfs
  fileSystems."/srv/nfs" = {
    device = "/data/share";
    options = [ "bind" ];
  };

  users.users.nfs = {
    isNormalUser = true;
    uid = 1001;
  };

  services.nfs.server = {
    enable = true;
    exports = ''
      /srv/nfs  192.168.1.0/24(rw,sync,no_subtree_check,root_squash,all_squash,anonuid=1001,anongid=100,fsid=0)
    '';
    statdPort = 4000;
    lockdPort = 4001;
    mountdPort = 4002;
  };

  networking.firewall = rec {
    allowedTCPPorts =
      [
        111 # portmapper
        2049 # nfs
      ]
      ++ lib.attrVals [
        "statdPort"
        "lockdPort"
        "mountdPort"
      ] config.services.nfs.server;

    allowedUDPPorts = allowedTCPPorts;
  };
}
