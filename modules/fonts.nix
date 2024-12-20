{ pkgs, ... }:
{
  fonts = {
    fontconfig = {
      enable = true;

      defaultFonts = {
        emoji = [ "Twitter Color Emoji" ];
        monospace = [
          "Fira Code Nerd Font"
          "Sarasa Gothic"
        ];
        sansSerif = [
          "Cantarell"
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
      nerd-fonts.fira-code
      cantarell-fonts
      twitter-color-emoji
      sarasa-gothic
      corefonts
      dejavu_fonts
    ];
  };
}
