{ pkgs, ... }:
{
  fonts = {
    fontconfig = {
      enable = true;

      defaultFonts = {
        emoji = [ "Twitter Color Emoji" ];
        monospace = [
          "JetBrains Mono Nerd Font"
          "Sarasa Gothic"
        ];
        sansSerif = [
          "Lato"
          "Sarasa Gothic"
        ];
      };

      subpixel.rgba = "rgb";
    };

    fontDir = {
      enable = true;
      decompressFonts = true;
    };

    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      twitter-color-emoji
      sarasa-gothic
      dejavu_fonts
      lato
      liberation_ttf
    ];
  };
}
