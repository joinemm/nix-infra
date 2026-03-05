{ inputs, pkgs, ... }:
{
  imports = [
    inputs.niri.nixosModules.niri
  ];

  programs.niri.enable = true;

  environment.systemPackages = with pkgs; [
    xwayland-satellite # xwayland support
  ];
}
