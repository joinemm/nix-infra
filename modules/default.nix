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
          ./vpn
          ./fonts.nix
          ./nginx.nix
          ./sound.nix
          ./common.nix
          ./accounts.nix
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
          ./node-exporter.nix
          ./virtualization.nix
          ./wayland.nix
          ./dev.nix
          ./gc.nix
          ./zfs.nix
          ./graphical.nix
          ./nautilus.nix
          ./hardening.nix
          ./tpm.nix
          ./nebula
          ./niri.nix
          ./users.nix
          ./cache.nix
          ./fwupd.nix
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
        cache
      ];
      server = with nixosModules; [
        headless
        ssh-access
        gc
      ];
      workstation = with nixosModules; [
        fwupd
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
        nautilus
        virtualization
        niri
        accounts
      ];
    };
  };
}
