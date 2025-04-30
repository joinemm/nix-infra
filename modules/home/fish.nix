{ pkgs, ... }:
{
  programs.fish = {
    enable = true;

    shellAbbrs = {
      gs = "git status";
      gd = "git diff";
      ga = "git add";
    };

    shellAliases = {
      ls = "ls --color=auto --hyperlink";
      mv = "mv -iv";
      rm = "rm -I";
      cp = "cp -iv";
      ln = "ln -iv";

      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";

      please = "sudo $history[1]";
      copy = "xclip -selection clipboard";
      dev = "nix develop --impure -c $SHELL";
      git-branch-cleanup = "git branch -vv | grep gone | awk '{print $1}' | xargs git branch -D";
    };

    shellInit = # fish
      ''
        # Start X at login
        if status is-login
            if test -z "$DISPLAY" -a "$XDG_VTNR" = 1
                exec startx -- -keeptty
            end
        end
      '';

    interactiveShellInit = # fish
      ''
        if not set -q fish_configured
          set -U fish_greeting
          tide configure --auto \
            --style=Lean \
            --prompt_colors='16 colors' \
            --show_time=No \
            --lean_prompt_height='Two lines' \
            --show_time='24-hour format' \
            --prompt_connection=Dotted \
            --prompt_spacing=Compact \
            --icons='Few icons' \
            --transient=Yes

          tide reload
          set -U fish_configured
        end
      '';

    plugins =
      map
        (name: {
          inherit name;
          inherit (pkgs.fishPlugins.${name}) src;
        })
        [
          "tide"
          "bass"
        ];
  };
}
