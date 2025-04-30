{ pkgs, ... }:
{
  home.packages = with pkgs; [ birdtray ];

  programs.thunderbird = {
    enable = true;
    profiles."default".isDefault = true;
    settings = {
      "mail.biff.show_tray_icon_always" = false;
    };
  };

  accounts.email =
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
    in
    {
      maildirBasePath = "mail";
      accounts = {

        "joonas@rautiola.co" = {
          realName = "Joonas Rautiola";
          address = "joonas@rautiola.co";
          userName = "joonas@rautiola.co";
          signature.text = "Joonas";
          thunderbird.enable = true;
          primary = true;
        } // migadu;

        "mail@joinemm.dev" = {
          realName = "Joinemm";
          address = "mail@joinemm.dev";
          userName = "mail@joinemm.dev";
          signature.text = "Joinemm";
          thunderbird.enable = true;
        } // migadu;
      };
    };
}
