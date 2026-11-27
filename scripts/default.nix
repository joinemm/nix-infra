{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages = {
        nix-show-deployment = pkgs.writeShellScriptBin "nix-show-deployment" ''
          MODIFIED="$(${pkgs.coreutils}/bin/stat -c %y /run/current-system)"
          RUNNING_KERNEL="$(uname -r)"
          CONFIGURED_KERNEL="$(basename "$(dirname "$(readlink -f /run/current-system/kernel)")")"
          CONFIGURED_KERNEL="''${CONFIGURED_KERNEL##*-linux-}"
          REBOOT_REQUIRED=false
          if [ "$RUNNING_KERNEL" != "$CONFIGURED_KERNEL" ]; then
            REBOOT_REQUIRED=true
          fi
          UPTIME="$(${pkgs.procps}/bin/uptime -p)"
          VERSION="$(nixos-version --json)"
          ${pkgs.jq}/bin/jq \
            --arg modified "$MODIFIED" \
            --arg runningKernel "$RUNNING_KERNEL" \
            --arg configuredKernel "$CONFIGURED_KERNEL" \
            --argjson rebootRequired "$REBOOT_REQUIRED" \
            --arg uptime "$UPTIME" \
            '. + { modified: $modified, runningKernel: $runningKernel, configuredKernel: $configuredKernel, rebootRequired: $rebootRequired, uptime: $uptime }' \
            <<< "$VERSION"
        '';

        show-hosts = pkgs.writeShellApplication {
          name = "show-hosts";
          runtimeInputs = with pkgs; [
            coreutils
            git
            gnused
            jq
            openssh
            parallel
          ];
          text = ''
            HOSTS='${builtins.toJSON self.deployList}'
          ''
          + builtins.readFile ./show-hosts.sh;
        };
      };
    };
}
