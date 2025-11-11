{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        name = "snowflake";
        packages = with pkgs; [
          sops
          ssh-to-age
          gnupg
          deploy-rs
          sbctl
          e2fsprogs

          # add scripts to path
          (writeScriptBin "node-list" (builtins.readFile (self + /scripts/list.sh)))
          (writeScriptBin "node-install" (builtins.readFile (self + /scripts/install.sh)))
          (writeScriptBin "node-init-secrets" (builtins.readFile (self + /scripts/init-secrets.sh)))
        ];
      };
    };
}
