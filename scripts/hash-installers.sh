#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
if command -v sha256sum >/dev/null 2>&1; then
  sha256sum install.ps1 install.sh
else
  shasum -a 256 install.ps1 install.sh
fi
