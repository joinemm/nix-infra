#!/usr/bin/env bash
FLAKE=$1
HOST=$2
EXTRAFLAGS=()

shift 2
for arg in "$@"; do
    case $arg in
    --secrets)
        SECRETS=$2
        shift
        shift
        ;;
    -v)
        EXTRAFLAGS+=("--debug")
        shift
        ;;
    --*)
        EXTRAFLAGS+=("$1")
        shift
        ;;
    esac
done

if [[ -z "$FLAKE" || -z "$HOST" ]]; then
    echo "FLAKE and HOST not given!"
    echo ""
    echo "Usage:"
    echo "  $(basename "$0") .#flakeattr user@hostname [--secrets /path/to/yaml] [-v]"
    exit 1
fi

echo "FLAKE      = $FLAKE"
echo "HOST       = $HOST"
echo "SECRETS    = $SECRETS"
echo "EXTRAFLAGS = ${EXTRAFLAGS[*]}"

read -p "Install? [y/N]: " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "> starting installation"
    FLAGS=("--flake" "$FLAKE" "--option" "accept-flake-config" "true")

    if [[ -n "$SECRETS" ]]; then
        echo "> decrypting ssh host key from $SECRETS"
        temp=$(mktemp -d)
        install -d -m755 "$temp/etc/ssh"
        nix run --inputs-from . nixpkgs#sops -- \
            --extract '["ssh_host_ed25519_key"]' \
            --decrypt "$SECRETS" >"$temp/etc/ssh/ssh_host_ed25519_key"
        chmod 600 "$temp/etc/ssh/ssh_host_ed25519_key"
        FLAGS+=("--extra-files" "$temp")
    fi

    echo "> running nixos-anywhere"
    set -x
    nix run --inputs-from . nixpkgs#nixos-anywhere -- \
        "$HOST" "${FLAGS[@]}" "${EXTRAFLAGS[@]}"
fi
