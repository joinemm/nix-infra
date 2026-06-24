{ config, ... }:
{
  services.accounts-daemon.enable = true;

  systemd.tmpfiles.rules =
    let
      user = config.owner;
      icon = ../face.png;
    in
    [
      "f+ /var/lib/AccountsService/users/${user}  0644 root root -  [User]\\nSession=\\nIcon=/var/lib/AccountsService/icons/${user}\\nSystemAccount=false\\n"
      "L+ /var/lib/AccountsService/icons/${user}  0644 root root -  ${icon}"
    ];
}
