{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      deploy-rs = pkgs.deploy-rs.overrideAttrs { patches = [ ./deploy-rs-fix-targets.diff ]; };
    in
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
            deploy-rs
          ];
      };
    };
}
