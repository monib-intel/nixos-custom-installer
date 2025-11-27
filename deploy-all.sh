#!/usr/bin/env bash
set -euo pipefail

# Batch deployment script
# Deploys to all targets defined in inventory.txt or the TARGETS array

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

# Define target mappings - modify these for your network
# Format: target-name:ip-address
declare -A TARGETS

# Load from inventory.txt if it exists
if [ -f "inventory.txt" ]; then
    print_status "Loading targets from inventory.txt"
    while IFS=: read -r name addr || [ -n "$name" ]; do
        # Skip comments and empty lines
        [[ "$name" =~ ^#.*$ ]] && continue
        [[ -z "$name" ]] && continue
        # Trim whitespace
        name=$(echo "$name" | xargs)
        addr=$(echo "$addr" | xargs)
        if [ -n "$name" ] && [ -n "$addr" ]; then
            TARGETS["$name"]="$addr"
        fi
    done < inventory.txt
else
    # Default targets - modify for your environment
    print_warning "No inventory.txt found, using default targets"
    TARGETS=(
        ["lab-server"]="192.168.1.50"
        ["dev-workstation"]="192.168.1.60"
        ["media-center"]="192.168.1.75"
    )
fi

# Check if any targets defined
if [ ${#TARGETS[@]} -eq 0 ]; then
    print_error "No targets defined"
    print_warning "Create an inventory.txt file with format: target-name:ip-address"
    exit 1
fi

# Track deployment results
declare -A RESULTS
FAILED=0

# Deployment function
deploy_target() {
    local name=$1
    local addr=$2
    print_status "Deploying $name to $addr..."
    if ./deploy.sh "$name" "$addr"; then
        echo -e "${GREEN}✓${NC} $name deployed successfully"
        return 0
    else
        echo -e "${RED}✗${NC} $name deployment failed" >&2
        return 1
    fi
}

echo ""
print_status "Starting deployment to all targets..."
echo ""
echo "Targets:"
for target in "${!TARGETS[@]}"; do
    echo "  - $target: ${TARGETS[$target]}"
done
echo ""

# Deploy to each target sequentially
# (Parallel deployment can be enabled but may cause issues with SSH)
for target in "${!TARGETS[@]}"; do
    if deploy_target "$target" "${TARGETS[$target]}"; then
        RESULTS["$target"]="success"
    else
        RESULTS["$target"]="failed"
        ((FAILED++)) || true
    fi
    echo ""
done

# Summary
echo ""
print_status "Deployment Summary"
echo "===================="
for target in "${!RESULTS[@]}"; do
    if [ "${RESULTS[$target]}" = "success" ]; then
        echo -e "  ${GREEN}✓${NC} $target: ${TARGETS[$target]}"
    else
        echo -e "  ${RED}✗${NC} $target: ${TARGETS[$target]} (FAILED)"
    fi
done
echo ""

if [ $FAILED -gt 0 ]; then
    print_error "$FAILED deployment(s) failed"
    exit 1
else
    print_status "All deployments completed successfully!"
fi
