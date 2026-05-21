{
  disko.devices.disk.kingston = {
    type = "disk";
    device = "/dev/disk/by-id/nvme-KINGSTON_SNVS2000G_50026B738174DF2C";
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
                "--csum"
                "xxhash"
              ];
              subvolumes =
                let
                  mountOptions = [
                    "compress=zstd:1"
                    "noatime"
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
                  "/nix" = {
                    mountpoint = "/nix";
                    inherit mountOptions;
                  };
                  "/swap" = {
                    mountpoint = "/swap";
                    mountOptions = [
                      "noatime"
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
