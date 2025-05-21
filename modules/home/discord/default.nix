{
  pkgs,
  inputs,
  ...
}:
let
  oldPkgs = import inputs.nixpkgs-old { inherit (pkgs) system; };
in
{
  imports = [ inputs.nixcord.homeModules.nixcord ];

  programs.nixcord = {
    enable = true;

    discord = {
      enable = false;
      package = pkgs.discord;
    };

    vesktop = {
      enable = true;

      # Use vencord fork with customizable tray icon
      # https://github.com/Vencord/Vesktop/pull/517
      package = oldPkgs.vesktop.overrideAttrs (prev: {
        src = pkgs.fetchFromGitHub {
          owner = "PolisanTheEasyNick";
          repo = "Vesktop";
          rev = "d15387257ce0c88ec848c8415f44b460d5590f9a";
          hash = "sha256-JowtPaz2kLjfv8ETgrrjiwn44T2WVPucrR1OoXV/cME=";
        };

        pnpmDeps = prev.pnpmDeps.overrideAttrs (_: {
          outputHash = "sha256-CHAA3RldLe1jte/701ckNELeiA4O1y2X3uMOhhuv7cc=";
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
