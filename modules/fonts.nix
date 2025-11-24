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
      nerd-fonts.jetbrains-mono
      cantarell-fonts
      twitter-color-emoji
      sarasa-gothic
      corefonts
      dejavu_fonts
    ];
  };
}
