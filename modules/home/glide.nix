{
  lib,
  pkgs,
  inputs,
  self,
  ...
}:
let
  inherit (self.packages.${pkgs.system}) glide-browser;

  mkFirefoxModule = import "${inputs.home-manager}/modules/programs/firefox/mkFirefoxModule.nix";

  dracula-improved = inputs.firefox-addons.lib.${pkgs.system}.buildFirefoxXpiAddon {
    pname = "dracula-improved";
    version = "1.1.2";
    addonId = "{e7f21826-229d-4799-8e7b-325957ed27ab}";
    url = "https://addons.mozilla.org/firefox/downloads/file/3831807/dracula_improved-1.1.2.xpi";
    sha256 = "sha256-EOsG3dUdpncXZt/mhcOrgtszRZdHz4gwZkM/k3/tB3I=";
    meta = with lib; {
      description = "A Dracula theme that doesn't actually suck and have horrible white borders with overly bright sides and actually uses Dark Mode.";
      license = licenses.cc-by-30;
      mozPermissions = [ ];
      platforms = platforms.all;
    };
  };
in
{
  imports = [
    (mkFirefoxModule {
      modulePath = [
        "programs"
        "glide"
      ];
      name = "Glide";
      wrappedPackageName = "glide-browser";
      visible = true;
      platforms.linux = {
        configPath = ".glide/glide";
      };
      platforms.darwin = null;
    })
  ];

  xdg.desktopEntries = {
    glide = {
      name = "Glide";
      genericName = "Web Browser";
      exec = "glide %u";
      terminal = false;
      categories = [
        "Network"
        "WebBrowser"
      ];
      mimeType = [
        "text/html"
        "text/xml"
      ];
      type = "Application";
    };
  };

  programs.glide =
    let
      profile = {
        settings = {
          "app.normandy.first_run" = false;
          "datareporting.usage.uploadEnabled" = false;
          "font.minimum-size.x-western" = 14;
          "font.size.monospace.x-western" = 14;
          "media.hardwaremediakeys.enabled" = false;
          "privacy.donottrackheader.enabled" = true;
          "signon.rememberSignons" = false;
          "extensions.activeThemeID" = "{e7f21826-229d-4799-8e7b-325957ed27ab}";
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
          "browser.uiCustomization.state" =
            "{\"placements\":{\"widget-overflow-fixed-list\":[],\"unified-extensions-area\":[\"sponsorblocker_ajay_app-browser-action\",\"_testpilot-containers-browser-action\",\"betterfloat_rums_dev-browser-action\",\"search_kagi_com-browser-action\",\"refinedhackernews_mihir_ch-browser-action\",\"_2e5ff8c8-32fe-46d0-9fc8-6b8986621f3c_-browser-action\",\"_contain-facebook-browser-action\",\"_194d0dc6-7ada-41c6-88b8-95d7636fe43c_-browser-action\",\"gdpr_cavi_au_dk-browser-action\",\"jid1-zadieub7xozojw_jetpack-browser-action\",\"_cf02b1a7-a01a-4e37-a609-516a283f1ed3_-browser-action\",\"soundfixer_unrelenting_technology-browser-action\",\"_988dd4f5-e8d5-49bf-a766-ff75b0e19fe2_-browser-action\",\"_7a45d857-b303-48e1-8dfa-5e45997ac47f_-browser-action\",\"_6833a9cb-d329-4d96-a062-76b1b663cd2c_-browser-action\"],\"nav-bar\":[\"sidebar-button\",\"back-button\",\"forward-button\",\"stop-reload-button\",\"glide-toolbar-mode-button\",\"customizableui-special-spring1\",\"vertical-spacer\",\"urlbar-container\",\"customizableui-special-spring2\",\"downloads-button\",\"glide-toolbar-keyseq-button\",\"fxa-toolbar-menu-button\",\"reset-pbm-toolbar-button\",\"unified-extensions-button\",\"firefox-view-button\",\"alltabs-button\",\"ublock0_raymondhill_net-browser-action\",\"_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action\",\"dark-mode-website-switcher_rugk_github_io-browser-action\"],\"toolbar-menubar\":[\"menubar-items\"],\"TabsToolbar\":[],\"vertical-tabs\":[\"tabbrowser-tabs\"],\"PersonalToolbar\":[\"import-button\",\"personal-bookmarks\"]},\"seen\":[\"reset-pbm-toolbar-button\",\"developer-button\",\"screenshot-button\",\"betterfloat_rums_dev-browser-action\",\"search_kagi_com-browser-action\",\"_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action\",\"dark-mode-website-switcher_rugk_github_io-browser-action\",\"refinedhackernews_mihir_ch-browser-action\",\"_2e5ff8c8-32fe-46d0-9fc8-6b8986621f3c_-browser-action\",\"sponsorblocker_ajay_app-browser-action\",\"ublock0_raymondhill_net-browser-action\",\"_contain-facebook-browser-action\",\"_194d0dc6-7ada-41c6-88b8-95d7636fe43c_-browser-action\",\"gdpr_cavi_au_dk-browser-action\",\"jid1-zadieub7xozojw_jetpack-browser-action\",\"_cf02b1a7-a01a-4e37-a609-516a283f1ed3_-browser-action\",\"soundfixer_unrelenting_technology-browser-action\",\"_988dd4f5-e8d5-49bf-a766-ff75b0e19fe2_-browser-action\",\"_testpilot-containers-browser-action\",\"_7a45d857-b303-48e1-8dfa-5e45997ac47f_-browser-action\",\"_6833a9cb-d329-4d96-a062-76b1b663cd2c_-browser-action\"],\"dirtyAreaCache\":[\"nav-bar\",\"vertical-tabs\",\"PersonalToolbar\",\"TabsToolbar\",\"unified-extensions-area\",\"toolbar-menubar\"],\"currentVersion\":23,\"newElementCount\":2}";
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
          packages =
            (with inputs.firefox-addons.packages.${pkgs.system}; [
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
            ])
            ++ [
              dracula-improved
            ];
          force = true;
          settings = {
            "uBlock0@raymondhill.net".settings =
              let
                importedLists = [
                  "https://raw.githubusercontent.com/muggs-cant-code/uBlock/refs/heads/main/Filters"
                ];
              in
              {
                userSettings = {
                  inherit importedLists;
                  advancedUserEnabled = true;
                  externalLists = lib.concatStringsSep "\n" importedLists;
                };
                selectedFilterLists = [
                  "user-filters"
                  "ublock-filters"
                  "ublock-badware"
                  "ublock-privacy"
                  "ublock-quick-fixes"
                  "ublock-unbreak"
                  "easylist"
                  "easyprivacy"
                  "urlhaus-1"
                  "plowe-0"
                  "ublock-annoyances"
                  "FIN-0"
                ]
                ++ importedLists;

                userFilters = lib.concatStringsSep "\n" [
                  "accounts.google.com/gsi/*" # google sign in popup
                ];
              };
          };
        };
      };
    in
    {
      enable = true;
      package = glide-browser;
      profiles.default = profile // {
        id = 0;
      };
      # profiles.diff = profile // {
      #   id = 1;
      # };
    };
}
