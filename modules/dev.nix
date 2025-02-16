{ pkgs, user, ... }:
{
  programs.adb.enable = true;
  services.udev.packages = [ pkgs.android-udev-rules ];

  environment.variables = {
    GOPATH = "${user.home}/.local/share/go";
  };

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune.enable = true;
  };

  users.users."${user.name}".extraGroups = [
    "docker"
    "adbusers"
  ];
}
