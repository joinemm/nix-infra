{
  pkgs,
  inputs,
  ...
}:
{
  imports = [ inputs.nixcord.homeManagerModules.nixcord ];

  programs.nixcord = {
    enable = true;
    discord.enable = false;

    vesktop = {
      enable = true;

      # Use vencord fork with customizable tray icon
      # https://github.com/Vencord/Vesktop/pull/517
      package = pkgs.vesktop.overrideAttrs (prev: {
        src = pkgs.fetchFromGitHub {
          owner = "PolisanTheEasyNick";
          repo = "Vesktop";
          rev = "b727a1cf8c2086cf4987455aa9c631dbceb8fb78";
          hash = "sha256-LLJQwRM/tUAtu0v1Zo2MGNtAPEXapb40iPIooVX++Pc=";
        };

        pnpmDeps = prev.pnpmDeps.overrideAttrs (_: {
          outputHash = "sha256-qVQbuXwZa1Lq8bHx5C3SmOV3EUbsQ3j9GrUWDwJafcE=";
        });

        patches = prev.patches ++ [ ./readonly-fix.patch ];

        # Patch the desktop file to use discord icon
        desktopItems = [
          (pkgs.makeDesktopItem {
            name = "discord";
            desktopName = "Discord";
            exec = "vesktop %U";
            icon = "discord";
            startupWMClass = "Discord";
            genericName = "Internet Messenger";
            keywords = [
              "discord"
              "vencord"
              "vesktop"
            ];
          })
        ];
      });
    };

    config.plugins = {
      betterGifAltText.enable = true;
      fakeNitro.enable = true;
      fakeNitro.useHyperLinks = false;
      favoriteEmojiFirst.enable = true;
      fixSpotifyEmbeds.enable = true;
      fixYoutubeEmbeds.enable = true;
      youtubeAdblock.enable = true;
      forceOwnerCrown.enable = true;
      friendsSince.enable = true;
      memberCount.enable = true;
      webScreenShareFixes.enable = true;
      volumeBooster.enable = true;
    };

    extraConfig = {
      notifications.useNative = "always";
    };

    config.useQuickCss = true;
    quickCss = # css
      ''
        button[aria-label="Send a gift"] {
          display: none;
        }

        button[aria-label="Add Emoji Confetti"] {
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

  # Replace vencord tray icon with the default discord icon
  xdg.configFile."vesktop/TrayIcons/icon_custom.png".source = ./tray-icon.png;

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
    trayMainOverride = true;
    trayColorType = "custom";
    trayAutoFill = "auto";
    trayColor = "c02828";
    firstLaunch = false;
  };
}
