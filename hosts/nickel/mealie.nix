{
  services.mealie = {
    enable = false; # TODO: fails to build right now

    listenAddress = "127.0.0.1";
    port = 9000;
    database.createLocally = true;

    settings = {
      BASE_URL = "mealie.lab.joinemm.dev";
    };
  };
}
