{
  inputs,
  lib,
  self,
  config,
  ...
}:
{
  imports = lib.flatten [
    (with self.profiles; [
      core
      workstation
    ])
    (with self.nixosModules; [
      zfs
      wayland
      secure-boot
    ])
    (with inputs.nixos-hardware.nixosModules; [
      common-cpu-amd
      common-cpu-amd-pstate
      common-pc-ssd
      common-pc
    ])
    inputs.sops-nix.nixosModules.sops
    ./hardware-configuration.nix
    ./9070XT.nix
  ];

  system.stateVersion = "23.11";

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };

  networking = {
    hostName = "cobalt";
    hostId = "c5a9072d";
  };

  fileSystems."/mnt/nas" = {
    device = "192.168.1.4:/";
    fsType = "nfs";
    options = [
      # "x-systemd.automount"
      "noauto"
      "users"
    ];
  };

  # allow launcher.keychron.com to access my M5 mouse
  services.udev.extraRules = ''
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3434", ATTRS{idProduct}=="d028", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
  '';

  services.power-profiles-daemon.enable = true;

  # Sample rates for Topping D10 USB DAC
  services.pipewire.extraConfig = {
    pipewire."99-topping-D10" = {
      "context.properties"."default.clock.allowed-rates" = [
        44100
        48000
        88200
        96000
        176400
        192000
        352800
        384000
      ];
    };
  };

  # don’t shutdown when power button is short-pressed
  services.logind.settings.Login.HandlePowerKey = "ignore";

  services.syncthing.settings.folders = {
    "code".enable = true;
    "documents".enable = true;
    "notes".enable = true;
    "pictures".enable = true;
    "videos".enable = true;
    "work".enable = true;
    "projects".enable = true;
  };

  # extra home-manager configuration
  home-manager.users."${config.owner}" = {
    programs.niri.settings.outputs."DP-1" = {
      mode = {
        width = 3440;
        height = 1440;
        refresh = 144.001;
      };
      scale = 1;
      position = {
        x = 0;
        y = 0;
      };
    };

    programs.foot.settings.main.font = lib.mkForce "monospace:size=11";
    sops.defaultSopsFile = ./secrets.yaml;
  };
}
