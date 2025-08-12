{
  lib,
  inputs,
  ...
}:
{
  programs.ssh = {
    enable = true;

    matchBlocks =
      let
        machines = import "${inputs.ghaf-infra}/hosts/machines.nix";
        user = "jrautiola";
      in
      {
        "*.cloudapp.azure.com" = {
          inherit user;
        };

        "ci-server 172.18.20.100" = {
          hostname = "172.18.20.100";
          inherit user;
        };

        "135.181.103.32" = {
          hostname = "135.181.103.32";
          inherit user;
        };
      }
      # map over machine definitions in ghaf-infra and add all of them
      // lib.mapAttrs (name: attrs: {
        host = "${name} ${attrs.ip}";
        hostname = attrs.ip;
        inherit user;
      }) machines;
  };
}
