#!/bin/sh
printf '\033c\033]0;%s\a' SRS_po_EVM
base_path="$(dirname "$(realpath "$0")")"
"$base_path/SRS_po_EVM_V66.x86_64" "$@"
