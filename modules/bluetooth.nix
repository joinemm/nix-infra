{ pkgs, ... }:
{
  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = false;
      package = pkgs.bluez5-experimental;
      settings.General = {
        ControllerMode = "dual";
        Experimental = true;
        KernelExperimental = true;
      };
    };
  };

  services.pipewire.wireplumber.extraConfig."10-bluetooth-audio" = {
    "wireplumber.settings" = {
      "bluetooth.autoswitch-to-headset-profile" = true;
    };

    "monitor.bluez.properties" = {
      "bluez5.disable-dummy-call" = true;
    };
  };

  boot.extraModprobeConfig = ''
    options btusb force_scofix=1
  '';
}
