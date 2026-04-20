{ lib, ... }:
let
  home = import ./home { inherit lib; };

  nixosModules =
    lib.listToAttrs (
      map
        (x: {
          name = lib.removeSuffix ".nix" (baseNameOf x);
          value = x;
        })
        [
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
    )
    // {
      home-manager = home.nixosModule;
    };
in
{
  flake = {
    inherit (home) homeModules;
    inherit nixosModules;
    profiles = {
      core = with nixosModules; [
        common
        hardening
        users
      ];
      server = with nixosModules; [
        headless
        node-exporter
        ssh-access
        gc
      ];
      workstation = with nixosModules; [
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
        home-manager
        gc
        graphical
        thunar
        virtualization
        niri
      ];
    };
  };
}
