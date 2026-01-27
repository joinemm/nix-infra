#!/usr/bin/env bash

set -euo pipefail

if [[ -z "${1:-}" ]]; then
  echo "Give .hex file to flash!"
  exit 0
fi

sudo dfu-programmer atmega32u4 get
sudo dfu-programmer atmega32u4 erase
sudo dfu-programmer atmega32u4 flash "$1"
sudo dfu-programmer atmega32u4 reset

echo "Done!"
