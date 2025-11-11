{
  pkgs,
  ...
}:
let
  # pcr 0 breaks if UEFI is updated

  # don't use pcr 4 as it breaks on every rebuild

  # pcr 7 enforces secure boot

  # check pcr 15 (luks volume key) is unset to prevent filesystem confusion attack
  # https://news.ycombinator.com/item?id=42733640

  # usage: sudo tpm-enroll /dev/disk/...
  tpm-enroll = pkgs.writeShellScriptBin "tpm-enroll" ''
    if [ -z "$1" ]; then echo "Please provide the luks disk path" >&2; exit 1; fi
    if [ "$EUID" -ne 0 ]; then echo "Please run as root" >&2; exit 1; fi

    systemd-cryptenroll "$1" \
      --wipe-slot=1 \
      --tpm2-device=auto \
      --tpm2-pcrs=0+2+7+15:sha256=0000000000000000000000000000000000000000000000000000000000000000
  '';
in
{
  environment.systemPackages =
    (with pkgs; [
      tpm2-tss
      tpm2-tools
    ])
    ++ [
      tpm-enroll
    ];

  boot.initrd.systemd.enable = true;
  boot.initrd.availableKernelModules = [ "tpm_tis" ];
}
