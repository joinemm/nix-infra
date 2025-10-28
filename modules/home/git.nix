{ pkgs, user, ... }:
{
  home.packages = [ pkgs.git-absorb ];

  programs.diff-so-fancy.enableGitIntegration = true;

  programs.git = {
    enable = true;
    signing.key = user.gpgKey;

    settings = {
      init.defaultBranch = "master";

      user = {
        name = user.fullName;
        inherit (user) email;
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
    ];
  };
}
