{
  lib,
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    brightnessctl
    mons
    acpi
    powertop
  ];

  # use S3 sleep mode
  boot.kernelParams = [ "mem_sleep_default=deep" ];

  # Enablees UPower and power hooks
  powerManagement.enable = true;

  # airplane mode button has to work without sudo
  security.sudo.extraRules = [
    {
      groups = [ "wheel" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/rfkill";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  services.displayManager.ly.settings = {
    battery_id = "BAT0";
  };

  services = {
    xserver.xkb.options = "caps:super";

    libinput.touchpad = {
      tapping = true;
      disableWhileTyping = true;
    };

    upower = {
      enable = true;
      percentageLow = 10;
      percentageCritical = 5;
      percentageAction = 2;
    };

    tlp = {
      enable = true;
      pd.enable = true;
      settings = {
        TLP_AUTO_SWITCH = 1;
        TLP_PERSISTENT_DEFAULT = 0;
        TLP_DEFAULT_MODE = "BAL";

        CPU_BOOST_ON_BAT = 1;

        WIFI_PWR_ON_BAT = "on";
        SOUND_POWER_SAVE_ON_BAT = 1;
        RUNTIME_PM_ON_BAT = "auto";

        START_CHARGE_THRESH_BAT0 = 90;
        STOP_CHARGE_THRESH_BAT0 = 100;

        DEVICES_TO_DISABLE_ON_STARTUP = "nfc";
      };
    };
  };

  systemd.services.tlp-pd.wantedBy = lib.mkForce [ ];
}
