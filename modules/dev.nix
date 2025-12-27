{ config, ... }:
{
  environment.variables = {
    GOPATH = "/home/${config.owner}/.local/share/go";
  };

  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
    autoPrune.enable = true;
  };
}
