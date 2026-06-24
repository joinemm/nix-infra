{
  osConfig,
  pkgs,
  inputs,
  self,
  ...
}:
{
  home.stateVersion = osConfig.system.stateVersion;
  programs.home-manager.enable = true;

  imports = [ inputs.nix-index-database.homeModules.nix-index ];

  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/interface".color-scheme = "prefer-dark";
    };
  };

  # run commands without installing them with `, <cmd>`
  programs.nix-index-database.comma.enable = true;
  programs.fzf.enable = true;

  xdg.configFile."nixpkgs/config.nix".text = ''
    { allowUnfree = true; }
  '';

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  home.packages =
    (with pkgs; [
      # development
      python3
      lua
      nodejs
      actionlint
      gitmoji-cli
      pre-commit
      leetcode-cli
      go-grip
      minicom
      godot
      nurl
      nix-init
      nh
      oras

      # gui apps
      spotify
      darktable
      slack
      pavucontrol
      pcmanfm
      ffmpegthumbnailer # video thumbnails
      obsidian
      gimp
      prusa-slicer
      nsxiv
      via
      krita
      kepubify
      vlc
      libreoffice
      blender
      arduino-ide
      chromium
      karere

      # cli apps
      glow # render markdown on the cli
      nix-output-monitor
      (btop.override { rocmSupport = true; })
      onefetch
      immich-go
      czkawka
      exif
      yt-dlp
      calendar-cli
      croc

      # utils
      ffmpeg-full
      nix-diff
      p7zip
      yq-go
      file
      geekbench
      ripgrep
    ])
    ++ (with self.packages.${pkgs.stdenv.hostPlatform.system}; [
      hypruler
      dev-manager-desktop
    ]);
}
