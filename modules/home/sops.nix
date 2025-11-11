{ user, inputs, ... }:
{
  imports = [
    inputs.sops-nix.homeManagerModules.default
  ];
  sops = {
    age.keyFile = "${user.home}/.config/sops/age/keys.txt";
  };
}
