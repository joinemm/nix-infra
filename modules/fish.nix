{ pkgs, ... }: {
  # Set fish as default shell
  users.defaultUserShell = pkgs.fish;
  programs.fish.enable = true;
}
