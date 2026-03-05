{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.zen-browser.homeModules.default
  ];

  programs.zen-browser = {
    enable = true;
    suppressXdgMigrationWarning = true;
    policies = {
      AutofillAddressEnabled = true;
      AutofillCreditCardEnabled = false;
      DisableAppUpdate = true;
      DisableFeedbackCommands = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableTelemetry = true;
      DontCheckDefaultBrowser = true;
      NoDefaultBookmarks = true;
      OfferToSaveLogins = false;
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };
    };
    profiles.default = {
      settings = {
        "app.normandy.first_run" = false;
        "datareporting.usage.uploadEnabled" = false;
        "font.minimum-size.x-western" = 14;
        "font.size.monospace.x-western" = 14;
        "media.hardwaremediakeys.enabled" = false;
        "privacy.donottrackheader.enabled" = true;
        "signon.rememberSignons" = false;
        "extensions.autoDisableScopes" = 0;
        "sidebar.new-sidebar.has-used" = true;
        "sidebar.verticalTabs" = true;
        "sidebar.verticalTabs.dragToPinPromo.dismissed" = true;

        "browser.tabs.warnOnClose" = true;
        "browser.startup.page" = 1; # don't open previous tabs
        "browser.translations.neverTranslateLanguages" = "fi";
        "browser.toolbars.bookmarks.visibility" = "never";
        "browser.aboutConfig.showWarning" = false;
        "browser.urlbar.trimURLs" = false;
        "browser.startup.couldRestoreSession.count" = -1;
      };
      containers = {
        Unikie = {
          color = "blue";
          icon = "briefcase";
          id = 1;
        };
        TII = {
          color = "red";
          icon = "briefcase";
          id = 2;
        };
      };
      search = {
        force = true;
        default = "search@kagi.comdefault";
        privateDefault = "ddg";
        engines = {
          "search@kagi.comdefault" = {
            name = "Kagi";
            loadPath = "[addon]search@kagi.com";
            icon = "https://kagi.com/favicon.ico";
            extensionID = "search@kagi.com";
            urls = [
              {
                template = "https://kagi.com/search?q={searchTerms}";
              }
              {
                template = "https://kagisuggest.com/api/autosuggest?q={searchTerms}";
                type = "application/x-suggestions+json";
              }
            ];
          };
        };
      };
      extensions = {
        packages = with inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}; [
          ublock-origin
          bitwarden
          consent-o-matic
          dark-mode-website-switcher
          image-max-url
          kagi-search
          reddit-enhancement-suite
          sponsorblock
          multi-account-containers
          csgofloat
          csgo-trader-steam-trading
        ];
      };
    };
  };
}
