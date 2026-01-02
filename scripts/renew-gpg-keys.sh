#!/usr/bin/env bash

if [[ -z "$1" ]]; then
  echo "Give new expiration date!"
  exit 1
fi

set -euo pipefail

KEYSTORE_DEVICE=/dev/sda
IDENTITY="joonas@rautiola.co"
EXPIRATION="$1"
echo "New expiration date: $EXPIRATION"
read -r -s -p "Certify passphrase: " CERTIFY_PASS
echo

echo "MOUNTING VOLUMES"
# Decrypt and mount the encrypted volume:
sudo cryptsetup luksOpen "${KEYSTORE_DEVICE}1" gnupg-secrets
sudo mkdir -p /mnt/encrypted
sudo mount /dev/mapper/gnupg-secrets /mnt/encrypted
# Mount the non-encrypted public partition:
sudo mkdir -p /mnt/public
sudo mount "${KEYSTORE_DEVICE}2" /mnt/public

cleanup() {
  echo "CLEANING UP"
  sudo umount /dev/mapper/gnupg-secrets
  sudo umount "${KEYSTORE_DEVICE}2"
  sudo cryptsetup luksClose gnupg-secrets
}
trap cleanup EXIT

echo "OVERRIDING GNUPGHOME"
GNUPGHOME=$(mktemp -d)
cp -avi /mnt/encrypted/gnupg/* "$GNUPGHOME/"

gpg -K

KEYID=$(gpg -k --with-colons "$IDENTITY" |
  awk -F: '/^pub:/ { print $5; exit }')
KEYFP=$(gpg -k --with-colons "$IDENTITY" |
  awk -F: '/^fpr:/ { print $10; exit }')

echo "RENEWING KEYS"
echo "$KEYID" "$KEYFP"

SUBKEY_FPS=()
mapfile -t SUBKEY_FPS < <(gpg -K --with-colons | awk -F: '/^fpr:/ { print $10 }' | tail -n "+2")

echo "$CERTIFY_PASS" | gpg --pinentry-mode=loopback --passphrase-fd 0 \
  --quick-set-expire "$KEYFP" "$EXPIRATION" "${SUBKEY_FPS[@]}"

echo "EXPORTING PUBLIC KEY"
gpg --armor --export "$KEYID" | sudo tee "/mnt/public/$KEYID-$(date +%F).asc"
gpg --send-key "$KEYID"

echo "RECV NEW PUBLIC KEY"
GNUPGHOME="$HOME/.gnupg"
gpg --recv "$KEYID"
gpg -K
