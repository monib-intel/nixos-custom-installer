#!/usr/bin/env bash

# This script tests the generated NixOS installation media in a VM using QEMU

set -e

# Define variables
ISO_PATH="./nixos-custom-installer.iso"
VM_NAME="nixos-test-vm"
DISK_SIZE="20G"
MEMORY="2048"

# Check if the ISO exists
if [[ ! -f "$ISO_PATH" ]]; then
  echo "Error: ISO file not found at $ISO_PATH"
  echo "Please build the ISO first using: ./scripts/build-iso.sh"
  exit 1
fi

# Check if QEMU is installed
if ! command -v qemu-system-x86_64 &> /dev/null; then
  echo "Error: QEMU is not installed."
  echo ""
  echo "Install QEMU:"
  echo "  macOS: brew install qemu"
  echo "  Linux: sudo apt install qemu-system-x86 (Debian/Ubuntu)"
  echo "         sudo dnf install qemu-system-x86 (Fedora)"
  exit 1
fi

# Create a virtual disk if it doesn't exist
if [[ ! -f "$VM_NAME.qcow2" ]]; then
  echo "Creating virtual disk: $VM_NAME.qcow2 ($DISK_SIZE)..."
  qemu-img create -f qcow2 "$VM_NAME.qcow2" "$DISK_SIZE"
fi

echo ""
echo "Starting NixOS test VM..."
echo "  ISO: $ISO_PATH"
echo "  Memory: ${MEMORY}M"
echo "  Disk: $VM_NAME.qcow2"
echo ""
echo "VM will boot from the ISO. To exit QEMU, press: Ctrl+A then X"
echo ""
echo "Test checklist:"
echo "  1. Check if system boots successfully"
echo "  2. Test WiFi: nmcli device wifi list"
echo "  3. Test SSH login: ssh monibahmed@<VM_IP>"
echo "  4. Verify packages: vim, git, htop, tmux"
echo ""
sleep 2

# Check if KVM is available and accessible
KVM_FLAGS=""
if [ -e /dev/kvm ] && [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
  KVM_FLAGS="-enable-kvm"
  echo "KVM acceleration enabled"
else
  echo "Warning: KVM not available or no permissions. Running without KVM (slower)."
  echo "To enable KVM: sudo usermod -aG kvm $USER (then logout/login)"
fi

echo ""

# Run QEMU with appropriate settings for testing
qemu-system-x86_64 \
  $KVM_FLAGS \
  -m "$MEMORY" \
  -smp 2 \
  -cdrom "$ISO_PATH" \
  -drive file="$VM_NAME.qcow2",format=qcow2,if=virtio \
  -net nic,model=virtio \
  -net user,hostfwd=tcp::2222-:22 \
  -boot d \
  -display default

echo ""
echo "VM stopped. To test again, run this script again."
echo "To connect via SSH (when VM is running): ssh -p 2222 monibahmed@localhost"