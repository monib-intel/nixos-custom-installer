#!/usr/bin/env bash
set -euo pipefail

# Network discovery script
# Scans the local network for SSH-enabled hosts

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "Scanning for SSH-enabled hosts on local network..."
echo ""

# Get local subnet (adjust interface as needed)
SUBNET=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+\.\d+\.\d+\.\d+/\d+' | grep -v 127.0.0.1 | head -1)

if [ -z "$SUBNET" ]; then
    echo "Could not determine local subnet"
    echo "Please specify subnet manually, e.g.:"
    echo "  nmap -p 22 --open 192.168.1.0/24"
    exit 1
fi

echo "Local subnet: $SUBNET"
echo ""

# Check if nmap is available
if ! command -v nmap &> /dev/null; then
    echo -e "${YELLOW}Warning:${NC} nmap not found"
    echo "Install nmap for network scanning:"
    echo "  nix-shell -p nmap"
    echo ""
    echo "Alternative: Use arp-scan if available:"
    echo "  sudo arp-scan --localnet"
    exit 1
fi

echo "Scanning for SSH hosts (port 22)..."
echo ""

# Scan for SSH hosts
printf "%-16s  %-20s  %s\n" "IP Address" "Hostname" "Status"
printf "%-16s  %-20s  %s\n" "----------" "--------" "------"

nmap -p 22 --open -oG - "$SUBNET" 2>/dev/null | \
    grep "/open/" | \
    awk '{print $2}' | \
    while read -r host; do
        # Try to get hostname via SSH
        hostname=$(timeout 2 ssh -o BatchMode=yes -o ConnectTimeout=1 \
            -o StrictHostKeyChecking=no \
            monibahmed@"$host" hostname 2>/dev/null || echo "-")
        
        # Check if monibahmed user can connect
        if [ "$hostname" != "-" ]; then
            status="${GREEN}accessible${NC}"
        else
            # Try to get hostname via DNS
            hostname=$(getent hosts "$host" 2>/dev/null | awk '{print $2}' || echo "-")
            status="${YELLOW}needs auth${NC}"
        fi
        
        printf "%-16s  %-20s  %b\n" "$host" "$hostname" "$status"
    done

echo ""
echo "Legend:"
echo -e "  ${GREEN}accessible${NC} - Can SSH as monibahmed"
echo -e "  ${YELLOW}needs auth${NC} - SSH available but cannot authenticate"
echo ""
echo "To add a discovered host to your inventory, edit inventory.txt:"
echo "  target-name:ip-address"
