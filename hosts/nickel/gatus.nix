{
  services.gatus = {
    enable = true;
    settings = {
      web.port = 3333;
      connectivity.checker = {
        target = "1.1.1.1:53";
        interval = "60s";
      };
      endpoints = [
        {
          name = "Syncthing cloud node";
          url = "https://sync.joinemm.dev/rest/noauth/health";
          interval = "5m";
          conditions = [
            "[STATUS] == 200"
            "[BODY].status == OK"
            "[RESPONSE_TIME] < 300"
          ];
        }
        {
          name = "Minecraft";
          url = "https://mcapi.us/server/status?ip=mc.joinemm.dev";
          interval = "10m";
          conditions = [
            "[STATUS] == 200"
            "[BODY].online == true"
            "[RESPONSE_TIME] < 1000"
          ];
        }
        {
          name = "Radicale";
          url = "https://dav.joinemm.dev";
          interval = "5m";
          conditions = [
            "[STATUS] == 200"
            "[RESPONSE_TIME] < 300"
          ];
        }
      ];
    };
  };
}
