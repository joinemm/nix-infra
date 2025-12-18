{ inputs, lib, ... }:
let
  ghaf-infra-hosts =
    let
      machines = import "${inputs.ghaf-infra}/hosts/machines.nix";
      user = "jrautiola";
    in
    {
      "*.cloudapp.azure.com" = {
        inherit user;
      };
    }
    # map over machine definitions in ghaf-infra and add all of them
    // lib.mapAttrs (name: attrs: {
      host = "${name} ${attrs.ip}";
      hostname = attrs.ip;
      inherit user;
    }) machines;
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        forwardAgent = false;
        identitiesOnly = true;
      };

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
    }
    // ghaf-infra-hosts;
  };
}
