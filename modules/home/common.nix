{ pkgs, inputs, ... }:
{
  home.stateVersion = "23.11";
  programs.home-manager.enable = true;
  systemd.user.startServices = false;

  imports = [ inputs.nix-index-database.homeModules.nix-index ];

  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/interface".color-scheme = "prefer-dark";
    };
  };

  programs = {
    # run commands without installing them with `, <cmd>`
    nix-index-database.comma.enable = true;
    fzf.enable = true;
  };

  nix.gc = {
    automatic = true;
    frequency = "weekly";
    options = "--delete-older-than 14d";
  };

  programs.chawan = {
    enable = true;
    settings = {
      buffer = {
        images = true;
      };
    };
  };

  home.packages = with pkgs; [
    # development
    python3
    rustup
    lua
    nodejs
    actionlint
    gitmoji-cli
    pre-commit
    leetcode-cli
    calendar-cli

    # gui apps
    spotify
    darktable
    slack
    pavucontrol
    pcmanfm
    ffmpegthumbnailer # video thumbnails
    obsidian
    gimp
    chromium
    prusa-slicer
    nsxiv
    via
    freecad
    krita
    kepubify
    vlc
    libreoffice

    # cli apps
    glow # render markdown on the cli
    nix-output-monitor
    (btop.override { rocmSupport = true; })
    onefetch
    immich-go
    czkawka
    exif
    yt-dlp

    # utils
    tree
    rsync
    ffmpeg-full
    nix-diff
    p7zip
    yq-go
    file
    jq
    geekbench
  ];
}
