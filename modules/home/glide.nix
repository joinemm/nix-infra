{
  pkgs,
  inputs,
  self,
  ...
}:
let
  inherit (self.packages.${pkgs.system}) glide-browser;
  mkFirefoxModule = import "${inputs.home-manager}/modules/programs/firefox/mkFirefoxModule.nix";
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
        configPath = ".glide";
      };
    })
  ];

  home.packages = [ glide-browser ];

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

  programs.glide.profiles.default = {
    settings = {
      "browser.aboutConfig.showWarning" = false;
      "browser.urlbar.trimURLs" = false;
      "datareporting.usage.uploadEnabled" = false;
      "font.minimum-size.x-western" = 14;
      "font.size.monospace.x-western" = 14;
      "media.hardwaremediakeys.enabled" = false;
      "privacy.donottrackheader.enabled" = true;
      "sidebar.verticalTabs" = true;
      "sidebar.visibility" = "expand-on-hover";
      "browser.startup.page" = 1; # don't open previous tabs
    };
    extensions.settings = {
      "uBlock0@raymondhill.net".settings = {
        userSettings = {
          externalLists = "https://raw.githubusercontent.com/muggs-cant-code/uBlock/refs/heads/main/Filters";
          importedLists = [
            "https://raw.githubusercontent.com/muggs-cant-code/uBlock/refs/heads/main/Filters"
          ];
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
          "https://raw.githubusercontent.com/muggs-cant-code/uBlock/refs/heads/main/Filters"
        ];
      };
    };
  };
}
