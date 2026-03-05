{
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    shellWrapperName = "y";
    settings = {
      manager = {
        sort_dir_first = true;
        sort_by = "mtime";
        sort_reverse = true;
        linemode = "mtime";
      };
      opener = {
        open = [
          {
            run = "xdg-open \"$@\"";
            orphan = true;
            desc = "Open";
          }
        ];
      };
    };
  };
}
