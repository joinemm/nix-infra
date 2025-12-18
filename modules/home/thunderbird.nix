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
  davHost = "https://dav.joinemm.dev";
  davUser = "joonas";
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
      remote = {
        type = "caldav";
        url = "${davHost}/${davUser}/2a465ca7-ebea-45ff-db4d-61eb39cf6631/";
        userName = davUser;
      };
      thunderbird = {
        enable = true;
        color = "#BD93F9";
      };
      primary = true;
    };
    "Pyhät" = {
      remote = {
        type = "caldav";
        url = "${davHost}/public/55b3acf2-379b-5e91-9636-c557cf55d476/";
      };
      thunderbird = {
        enable = true;
        readOnly = true;
        color = "#FF5555";
      };
    };
    "Hyvä Tietää" = {
      remote = {
        type = "caldav";
        url = "${davHost}/public/f9858e17-dc08-22c6-66aa-d56f92372f21/";
      };
      thunderbird = {
        enable = true;
        readOnly = true;
        color = "#F1FA8C";
      };
    };
  };

  accounts.contact.accounts = {
    "contacts" = {
      remote = {
        type = "carddav";
        url = "${davHost}/${davUser}/c589f856-74e5-5445-5cdd-d285c23b82f9/";
        userName = davUser;
      };
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
