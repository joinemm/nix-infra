#!/bin/sh

nix eval --json .#deployList 2>/dev/null | jq -r '. | to_entries[] | [.key, .value] | @tsv' | column -t
