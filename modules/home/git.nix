{ pkgs, ... }:
let
  delta-themes = pkgs.stdenv.mkDerivation {
    name = "delta-themes";
    src = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/dandavison/delta/main/themes.gitconfig";
      sha256 = "sha256-kPGzO4bzUXUAeG82UjRk621uL1faNOZfN4wNTc1oeN4=";
    };
    unpackPhase = "true";
    installPhase = ''
      cp $src $out
    '';
  };
in
{
  home.packages = with pkgs; [
    git-absorb
  ];

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      side-by-side = true;
      line-numbers = true;
      hyperlinks = true;
      dark = true;
      features = "navigate mantis-shrimp";
    };
  };

  programs.git = {
    enable = true;
    signing.key = "0x090EB48A4669AA54";

    settings = {
      init.defaultBranch = "master";

      user = {
        name = "Joonas Rautiola";
        email = "joonas@rautiola.co";
      };

      color = {
        status = "auto";
        diff = "auto";
        branch = "auto";
        interactive = "auto";
        ui = "auto";
        sh = "auto";
      };

      merge = {
        conflictStyle = "zdiff3";
        stat = true;
        tool = "nvimdiff2";
      };

      commit.gpgsign = true;
      fetch.prune = true;
      pull.rebase = true;
      push.autoSetupRemote = true;
    };

    includes = [
      {
        condition = "gitdir:~/work/tii/";
        path = "~/work/tii/.gitconfig_include";
      }
      {
        path = toString delta-themes;
      }
    ];
  };
}
