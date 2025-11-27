#!/usr/bin/env bash
# Build a bootable NixOS installer ISO image
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Building NixOS installer ISO..."
echo "Repository root: $REPO_ROOT"

cd "$REPO_ROOT"

# Build the ISO image
nix build .#nixosConfigurations.installer.config.system.build.isoImage \
    --out-link result-iso

# Find the built ISO
ISO_PATH=$(find result-iso/iso -name "*.iso" -type f 2>/dev/null | head -1)

if [ -n "$ISO_PATH" ]; then
    echo ""
    echo "ISO built successfully!"
    echo "Location: $ISO_PATH"
    echo "Size: $(du -h "$ISO_PATH" | cut -f1)"
    echo ""
    echo "To test with QEMU, run:"
    echo "  ./scripts/test-iso-qemu.sh"
    echo ""
    echo "To write to USB drive:"
    echo "  sudo dd if=$ISO_PATH of=/dev/sdX bs=4M status=progress"
else
    echo "Error: ISO file not found after build"
    exit 1
fi
