{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.niri.nixosModules.niri
  ];

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = false;
    config.niri = {
      default = [
        "gnome"
        "gtk"
      ];
      "org.freedesktop.impl.portal.Access" = "gtk";
      "org.freedesktop.impl.portal.Notification" = "gtk";
      "org.freedesktop.impl.portal.Secret" = "gnome-keyring";
    };
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  programs.niri = {
    enable = true;
    package = pkgs.niri.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ./niri-session-import-environment.patch ];
    });
  };

  # just undoing weird things that niri flake enables by default
  systemd.user.services.niri-flake-polkit.enable = false;
  niri-flake.cache.enable = false;
  fonts.enableDefaultPackages = false;

  environment.systemPackages = with pkgs; [
    xwayland-satellite # XWayland compatibility for apps/games
  ];
}
