#!/usr/bin/env bash

show_host() {
  local name="$1" hostname="$2"
  BOLD=$'\033[1m'
  CYAN=$'\033[36m'
  GREEN=$'\033[32m'
  RED=$'\033[31m'
  YELLOW=$'\033[33m'
  RESET=$'\033[0m'

  printf '\n%s%s=== %s (%s) ===%s\n' "$BOLD" "$CYAN" "$name" "$hostname" "$RESET"
  ssh_error_file="$(mktemp)"
  if ! version="$(ssh -o BatchMode=yes -o ConnectTimeout=5 "$hostname" nix-show-deployment \
    </dev/null 2>"$ssh_error_file")"; then
    printf '  %s%-18s%s %s%s%s\n' "$BOLD" 'Status:' "$RESET" "$RED" 'SSH failed' "$RESET"
    sed 's/^/  /' "$ssh_error_file"
    rm -f "$ssh_error_file"
    return
  fi
  rm -f "$ssh_error_file"

  revision="$(jq -r '.configurationRevision' <<< "$version")"
  modified="$(jq -r '.modified' <<< "$version")"
  nixos_version="$(jq -r '.nixosVersion' <<< "$version")"
  running_kernel="$(jq -r '.runningKernel' <<< "$version")"
  configured_kernel="$(jq -r '.configuredKernel' <<< "$version")"
  reboot_required="$(jq -r '.rebootRequired' <<< "$version")"
  uptime="$(jq -r '.uptime' <<< "$version")"
  commit="${revision%-dirty}"
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
}
export -f show_host
SHELL="$BASH" parallel --will-cite --jobs 0 --colsep '\t' show_host \
  < <(jq -r 'to_entries[] | [.key, .value] | @tsv' <<< "$HOSTS")
