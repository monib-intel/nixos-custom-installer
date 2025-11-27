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

# Find OVMF firmware path
find_ovmf() {
    local ovmf_paths=(
        # Common Linux distribution paths
        "/usr/share/ovmf/OVMF.fd"
        "/usr/share/OVMF/OVMF_CODE.fd"
        "/usr/share/edk2/ovmf/OVMF_CODE.fd"
        "/usr/share/qemu/OVMF.fd"
    )
    
    # Check static paths first
    for path in "${ovmf_paths[@]}"; do
        if [ -f "$path" ]; then
            echo "$path"
            return 0
        fi
    done
    
    # Check Nix store paths (when running in nix develop)
    local nix_ovmf
    nix_ovmf=$(find /nix/store -maxdepth 2 -type d -name "FV" 2>/dev/null | head -1)
    if [ -n "$nix_ovmf" ] && [ -f "$nix_ovmf/OVMF.fd" ]; then
        echo "$nix_ovmf/OVMF.fd"
        return 0
    fi
    
    echo ""
    return 1
}

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

# Find OVMF firmware
OVMF_PATH=$(find_ovmf)
if [ -z "$OVMF_PATH" ]; then
    echo "Error: OVMF firmware not found."
    echo ""
    echo "Please run this script from the nix development shell:"
    echo "  nix develop"
    echo "  ./scripts/test-iso-qemu.sh"
    echo ""
    echo "Or install OVMF/edk2-ovmf package on your system."
    exit 1
fi

echo "OVMF: $OVMF_PATH"
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

# Check if KVM is available
run_qemu() {
    local use_kvm="$1"
    local kvm_flag=""
    
    if [ "$use_kvm" = "true" ]; then
        kvm_flag="-enable-kvm"
    fi
    
    # shellcheck disable=SC2086
    qemu-system-x86_64 \
        $kvm_flag \
        -m "$MEMORY" \
        -smp "$CPUS" \
        -boot d \
        -cdrom "$ISO_PATH" \
        -drive file="$DISK_FILE",format=qcow2,if=virtio \
        -netdev user,id=net0,hostfwd=tcp::2222-:22 \
        -device virtio-net-pci,netdev=net0 \
        -bios "$OVMF_PATH" \
        -display gtk
}

# Try with KVM first, fall back to software emulation
if [ -e /dev/kvm ] && [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
    echo "Using KVM hardware acceleration"
    run_qemu "true"
else
    echo "Note: KVM not available, running without hardware acceleration (slower)"
    run_qemu "false"
fi
