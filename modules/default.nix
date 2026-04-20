{ lib, ... }:
let
  modules = lib.listToAttrs (
    map
      (x: {
        name = lib.removeSuffix ".nix" (baseNameOf x);
        value = x;
      })
      [
        ./home
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
        ./hibernate.nix
        ./bluetooth.nix
        ./secure-boot.nix
        ./syncthing.nix
        ./tailscale.nix
        ./networking.nix
        ./ssh-access.nix
        ./remotebuild.nix
        ./systemd-boot.nix
        ./node-exporter.nix
        ./virtualization.nix
        ./wayland.nix
        ./dev.nix
        ./gc.nix
        ./zfs.nix
        ./graphical.nix
        ./thunar.nix
        ./hardening.nix
        ./tpm.nix
        ./nebula
        ./niri.nix
        ./users.nix
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
        users
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
        vpn
        yubikey
        dev
        home
        gc
        graphical
        thunar
        virtualization
        niri
      ];
    };
  };
}
