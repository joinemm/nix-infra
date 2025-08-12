{
  lib,
  self,
  inputs,
  pkgs,
  user,
  ...
}:
{
  imports = lib.flatten [
    (with self.profiles; [
      core
      server
    ])
    (with self.nixosModules; [
      locale
    ])
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
    inputs.nix-topology.nixosModules.default
    ./sdcard.nix
    ./rpi-exporter.nix
    ./blocky.nix
    ./monitoring.nix
  ];

  nixpkgs.hostPlatform = "aarch64-linux";
  networking.hostName = "zinc";
  system.stateVersion = "24.05";

  # it's headless so we can't see the console anyway
  console.enable = false;

  hardware = {
    raspberry-pi."4" = {
      apply-overlays-dtmerge.enable = true;
    };
    deviceTree = {
      enable = true;
      filter = "*rpi-4-*.dtb";
    };
  };

  # postgresql is running on unix socket at /run/postgresql
  # only local connections are allowed
  # TCP connections are refused
  services.postgresql = {
    enable = true;
    authentication = lib.mkForce ''
      local all all trust
    '';
    # https://github.com/shizunge/blocky-postgresql/blob/main/init-scripts/blocky-pg-init.sh
    # https://gist.github.com/zaenk/2e9c1936663caae71b212f056b5dfb5f
    initialScript = pkgs.writeText "postgres-init" ''
      CREATE DATABASE blocky;
      CREATE USER blocky WITH PASSWORD 'blocky';
      GRANT ALL PRIVILEGES ON DATABASE blocky TO blocky;
      GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO blocky;
      GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO blocky;

      \c blocky postgres
      GRANT ALL ON SCHEMA public TO blocky;

      CREATE USER grafana WITH PASSWORD 'grafana';
      GRANT CONNECT ON DATABASE blocky TO grafana;
      GRANT USAGE ON SCHEMA public TO grafana;

      \c blocky blocky
      ALTER DEFAULT PRIVILEGES FOR USER blocky IN SCHEMA public GRANT SELECT ON TABLES TO grafana;
    '';
  };

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
  };

  # Allow access to GPIO pins for gpio group
  services.udev.packages = [
    (pkgs.writeTextFile {
      name = "gpio-udev-rules";
      destination = "/etc/udev/rules.d/99-gpio.rules";
      text = ''
        SUBSYSTEM=="bcm2835-gpiomem", KERNEL=="gpiomem", GROUP="gpio",MODE="0660"
        SUBSYSTEM=="gpio", KERNEL=="gpiochip*", ACTION=="add", RUN+="${pkgs.bash}/bin/bash -c 'chown root:gpio /sys/class/gpio/export /sys/class/gpio/unexport ; chmod 220 /sys/class/gpio/export /sys/class/gpio/unexport'"
        SUBSYSTEM=="gpio", KERNEL=="gpio*", ACTION=="add",RUN+="${pkgs.bash}/bin/bash -c 'chown root:gpio /sys%p/active_low /sys%p/direction /sys%p/edge /sys%p/value ; chmod 660 /sys%p/active_low /sys%p/direction /sys%p/edge /sys%p/value'"
      '';
    })
  ];

  users.groups.gpio = { };
  users.users.${user.name}.extraGroups = [
    "gpio"
    "vcio"
  ];

  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
  ];
}
