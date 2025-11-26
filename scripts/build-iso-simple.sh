#!/usr/bin/env bash

set -e

echo "Building NixOS installation ISO using nixos-generators..."
echo "Note: This may take a while on macOS..."
echo ""

# Install nixos-generators if not already available
if ! nix-shell -p nixos-generators --run "echo 'nixos-generators available'" &>/dev/null; then
  echo "Installing nixos-generators..."
fi

# Build using nixos-generators
nix-shell -p nixos-generators --run \
  "nixos-generate --format iso --configuration ./modules/installer.nix --system x86_64-linux"

echo ""
echo "✓ Build complete!"
echo ""
echo "The ISO will be in the current directory."
