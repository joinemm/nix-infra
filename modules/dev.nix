{
  inputs,
  pkgs,
  config,
  ...
}:
{

  environment.systemPackages = [
    inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.bubblewrap # For codex
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
