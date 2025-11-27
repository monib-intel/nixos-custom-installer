#!/usr/bin/env bash
set -euo pipefail

# NixOS deployment script
# Deploys a named configuration to a target machine

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}==>${NC} $1"
}

print_error() {
    echo -e "${RED}Error:${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}Warning:${NC} $1"
}

# Check if running from git repository
if [ ! -f "flake.nix" ]; then
    print_error "Must be run from the nixos-config repository root"
    exit 1
fi

# Parse arguments
TARGET_NAME=${1:-}
TARGET_ADDRESS=${2:-}

# Show usage if arguments missing
if [ -z "$TARGET_NAME" ] || [ -z "$TARGET_ADDRESS" ]; then
    echo "Usage: $0 <target-name> <target-address>"
    echo ""
    echo "Available targets:"
    if [ -d "targets" ]; then
        find targets -maxdepth 1 -type d -not -path targets -not -path "targets/common" -not -path "targets/template" \
            -exec basename {} \; 2>/dev/null | sort
    fi
    echo ""
    echo "Examples:"
    echo "  $0 lab-server 192.168.1.50"
    echo "  $0 dev-workstation dev-workstation.local"
    echo "  $0 media-center localhost"
    exit 1
fi

# Verify target configuration exists
if command -v nix &> /dev/null; then
    if ! nix flake show --json 2>/dev/null | jq -e ".nixosConfigurations.\"$TARGET_NAME\"" >/dev/null 2>&1; then
        print_error "Target configuration '$TARGET_NAME' not found in flake.nix"
        print_warning "Available configurations:"
        nix flake show --json 2>/dev/null | jq -r '.nixosConfigurations | keys[]' 2>/dev/null || echo "Unable to list configurations"
        exit 1
    fi
else
    print_warning "nix command not found, skipping configuration verification"
fi

print_status "Deploying '$TARGET_NAME' configuration to $TARGET_ADDRESS"

# Check if deploying locally or remotely
if [ "$TARGET_ADDRESS" = "localhost" ] || [ "$TARGET_ADDRESS" = "127.0.0.1" ]; then
    print_status "Performing local deployment"

    # Local deployment
    sudo nixos-rebuild switch --flake .#"$TARGET_NAME"
else
    print_status "Performing remote deployment to monibahmed@$TARGET_ADDRESS"

    # Test SSH connectivity first
    if ! ssh -o ConnectTimeout=5 -o BatchMode=yes monibahmed@"$TARGET_ADDRESS" exit 2>/dev/null; then
        print_warning "SSH key authentication failed, trying interactive mode..."
        if ! ssh -o ConnectTimeout=5 monibahmed@"$TARGET_ADDRESS" exit 2>/dev/null; then
            print_error "Cannot connect to monibahmed@$TARGET_ADDRESS via SSH"
            print_warning "Ensure:"
            print_warning "  - Target is reachable at $TARGET_ADDRESS"
            print_warning "  - SSH service is running on target"
            print_warning "  - User 'monibahmed' exists on target"
            print_warning "  - SSH keys are configured (or password authentication is enabled)"
            exit 1
        fi
    fi

    # Remote deployment
    nixos-rebuild switch \
        --flake .#"$TARGET_NAME" \
        --target-host monibahmed@"$TARGET_ADDRESS" \
        --use-remote-sudo \
        --build-host localhost
fi

print_status "Deployment completed successfully!"
