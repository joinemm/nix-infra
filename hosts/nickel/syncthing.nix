{
  self,
  config,
  ...
}:
{
  imports = [ self.nixosModules.syncthing ];

  sops.secrets = {
    syncthing_password = {
      owner = config.services.syncthing.user;
      restartUnits = [ "syncthing-init.service" ];
    };
    syncthing_cert.owner = "root";
    syncthing_key.owner = "root";
  };

  services.syncthing = {
    # Keep both the synced files and the database on the NVMe root filesystem.
    dataDir = "/var/lib/syncthing";
    settings.gui.insecureSkipHostcheck = true;

    guiPasswordFile = config.sops.secrets.syncthing_password.path;
    key = config.sops.secrets.syncthing_key.path;
    cert = config.sops.secrets.syncthing_cert.path;

    settings.folders = {
      "code".enable = true;
      "documents".enable = true;
      "notes".enable = true;
      "pictures".enable = true;
      "videos".enable = true;
      "work".enable = true;
      "projects".enable = true;
    };
  };

  systemd.tmpfiles.rules = [ "d /var/lib/syncthing 0755 ${config.owner} users" ];

  services.nginx.virtualHosts."sync.lab.joinemm.dev" = {
    serverAliases = [ "syncthing.lab.joinemm.dev" ];
    useACMEHost = "lab.joinemm.dev";
    forceSSL = true;
    locations."/".proxyPass = "http://${config.services.syncthing.guiAddress}";
  };
}
