{ user, ... }:
{
  environment.variables = {
    GOPATH = "${user.home}/.local/share/go";
  };

  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
    autoPrune.enable = true;
  };

  users.users."${user.name}".extraGroups = [
    "docker"
    "adbusers"
  ];
}
