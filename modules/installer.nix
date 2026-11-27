{
  config,
  inputs,
  lib,
  ...
}:
{
  imports = [
    inputs.nixos-images.nixosModules.image-installer
    ./users.nix
  ];

  # Disabled because bcachefs fails to build against Linux 6.18.64.
  # https://github.com/koverstreet/bcachefs-tools/issues/1241
  boot.supportedFilesystems.bcachefs = false;

  networking = {
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };
    useNetworkd = lib.mkForce false;
  };
  systemd.network.enable = lib.mkForce false;

  users.users.root.openssh.authorizedKeys.keys =
    config.users.users.${config.owner}.openssh.authorizedKeys.keys;
  nix.settings.trusted-users = [ config.owner ];
}
