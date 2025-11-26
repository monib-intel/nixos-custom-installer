#!/usr/bin/env bash

set -e

echo "Building NixOS installation ISO..."
echo "Note: Cross-compiling from macOS (ARM) to x86_64-linux..."
echo ""

# Build the NixOS ISO using the flake configuration with cross-compilation
nix build .#nixosConfigurations.installer.config.system.build.isoImage \
  --extra-platforms x86_64-linux \
  --option sandbox false

# Find the ISO file
ISO_FILE=$(find result/iso -name "*.iso" 2>/dev/null | head -n 1)

if [ -z "$ISO_FILE" ]; then
  echo "Error: No ISO file found in result/iso/"
  exit 1
fi

# Copy the generated ISO to the current directory
OUTPUT_ISO="nixos-custom-installer.iso"
cp "$ISO_FILE" "$OUTPUT_ISO"

echo ""
echo "✓ NixOS installation ISO has been built successfully!"
echo "  Location: $OUTPUT_ISO"
echo "  Size: $(du -h "$OUTPUT_ISO" | cut -f1)"
echo ""
echo "You can now write this ISO to a USB drive using:"
echo "  dd if=$OUTPUT_ISO of=/dev/sdX bs=4M status=progress"
echo "  (Replace /dev/sdX with your USB device)"