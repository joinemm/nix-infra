# Native ZFS encryption for the HDDs. These are migration mounts; /data still
# uses the original disks until the restore/copy has been verified.
{ lib, ... }:
{
  # The pool import runs before local-fs.target. Early activation makes the
  # secret available without depending on mounts that need this same key.
  sops.secrets.zfs-decryption-key = {
    neededForUsers = true;
    owner = "root";
    group = "root";
    mode = "0400";
  };

  boot.zfs = {
    extraPools = [ "storage" ];
    pools.storage.devNodes = "/dev/disk/by-id";
    # The NixOS import service loads this encryption root's key before any
    # dataset mount. Children inherit its encryption and require no extra key.
    requestEncryptionCredentials = [ "storage/data" ];
  };

  # Legacy ZFS mounts give systemd an individual mount unit per dataset.
  # RequiresMountsFor can then depend on the actual child dataset, too.
  # nofail lets the machine boot for SSH recovery if the pool/key is missing.
  fileSystems = lib.listToAttrs (
    map
      (suffix: {
        name = "/mnt/zfs-new${suffix}";
        value = {
          device = "storage/data${suffix}";
          fsType = "zfs";
          options = [ "nofail" ];
        };
      })
      [
        ""
        "/media"
        "/share"
        "/documents"
        "/photos"
        "/backups"
      ]
  );
}
