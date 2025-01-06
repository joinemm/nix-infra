{
  programs.ssh = {
    enable = true;
    matchBlocks = {
      miso-old = {
        hostname = "5.161.128.99";
        user = "root";
      };

      miso.hostname = "5.161.235.21";
      oxygen.hostname = "65.21.249.145";
      hydrogen.hostname = " 65.108.222.239";
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
