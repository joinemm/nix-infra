{ pkgs, ... }:
{
  # make startx use xsession like any other display manager
  home.file.".xinitrc".source = pkgs.writeShellScript ".xinitrc" ''
    source .xsession
  '';

  xsession = {
    enable = true;
    initExtra = # bash
      ''
        [[ -f ~/.wallpaper ]] && ${pkgs.feh}/bin/feh --bg-fill --no-fehbg ~/.wallpaper
        xset s 900 900
        xset r rate 250 30
        export LS_COLORS="$(${pkgs.vivid}/bin/vivid generate dracula)"

        # programs
        birdtray &
      '';
  };
}
