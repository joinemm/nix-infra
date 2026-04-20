{
  pkgs,
  ...
}:
{
  home.sessionVariables = {
    XDG_SESSION_TYPE = "wayland";
    QT_QPA_PLATFORM = "wayland";
    MOZ_ENABLE_WAYLAND = 1;
    NIXOS_OZONE_WL = 1;
  };

  home.packages = with pkgs; [
    wl-clipboard
    hyprpicker
    wlopm
    wf-recorder
    slurp
    wl-mirror
  ];
}
