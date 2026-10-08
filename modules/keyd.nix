{
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings = {
        main = {
          capslock = "layer(meta)";
          leftalt = "overloadt2(vim, f13, 200)";
        };
        "vim:A" = {
          h = "left";
          k = "up";
          j = "down";
          l = "right";
        };
      };
      extraConfig = ''
        [meta+vim]
        h = M-A-h
        j = M-A-j
        k = M-A-k
        l = M-A-l
      '';
    };
  };
}
