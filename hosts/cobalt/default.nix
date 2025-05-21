{
  inputs,
  lib,
  user,
  self,
  ...
}:
{
  imports = lib.flatten [
    (with self.profiles; [
      core
      workstation
    ])
    (with self.nixosModules; [
      desktop
      zfs
      airvpn
    ])
    (with inputs.nixos-hardware.nixosModules; [
      common-cpu-amd
      common-cpu-amd-pstate
      common-pc-ssd
      common-pc
    ])
    inputs.sops-nix.nixosModules.sops
    ./hardware-configuration.nix
    ./5700XT.nix
    ./monitor.nix
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
      "x-systemd.automount"
      "noauto"
      "users"
    ];
  };

  services.power-profiles-daemon.enable = true;
  services.auto-epp = {
    enable = true;
    settings.Settings = {
      epp_state_for_AC = "performance";
      epp_state_for_BAT = "power";
    };
  };

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
  home-manager.users."${user.name}" = { };
}
