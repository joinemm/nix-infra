{ lib, config, ... }:
{
  imports = [
    (lib.mkAliasOptionModule [ "users" "default" ] [ "users" "users" config.owner ])
  ];

  options = {
    owner = lib.mkOption {
      type = lib.types.str;
      default = "joonas";
    };
  };

  config = {
    users.users.${config.owner} = {
      isNormalUser = true;
      useDefaultShell = true;
      initialHashedPassword = "$y$j9T$KyBnHLJFeVfuTfXyr.PkK.$AI..EcHtj.5x5v4puNb2Gn7iYzmQPSgv2hh7zz6zuz0";
      description = "Joonas Rautiola";
      extraGroups = [
        "wheel"
        "input"
        "dialout"
        "networkmanager"
        "docker"
        "adbusers"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGlFqSQFoSSuAS1IjmWBFXie329I5Aqf71QhVOnLTBG+ joonas@athens" # Laptop
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3h/Aj66ndKFtqpQ8H53tE9KbbO0obThC0qbQQKFQRr joonas@rome" # Desktop
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC0ONtbWZD6fMDQNWSiKLBUlkxJAVQ36jf3LbVEbba4M u0_a224@localhost" # Pixel 8
      ];
    };
  };
}
