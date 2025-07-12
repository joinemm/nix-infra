{
  pkgs,
  config,
  lib,
  ...
}:
lib.mkMerge [
  {
    services = {
      xserver = {
        enable = true;

        # keyboard settings
        xkb.layout = "eu";

        # I don't need xterm
        excludePackages = with pkgs; [
          xorg.iceauth
          xterm
        ];

        # use startx as a display manager
        displayManager.startx.enable = true;
      };
    };
  }
  (lib.mkIf config.services.xserver.enable {
    # use X11 keyboard settings in tty
    console.useXkbConfig = true;

    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = false;
      extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
      config.common.default = "*";
    };

    environment.systemPackages = with pkgs; [
      xdotool
      xclip
    ];
  })
]
