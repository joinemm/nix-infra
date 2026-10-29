# Import the existing encrypted HDD pool; reinstalling the NVMe must not
# recreate it. Dataset properties are persistent and set during provisioning.
{ config, lib, ... }:
let
  datasetSuffixes = [
    ""
    "/media"
    "/share"
    "/documents"
    "/photos"
    "/backups"
  ];
  tmpfiles = "${config.systemd.package}/bin/systemd-tmpfiles";
in
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
    map (suffix: {
      name = "/data${suffix}";
      value = {
        device = "storage/data${suffix}";
        fsType = "zfs";
        options = [ "nofail" ];
      };
    }) datasetSuffixes
  );

  # Nixarr and Paperless also contribute /data rules upstream. Run all of
  # those rules after the real datasets mount, rather than during global
  # tmpfiles setup (nofail mounts need not finish before local-fs.target).
  systemd.services =
    lib.genAttrs
      [
        "jellyfin"
        "qbittorrent"
        "radarr"
        "sonarr"
        "bazarr"
        "audiobookshelf"
        "samba-smbd"
        "paperless-storage-setup"
        "paperless-exporter"
        "immich-storage-setup"
      ]
      (_: {
        requires = [ "data-tmpfiles-setup.service" ];
        after = [ "data-tmpfiles-setup.service" ];
      })
    // {
      systemd-tmpfiles-setup = {
        overrideStrategy = "asDropin";
        serviceConfig.ExecStart = [
          ""
          "${tmpfiles} --create --remove --boot --exclude-prefix=/dev --exclude-prefix=/data"
        ];
      };
      systemd-tmpfiles-resetup.serviceConfig.ExecStart = lib.mkForce (
        "${tmpfiles} --create --remove --exclude-prefix=/dev --exclude-prefix=/data"
      );
      data-tmpfiles-setup = {
        description = "Create application directories on mounted ZFS datasets";
        wantedBy = [ "multi-user.target" ];
        after = [ "systemd-tmpfiles-setup.service" ];
        unitConfig.RequiresMountsFor = map (suffix: "/data${suffix}") datasetSuffixes;
        restartTriggers = [ config.environment.etc."tmpfiles.d".source ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${tmpfiles} --create --prefix=/data";
        };
      };
    };
}
