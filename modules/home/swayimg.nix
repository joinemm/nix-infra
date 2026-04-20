{
  rrograms.swayimg = {
    enable = true;
    settings = {
      general = {
        overlay = "no";
      };
      viewer = {
        window = "#000000";
      };
      list = {
        order = "mtime";
        reverse = "yes";
        all = "yes";
      };
      info = {
        info_timeout = 1;
      };
      "keys.viewer" = {
        ScrollUp = "zoom +5";
        ScrollDown = "zoom -5";
        j = "prev_file";
        k = "next_file";
        Left = "prev_file";
        Right = "next_file";
        b = "exec setbg \"%\"";
      };
      "keys.gallery" = {
        ScrollUp = "thumb +20";
        ScrollDown = "thumb -20";
        j = "page_down";
        k = "page_up";
      };
    };
  };
}
