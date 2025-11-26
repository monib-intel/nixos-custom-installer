#!/usr/bin/env bash

# This script sets up a virtual machine to test the generated NixOS installation media.

set -e

# Define variables
ISO_PATH="./result/nixos.iso"
VM_NAME="nixos-test-vm"

# Check if the ISO exists
if [[ ! -f "$ISO_PATH" ]]; then
  echo "Error: ISO file not found at $ISO_PATH"
  exit 1
fi

# Create and start the virtual machine
echo "Starting virtual machine with NixOS installation media..."
virt-install \
  --name "$VM_NAME" \
  --ram 2048 \
  --disk path="$VM_NAME.img",size=10 \
  --vcpus 1 \
  --os-type linux \
  --os-variant nixos \
  --cdrom "$ISO_PATH" \
  --network network=default \
  --graphics none \
  --console pty,target_type=serial \
  --extra-args 'console=ttyS0,115200n8 serial'

echo "Virtual machine $VM_NAME is running. You can connect to it using your preferred method."