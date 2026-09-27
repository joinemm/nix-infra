{
  services = {
    tangled = {
      knot = rec {
        enable = true;
        gitUser = "git";
        stateDir = "/var/lib/tangled";
        repo.scanPath = "${stateDir}/repos";
        server = {
          hostname = "knot.joinemm.dev";
          owner = "TODO";
        };
      };
      spindle = {
        enable = true;
        server = {
          hostname = "spindle.joinemm.dev";
          owner = "TODO";
        };
      };
    };
  };
}
