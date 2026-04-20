{ pkgs, ... }:
{
  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = false;
      package = pkgs.bluez5-experimental;
      settings.General = {
        Experimental = true;
      };
    };
  };

  # default pulseaudio config loads these modules already.
  # they must be unloaded first if we want to add parameters to them
  services.pulseaudio.extraConfig = # sh
    ''
      # switch bluetooth profile automatically to HSP/headset when mic is requested
      unload-module module-bluetooth-policy
      load-module module-bluetooth-policy auto_switch=2

      # remember the bluetooth device profile when reconnecting
      unload-module module-card-restore
      load-module module-card-restore restore_bluetooth_profile=true
    '';
}
