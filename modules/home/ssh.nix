{ inputs, lib, ... }:
let
  ghaf-infra-hosts =
    let
      machines = import "${inputs.ghaf-infra}/hosts/machines.nix";
      User = "jrautiola";
    in
    {
      "*.cloudapp.azure.com" = {
        inherit User;
      };
    }
    # map over machine definitions in ghaf-infra and add all of them
    // lib.mapAttrs' (
      name: attrs:
      lib.nameValuePair "${name} ${attrs.machine.ip}" {
        HostName = attrs.machine.ip;
        inherit User;
      }
    ) (lib.filterAttrs (_: host: host ? machine) machines);
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        ForwardAgent = false;
        IdentitiesOnly = true;
      };

      miso.HostName = "5.161.235.21";
      oxygen.HostName = "65.21.249.145";
      zinc.HostName = "192.168.1.3";
      nickel.HostName = "192.168.1.4";

      oracle = {
        HostName = "129.151.193.22";
        User = "ubuntu";
      };

      "lab.joinemm.dev *.lab.joinemm.dev" = {
        ConnectTimeout = 3;
      };
    }
    // ghaf-infra-hosts;
  };
}
