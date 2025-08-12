{
  lib,
  pkgs,
  modulesPath,
  config,
  ...
}:
{
  # workaround for missing kernel modules
  # https://github.com/NixOS/nixpkgs/issues/154163
  nixpkgs.overlays = [
    (_: super: { makeModulesClosure = x: super.makeModulesClosure (x // { allowMissing = true; }); })
  ];

  imports = [
    (modulesPath + "/installer/sd-card/sd-image.nix")
  ];

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };

  sdImage = {
    # .img instead of .img.zst
    compressImage = false;

    populateFirmwareCommands =
      let
        configTxt = pkgs.writeText "config.txt" ''
          kernel=u-boot-rpi4.bin
          enable_gic=1
          armstub=armstub8-gic.bin
          disable_overscan=1
          arm_boost=1
          arm_64bit=1
          enable_uart=1
          avoid_warnings=1
        '';
      in
      ''
        (cd ${pkgs.raspberrypifw}/share/raspberrypi/boot && cp bootcode.bin fixup*.dat start*.elf $NIX_BUILD_TOP/firmware/)

        # Add the config
        cp ${configTxt} firmware/config.txt

        # Add pi4 specific files
        cp ${pkgs.ubootRaspberryPi4_64bit}/u-boot.bin firmware/u-boot-rpi4.bin
        cp ${pkgs.raspberrypi-armstubs}/armstub8-gic.bin firmware/armstub8-gic.bin
        cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2711-rpi-4-b.dtb firmware/
        cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2711-rpi-400.dtb firmware/
        cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2711-rpi-cm4.dtb firmware/
        cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2711-rpi-cm4s.dtb firmware/
      '';
    populateRootCommands = ''
      mkdir -p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
    '';
  };
}
