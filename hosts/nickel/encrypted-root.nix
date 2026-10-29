# Encrypted NVMe root for the reinstall. Bulk files live on the HDD ZFS pool;
# /var/lib and /var/cache remain on this fast local filesystem.
{
  self,
  lib,
  ...
}:
{
  imports = with self.nixosModules; [
    secure-boot
    tpm2
  ];

  # nickel's firmware exposes its TPM through CRB.
  boot.initrd.availableKernelModules = [ "tpm_crb" ];

  # The NVMe identity comes from disk-config.nix. The unencrypted ESP holds
  # the signed boot image; the rest of the device is LUKS-encrypted ext4.
  disko.devices.disk.root.content.partitions = lib.mkForce {
    ESP = {
      type = "EF00";
      size = "1G";
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
        type = "luks";
        name = "cryptroot";
        # Choose and save this independent password during installation.
        # TPM enrollment is a separate step after verifying Secure Boot.
        askPassword = true;
        extraFormatArgs = [
          "--type"
          "luks2"
        ];
        settings = {
          allowDiscards = true;
          crypttabExtraOpts = [
            "tpm2-device=auto"
            "tpm2-measure-pcr=yes"
          ];
        };
        content = {
          type = "filesystem";
          format = "ext4";
          mountpoint = "/";
        };
      };
    };
  };
}
