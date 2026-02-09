{ self, inputs, ... }:
{
  perSystem =
    { system, pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        name = "snowflake";
        packages =
          (with pkgs; [
            sops
            ssh-to-age
            gnupg
            sbctl
            e2fsprogs
            nebula

            # add scripts to path
            (writeScriptBin "node-list" (builtins.readFile (self + /scripts/list.sh)))
            (writeScriptBin "node-install" (builtins.readFile (self + /scripts/install.sh)))
            (writeScriptBin "node-init-secrets" (builtins.readFile (self + /scripts/init-secrets.sh)))
          ])
          ++ [
            inputs.deploy-rs.packages.${system}.default
          ];
      };
    };
}
