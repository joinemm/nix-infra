# Import this module during the NVMe migration, after backing up its contents.
# The current disk-config.nix remains active until then. A rebuild does not
# convert an existing ext4 root into LUKS: the NVMe must be recreated/restored.
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
  boot.initrd.systemd.tpm2.enable = true;

  # Keep the existing NVMe identity from disk-config.nix, but replace its
  # partition layout. An unencrypted ESP holds the signed boot image.
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
