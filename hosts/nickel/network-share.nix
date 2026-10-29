{ config, pkgs, ... }: {
  users.groups.smbusers = { };

  users.users = {
    joonas.extraGroups = [ "smbusers" ];

    julia = {
      isNormalUser = true;
      extraGroups = [ "smbusers" ];
    };
  };

  services.samba = {
    enable = true;
    openFirewall = true;

    settings = {
      global = {
        "security" = "user";
      };

      share = {
        path = "/data/share";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";

        "valid users" = "@smbusers";
        "force group" = "smbusers";
        "create mask" = "0664";
        "directory mask" = "0775";
      };

      paperless = {
        # Samba expands %U to the authenticated username, isolating scan inboxes.
        path = "${config.services.paperless.consumptionDir}/%U";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";

        "valid users" = "@smbusers";
        "force user" = "paperless";
        "force group" = "paperless";
        "create mask" = "0600";
        "directory mask" = "0700";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  services.avahi = {
    enable = true;
    openFirewall = true;
    nssmdns4 = true;
    nssmdns6 = false;

    publish = {
      enable = true;
      addresses = true;
      workstation = true;
      userServices = true;
    };

    extraServiceFiles = {
      smb = ''
        <?xml version="1.0" standalone='no'?>
        <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
        <service-group>
          <name replace-wildcards="yes">%h</name>
          <service>
            <type>_smb._tcp</type>
            <port>445</port>
          </service>
        </service-group>
      '';

      ssh = ''
        <?xml version="1.0" standalone='no'?>
        <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
        <service-group>
          <name replace-wildcards="yes">%h SSH</name>
          <service>
            <type>_ssh._tcp</type>
            <port>22</port>
          </service>
          <service>
            <type>_sftp-ssh._tcp</type>
            <port>22</port>
          </service>
        </service-group>
      '';
    };
  };

  systemd.services.samba-smbd.preStart = ''
    ${pkgs.coreutils}/bin/install -d -m 0775 -o joonas -g smbusers /data/share
  '';
  systemd.services.samba-smbd.requires = [ "paperless-storage-setup.service" ];
  systemd.services.samba-smbd.after = [ "paperless-storage-setup.service" ];
  systemd.services.samba-smbd.unitConfig.RequiresMountsFor = [
    config.services.samba.settings.share.path
    config.services.paperless.consumptionDir
  ];
}
