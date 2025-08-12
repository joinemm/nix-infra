{
  disko.devices.disk = {
    os = {
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            type = "EF02";
            size = "1M";
          };
          ESP = {
            type = "EF00";
            size = "512M";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
