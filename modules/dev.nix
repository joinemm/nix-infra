{
  inputs,
  pkgs,
  config,
  ...
}:
{

  environment.systemPackages = [
    inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  environment.variables = {
    GOPATH = "/home/${config.owner}/.local/share/go";
  };

  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
    autoPrune.enable = true;
  };
}
