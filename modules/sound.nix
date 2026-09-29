{ pkgs, ... }:
{
  services.pipewire = {
    enable = true;
    pulse.enable = true;

    # Improve battery life by disabling camera in pipewire
    # https://www.reddit.com/r/linux/comments/1em8biv/psa_pipewire_has_been_halving_your_battery_life/
    wireplumber = {
      enable = true;
      extraConfig."10-disable-camera" = {
        "wireplumber.profiles".main."monitor.libcamera" = "disabled";
      };
    };
  };

  security.rtkit.enable = true;

  environment.systemPackages = with pkgs; [
    playerctl
  ];
}
