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
        Privacy = "device";
      };
    };
  };

  services.pipewire.wireplumber.extraConfig."10-bluetooth-audio" = {
    "wireplumber.settings" = {
      "bluetooth.autoswitch-to-headset-profile" = true;
    };
  };
}
