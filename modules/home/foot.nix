{
  pkgs,
  lib,
  config,
  ...
}:
{
  options = {
    programs.foot.fontSize = lib.mkOption {
      type = lib.types.int;
      default = 11;
    };
  };
  config = {
    programs.foot = {
      enable = true;
      server.enable = true;
    };

    # don't kill all of my terminals with nixos-rebuild
    systemd.user.services.foot.Unit.X-RestartIfChanged = "false";

    # use background and foreground from noctalia but override ANSI colors with dracula
    # because the noctalia themes don't have recognizable color difference
    xdg.configFile."foot/foot.ini".text = ''
      include=~/.config/foot/themes/noctalia
      include=~/.config/foot/themes/dracula

      [main]
      term=xterm-256color
      font=monospace:size=${toString config.programs.foot.fontSize}
      pad=12x8

      [colors-dark]
      alpha=0.85

      [scrollback]
      lines=10000
      multiplier=6

      [mouse]
      alternate-scroll-mode=false

      [key-bindings]
      show-urls-launch=Alt_L
    '';

    xdg.configFile."foot/themes/dracula".text = ''
      [colors-dark]
      regular0=000000 
      regular1=ff5555 
      regular2=50fa7b 
      regular3=f1fa8c 
      regular4=bd93f9 
      regular5=ff79c6 
      regular6=8be9fd 
      regular7=bfbfbf 

      bright0=4d4d4d 
      bright1=ff6e67 
      bright2=5af78e 
      bright3=f4f99d 
      bright4=caa9fa 
      bright5=ff92d0 
      bright6=9aedfe 
      bright7=e6e6e6 
    '';

    home.sessionVariables = {
      TERMINAL = "footclient";
      TERM = "foot";
      LS_COLORS = "$(${pkgs.vivid}/bin/vivid generate dracula)";
    };
  };
}
