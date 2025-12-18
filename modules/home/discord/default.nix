{ inputs, ... }:
{
  imports = [ inputs.nixcord.homeModules.nixcord ];

  programs.nixcord = {
    enable = true;

    discord = {
      enable = false;
    };

    vesktop = {
      enable = true;
    };

    config.plugins = {
      betterGifAltText.enable = true;
      fakeNitro = {
        enable = true;
        useEmojiHyperLinks = false;
        useStickerHyperLinks = false;
        transformEmojis = false;
        transformStickers = false;
      };
      favoriteEmojiFirst.enable = true;
      fixSpotifyEmbeds.enable = true;
      fixYoutubeEmbeds.enable = true;
      youtubeAdblock.enable = true;
      forceOwnerCrown.enable = true;
      friendsSince.enable = true;
      memberCount.enable = true;
      webScreenShareFixes.enable = true;
      volumeBooster.enable = true;
      noTypingAnimation.enable = true;
    };

    extraConfig = {
      notifications.useNative = "always";
    };

    config.useQuickCss = true;
    quickCss = # css
      ''
        div[aria-label="Send a gift"] {
          display: none;
        }

        div[aria-label="Apps"] {
          display: none;
        }

        .visual-refresh .channelAppLauncher_e6e74f {
          display: none;
        }

        .buttons__74017 .lottieIcon__5eb9b {
          width: 26px !important;
          height: 26px !important;
        }

        .spriteContainer__04eed {
          --custom-emoji-sprite-size: 26px !important;
        }

        .visual-refresh .panels_c48ade {
          bottom: 20px;
        }
      '';
  };

  # https://github.com/KaylorBen/nixcord/issues/18
  xdg.configFile."vesktop/settings.json".text = builtins.toJSON {
    minimizeToTray = "on";
    discordBranch = "stable";
    arRPC = "on";
    splashColor = "rgb(196, 201, 212)";
    splashBackground = "rgb(22, 24, 29)";
    splashTheming = true;
    checkUpdates = false;
    disableMinSize = true;
    tray = true;
    hardwareAcceleration = true;
    firstLaunch = false;
  };
}
