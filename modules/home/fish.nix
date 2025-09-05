{ pkgs, lib, ... }:
let
  git-branch-rebase = pkgs.writeShellApplication {
    name = "git-fork-update";
    text = # sh
      ''
        MAIN="''${1:-main}"
        BRANCH="$(git branch | grep '\* ' | sed 's/\* //g')"
        git checkout "$MAIN"
        git pull upstream "$MAIN"
        git push
        git checkout "$BRANCH"
        git rebase "$MAIN"
      '';
  };
in
{
  home.packages = [
    git-branch-rebase
  ];

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

    plugins =
      map
        (name: {
          inherit name;
          inherit (pkgs.fishPlugins.${name}) src;
        })
        [
          "bass"
        ];
  };
}
