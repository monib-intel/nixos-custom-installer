#!/usr/bin/env bash
# Test the NixOS installer ISO with QEMU
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Default values
MEMORY="${QEMU_MEMORY:-2048}"
CPUS="${QEMU_CPUS:-2}"
DISK_SIZE="${QEMU_DISK_SIZE:-20G}"
DISK_FILE="${QEMU_DISK_FILE:-/tmp/nixos-test-disk.qcow2}"
ISO_PATH=""

usage() {
    echo "Usage: $0 [OPTIONS] [ISO_PATH]"
    echo ""
    echo "Test the NixOS installer ISO with QEMU."
    echo ""
    echo "Options:"
    echo "  -m, --memory SIZE     Memory in MB (default: $MEMORY)"
    echo "  -c, --cpus NUM        Number of CPUs (default: $CPUS)"
    echo "  -d, --disk SIZE       Disk size (default: $DISK_SIZE)"
    echo "  -f, --disk-file FILE  Disk image file (default: $DISK_FILE)"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "If ISO_PATH is not provided, it will look for the ISO in result-iso/iso/"
    echo ""
    echo "Environment variables:"
    echo "  QEMU_MEMORY     Memory in MB"
    echo "  QEMU_CPUS       Number of CPUs"
    echo "  QEMU_DISK_SIZE  Disk size"
    echo "  QEMU_DISK_FILE  Disk image file path"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--memory)
            MEMORY="$2"
            shift 2
            ;;
        -c|--cpus)
            CPUS="$2"
            shift 2
            ;;
        -d|--disk)
            DISK_SIZE="$2"
            shift 2
            ;;
        -f|--disk-file)
            DISK_FILE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            if [ -z "$ISO_PATH" ]; then
                ISO_PATH="$1"
            else
                echo "Error: Unknown argument: $1"
                usage
                exit 1
            fi
            shift
            ;;
    esac
done

cd "$REPO_ROOT"

# Find ISO if not specified
if [ -z "$ISO_PATH" ]; then
    if [ -d "result-iso/iso" ]; then
        ISO_PATH=$(find result-iso/iso -name "*.iso" -type f 2>/dev/null | head -1)
    fi
fi

if [ -z "$ISO_PATH" ] || [ ! -f "$ISO_PATH" ]; then
    echo "Error: ISO file not found."
    echo ""
    echo "Please build the ISO first:"
    echo "  ./scripts/build-iso.sh"
    echo ""
    echo "Or specify the ISO path:"
    echo "  $0 /path/to/nixos.iso"
    exit 1
fi

echo "Testing NixOS ISO with QEMU"
echo "==========================="
echo "ISO: $ISO_PATH"
echo "Memory: ${MEMORY}MB"
echo "CPUs: $CPUS"
echo "Disk: $DISK_FILE ($DISK_SIZE)"
echo ""

# Create disk image if it doesn't exist
if [ ! -f "$DISK_FILE" ]; then
    echo "Creating virtual disk: $DISK_FILE"
    qemu-img create -f qcow2 "$DISK_FILE" "$DISK_SIZE"
fi

echo "Starting QEMU..."
echo ""
echo "Tips:"
echo "  - Press Ctrl+Alt+G to release mouse capture"
echo "  - Press Ctrl+Alt+F to toggle fullscreen"
echo "  - The VM will boot from the ISO"
echo "  - You can test the installation process on the virtual disk"
echo ""

# Run QEMU with UEFI support
qemu-system-x86_64 \
    -enable-kvm \
    -m "$MEMORY" \
    -smp "$CPUS" \
    -boot d \
    -cdrom "$ISO_PATH" \
    -drive file="$DISK_FILE",format=qcow2,if=virtio \
    -netdev user,id=net0,hostfwd=tcp::2222-:22 \
    -device virtio-net-pci,netdev=net0 \
    -bios /usr/share/ovmf/OVMF.fd \
    -display gtk \
    2>/dev/null || {
        # Fallback without KVM if not available
        echo "Note: KVM not available, running without hardware acceleration (slower)"
        qemu-system-x86_64 \
            -m "$MEMORY" \
            -smp "$CPUS" \
            -boot d \
            -cdrom "$ISO_PATH" \
            -drive file="$DISK_FILE",format=qcow2,if=virtio \
            -netdev user,id=net0,hostfwd=tcp::2222-:22 \
            -device virtio-net-pci,netdev=net0 \
            -bios /usr/share/ovmf/OVMF.fd \
            -display gtk
    }
