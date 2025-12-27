{ pkgs, ... }:
{
  # use bash for headless systems
  users.defaultUserShell = pkgs.bashInteractive;
}
