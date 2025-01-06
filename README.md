<img alt="NixOS" src="https://raw.githubusercontent.com/NixOS/nixos-artwork/master/logo/nix-snowflake-white.svg" width="150px"/>

# Nix Infra

My personal NixOS flake, including configuration for all of my systems and servers.

The configuration is modular, with modules imported to each host as needed.

Shell scripts are built from the flake at <https://github.com/joinemm/bin>

## Hosts

- `cobalt` - Desktop workstation/gaming pc
- `carbon` - Thinkpad X1 Carbon gen11 (work laptop)
- `misobot` - Hetzner box running Miso Bot's production deployment
- `oxygen` - Hetzner box acting as syncthing node and hosting web services
- `zinc` - Raspberry Pi 4B, mainly used as a DNS server
- `nickel` - Aoostar WTR PRO, my NAS and home server

## Installing a configuration

Assuming NixOS is already running, a config can be switched to:

```sh
nixos-rebuild switch --flake .#$HOST
```

## Installing to remote servers

The included script will install the system, and add `ssh_host_ed25519_key` specified in `secrets.yaml`

```sh
./scripts/install .#$HOST $REMOTE_IP --secrets hosts/$HOST/secrets.yaml
```

To update the remote server after changes, run `nixos-rebuild` with remote target:

```sh
nixos-rebuild switch --flake .#$HOST --target-host $REMOTE_IP --use-remote-sudo
```

Add `--fast` if the target system architecture does not match yours (e.g. it's `aarch64` system)

## SD card images

The raspberry pi config can be built as flashable sd card image for initial installation:

```sh
nix build .#nixosConfigurations.zinc.config.system.build.sdImage

# check sd card device
lsblk
# flash to sd card
cd result/sd-image
sudo dd if=nixos-sd-image-xxx-aarch64-linux.img of=/dev/xxx bs=4M conv=fsync status=progress
```

This sd card can now be inserted into a raspberry pi and it will boot the configuration.

## ZMK Firmware

This flake can also build the firmware for my custom Kyria split keyboard, with the keymaps located at `./keyboards/kyria/config`

```sh
nix build .#firmware
```

The resulting `.u2f` firmware files for left and right half are located inside `result`.

The keymap svg can be drawn with `nix run .#draw-keymap` and will create a new file in the current directory.
