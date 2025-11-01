{ lib, ... }:
let
  modules = lib.listToAttrs (
    map
      (x: {
        name = lib.removeSuffix ".nix" (builtins.baseNameOf x);
        value = x;
      })
      [
        ./home
        ./kanata
        ./x11.nix
        ./keyd.nix
        ./vpn.nix
        ./fonts.nix
        ./nginx.nix
        ./sound.nix
        ./common.nix
        ./gaming.nix
        ./laptop.nix
        ./locale.nix
        ./hetzner.nix
        ./yubikey.nix
        ./headless.nix
        ./bluetooth.nix
        ./secure-boot.nix
        ./syncthing.nix
        ./tailscale.nix
        ./networking.nix
        ./ssh-access.nix
        ./remotebuild.nix
        ./systemd-boot.nix
        ./transmission.nix
        ./node-exporter.nix
        ./virtualization.nix
        ./wayland.nix
        ./dev.nix
        ./gc.nix
        ./zfs.nix
        ./graphical.nix
        ./thunar.nix
        ./hardening.nix
      ]
  );
in
{
  flake = {
    nixosModules = modules;
    profiles = {
      core = with modules; [
        common
        hardening
      ];
      server = with modules; [
        headless
        node-exporter
        ssh-access
        gc
      ];
      workstation = with modules; [
        bluetooth
        fonts
        gaming
        locale
        networking
        remotebuild
        sound
        syncthing
        systemd-boot
        tailscale
        transmission
        vpn
        x11
        yubikey
        dev
        home
        gc
        graphical
        thunar
        virtualization
      ];
    };
  };
}
