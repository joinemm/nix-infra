{
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

    publish = {
      enable = true;
      addresses = true;
      workstation = true;
      userServices = true;
    };
  };

  systemd.tmpfiles.rules = [
    "d /data/share 0775 joonas smbusers - -"
  ];
}
