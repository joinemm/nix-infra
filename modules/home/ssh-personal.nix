{
  programs.ssh = {
    enable = true;
    matchBlocks = {
      miso.hostname = "5.161.235.21";
      oxygen.hostname = "65.21.249.145";
      oracle = {
        hostname = "129.151.193.22";
        user = "ubuntu";
      };

      zinc.hostname = "192.168.1.3";
      nickel.hostname = "192.168.1.4";

      "lab.joinemm.dev *.lab.joinemm.dev" = {
        extraOptions = {
          ConnectTimeout = toString 3;
        };
      };
    };
  };
}
