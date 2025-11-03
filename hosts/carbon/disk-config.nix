{
  fileSystems."/persistent".neededForBoot = true;

  disko.devices.disk.internal = {
    type = "disk";
    device = "/dev/nvme0n1";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          # big esp has enough space for many generations of kernels
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [
              "defaults"
              "noexec"
              "nosuid"
              "nodev"
              # https://github.com/NixOS/nixpkgs/issues/279362#issuecomment-1913506090
              "umask=0077"
            ];
          };
        };
        luks = {
          size = "100%";
          content = {
            type = "luks";
            name = "crypt";
            extraOpenArgs = [
              "--allow-discards"
              # improves SSD performance
              "--perf-no_read_workqueue"
              "--perf-no_write_workqueue"
            ];
            settings.crypttabExtraOpts = [
              "tpm2-device=auto"
              "tpm2-measure-pcr=yes"
            ];
            content = {
              type = "btrfs";
              extraArgs = [
                "-L"
                "nixos"
                "-f"
                # faster hashing algorithm
                "--csum xxhash"
              ];
              subvolumes =
                let
                  mountOptions = [
                    # lzo is faster than zstd albeit doesn't compress as efficiently
                    "compress=lzo"
                    "noatime"
                    "autodefrag"
                    "discard=async"
                  ];
                in
                {
                  "/root" = {
                    mountpoint = "/";
                    inherit mountOptions;
                  };
                  "/home" = {
                    mountpoint = "/home";
                    inherit mountOptions;
                  };
                  "/persistent" = {
                    mountpoint = "/persistent";
                    inherit mountOptions;
                  };
                  "/nix" = {
                    mountpoint = "/nix";
                    inherit mountOptions;
                  };
                  # this will store the clean root snapshot
                  "/womb" = {
                    mountOptions = [
                      "noatime"
                      "nodatacow"
                    ];
                  };
                  "/swap" = {
                    mountpoint = "/swap";
                    mountOptions = [
                      "noatime"
                      "nodatacow"
                      "compress=no"
                    ];
                    swap.swapfile.size = "32G";
                  };
                };
            };
          };
        };
      };
    };
  };
}
