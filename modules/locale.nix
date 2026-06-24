{
  time.timeZone = "Europe/Helsinki";

  i18n = {
    defaultLocale = "fi_FI.UTF-8";
    extraLocaleSettings = {
      LC_MESSAGES = "en_US.UTF-8";
    };
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "fi_FI.UTF-8/UTF-8"
      "ja_JP.UTF-8/UTF-8" # required by some japanese games
    ];
  };

  location.provider = "geoclue2";
  services.geoclue2.enable = true;
}
