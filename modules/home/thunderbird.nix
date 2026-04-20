{ pkgs, ... }:
let
  migadu = {
    imap = {
      host = "imap.migadu.com";
      port = 993;
    };
    smtp = {
      host = "smtp.migadu.com";
      port = 465;
    };
  };
  mkDavRemote = type: uuid: {
    inherit type;
    url = "https://dav.joinemm.dev/joonas/${uuid}/";
    userName = "joonas";
  };
  mkWebcalRemote = id: {
    type = "http";
    url = "https://www.webcal.guru/fi-FI/lataa_kalenteri?calendar_instance_id=${toString id}";
  };
in
{
  programs.thunderbird = {
    enable = true;
    package = pkgs.thunderbird-esr-bin;
    profiles."default".isDefault = true;
    settings = {
      "mail.biff.show_tray_icon_always" = true;
      "calendar.alarms.playsound" = false;
      "calendar.alarms.show" = false;
      "calendar.item.editInTab" = true;
      "calendar.view.visiblehours" = 12;
      "calendar.week.start" = 1;
      "mail.spam.manualMark" = true;
      "mail.threadpane.listview" = 1;
      "mailnews.message_display.disable_remote_image" = false;
      "messenger.startup.action" = 0;
      "network.cookie.cookieBehavior" = 3;
      "places.history.enabled" = false;
      "privacy.globalprivacycontrol.enabled" = true;
    };
  };

  accounts.calendar.accounts = {
    "Primary" = {
      remote = mkDavRemote "caldav" "2a465ca7-ebea-45ff-db4d-61eb39cf6631/";
      thunderbird = {
        enable = true;
        color = "#60A356";
      };
      primary = true;
    };
    "Pyhät" = {
      remote = mkWebcalRemote 52;
      thunderbird = {
        enable = true;
        readOnly = true;
        color = "#FF5555";
      };
    };
    "Hyvä Tietää" = {
      remote = mkWebcalRemote 180;
      thunderbird = {
        enable = true;
        readOnly = true;
        color = "#F1FA8C";
      };
    };
  };

  accounts.contact.accounts = {
    "contacts" = {
      remote = mkDavRemote "carddav" "c589f856-74e5-5445-5cdd-d285c23b82f9/";
      thunderbird.enable = true;
    };
  };

  accounts.email.accounts = {
    "joonas@rautiola.co" = migadu // {
      realName = "Joonas Rautiola";
      address = "joonas@rautiola.co";
      userName = "joonas@rautiola.co";
      thunderbird.enable = true;
      primary = true;
    };

    "mail@joinemm.dev" = migadu // {
      realName = "Joinemm";
      address = "mail@joinemm.dev";
      userName = "mail@joinemm.dev";
      thunderbird.enable = true;
    };
  };
}
