{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages = {
        rpi-export = pkgs.callPackage ./rpi-export { };
        blocky-ui = pkgs.callPackage ./blocky-ui { };
        weddingshare = pkgs.callPackage ./weddingshare { };
        idlehack = pkgs.callPackage ./idlehack { };
        hypruler = pkgs.callPackage ./hypruler { };
        dev-manager-desktop = pkgs.callPackage ./dev-manager-desktop { };
        rishot = pkgs.callPackage ./rishot { };

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

        show-hosts = pkgs.writeShellScriptBin "show-hosts" ''
          HOSTS='${builtins.toJSON self.deployList}'
          BOLD=$'\033[1m'
          CYAN=$'\033[36m'
          GREEN=$'\033[32m'
          RED=$'\033[31m'
          YELLOW=$'\033[33m'
          RESET=$'\033[0m'

          while IFS=$'\t' read -r name hostname; do
            printf '\n%s%s=== %s (%s) ===%s\n' "$BOLD" "$CYAN" "$name" "$hostname" "$RESET"
            ssh_error_file="$(mktemp)"
            if ! version="$(ssh -o BatchMode=yes -o ConnectTimeout=5 "$hostname" nix-show-deployment \
              </dev/null 2>"$ssh_error_file")"; then
              printf '  %s%-18s%s %s%s%s\n' "$BOLD" 'Status:' "$RESET" "$RED" 'SSH failed' "$RESET"
              sed 's/^/  /' "$ssh_error_file"
              rm -f "$ssh_error_file"
              continue
            fi
            rm -f "$ssh_error_file"

            revision="$(jq -r '.configurationRevision' <<< "$version")"
            modified="$(jq -r '.modified' <<< "$version")"
            nixos_version="$(jq -r '.nixosVersion' <<< "$version")"
            running_kernel="$(jq -r '.runningKernel' <<< "$version")"
            configured_kernel="$(jq -r '.configuredKernel' <<< "$version")"
            reboot_required="$(jq -r '.rebootRequired' <<< "$version")"
            uptime="$(jq -r '.uptime' <<< "$version")"
            commit="''${revision%-dirty}"
            if commits_behind="$(git rev-list --count "$commit..HEAD" 2>/dev/null)"; then
              revision_display="$revision"
              behind_display="($commits_behind commits behind)"
              if [ "$commits_behind" -gt 0 ]; then
                behind_color="$RED"
              else
                behind_color="$GREEN"
              fi
            else
              revision_display="$revision"
              behind_display='(unknown commits behind)'
              behind_color="$YELLOW"
            fi
            if [ "$reboot_required" = true ]; then
              kernel_display="$running_kernel -> $configured_kernel [reboot required]"
              kernel_color="$RED"
            else
              kernel_display="$running_kernel"
              kernel_color="$GREEN"
            fi
            printf '  %s%-18s%s %s\n' "$BOLD" 'Last modified:' "$RESET" "$modified"
            printf '  %s%-18s%s %s\n' "$BOLD" 'NixOS version:' "$RESET" "$nixos_version"
            printf '  %s%-18s%s %s%s%s\n' "$BOLD" 'Kernel version:' "$RESET" "$kernel_color" "$kernel_display" "$RESET"
            printf '  %s%-18s%s %s\n' "$BOLD" 'Current uptime:' "$RESET" "$uptime"
            printf '  %s%-18s%s %s%s%s %s%s%s\n' "$BOLD" 'Commit revision:' "$RESET" "$CYAN" "$revision_display" "$RESET" "$behind_color" "$behind_display" "$RESET"
            if commit_info="$(git show -s --format='%cI%x09%s' "$commit" 2>/dev/null)"; then
              IFS=$'\t' read -r commit_timestamp commit_message <<< "$commit_info"
              printf '  %s%-18s%s %s\n' "$BOLD" 'Commit created:' "$RESET" "$commit_timestamp"
              printf '  %s%-18s%s %s%s%s\n' "$BOLD" 'Commit message:' "$RESET" "$YELLOW" "$commit_message" "$RESET"
            else
              printf '  %s%-18s%s %s%s%s\n' "$BOLD" 'Commit:' "$RESET" "$RED" 'not found locally' "$RESET"
            fi
          done < <(jq -r 'to_entries[] | [.key, .value] | @tsv' <<< "$HOSTS")
        '';
      };
    };
}
