# NixOS Deployment System - Implementation Specification

This document provides detailed implementation requirements for the NixOS network deployment system. The system should enable deployment from any host to any target machine on a local network using git-tracked configurations.

## Core Requirements

### System Architecture

1. **Flake-based Configuration**
   - Use Nix flakes for reproducible system configurations
   - All dependencies pinned via flake.lock
   - Support for multiple named target configurations

2. **Network Deployment**
   - Any machine with the repository can deploy to any target
   - No central build/deployment server required
   - Deployments over SSH using `nixos-rebuild`

3. **User Configuration**
   - Primary user: `monibahmed`
   - User must have sudo/wheel access on all targets
   - SSH key authentication preferred (password for bootstrap only)

## Implementation Details

### 1. Flake Structure (`flake.nix`)

Create a flake that:
- Defines multiple `nixosConfigurations` for named targets
- Each configuration sets its own hostname
- Imports common base configuration
- Uses modular structure for maintainability

```nix
{
  description = "NixOS configurations for local network";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Optional: Add home-manager, deploy-rs, etc. as needed
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations = {
      # Define each target here
      lab-server = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./targets/common/base.nix
          ./targets/common/users.nix
          ./targets/lab-server/configuration.nix
          { networking.hostName = "lab-server"; }
        ];
      };
      # Add more targets...
    };
  };
}
```

### 2. Common Base Configuration (`targets/common/base.nix`)

Implement base configuration that all targets share:

```nix
{ config, pkgs, lib, ... }: {
  # Core system settings
  system.stateVersion = "23.11";  # Set appropriately
  
  # Nix daemon configuration
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
  };

  # Essential services
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;  # After initial setup
      PermitRootLogin = "no";
    };
  };

  # Network configuration
  networking = {
    networkmanager.enable = true;  # Or systemd-networkd based on preference
    firewall.allowedTCPPorts = [ 22 ];  # SSH
  };

  # Basic packages all systems need
  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    tmux
    wget
    curl
  ];

  # Time and locale
  time.timeZone = "America/Los_Angeles";  # Adjust as needed
  i18n.defaultLocale = "en_US.UTF-8";
}
```

### 3. User Configuration (`targets/common/users.nix`)

Define the monibahmed user:

```nix
{ config, pkgs, ... }: {
  users.users.monibahmed = {
    isNormalUser = true;
    description = "Monib Ahmed";
    extraGroups = [ 
      "wheel"          # For sudo access
      "networkmanager" # Network configuration
      "audio"          # Audio access
      "video"          # Video device access
    ];
    shell = pkgs.bash;  # Or zsh/fish as preferred
    
    # SSH keys for deployment access
    openssh.authorizedKeys.keys = [
      # Add SSH public keys here
      # "ssh-ed25519 AAAAC3... monibahmed@hostname"
    ];
    
    # Initial password for bootstrap only
    # Remove after SSH keys are configured
    initialPassword = "changeme";
  };

  # Sudo configuration
  security.sudo = {
    wheelNeedsPassword = true;  # Or false for passwordless sudo
  };
}
```

### 4. Target-Specific Configurations

Each target should have its own configuration file:

```nix
# targets/lab-server/configuration.nix
{ config, pkgs, ... }: {
  # Hardware-specific imports
  imports = [ 
    # Include hardware scan results if available
    # ./hardware-configuration.nix
  ];

  # Boot configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # File systems (adjust based on actual hardware)
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  # Target-specific services
  services = {
    # Example: Lab server might run Jupyter
    jupyter.enable = true;
    postgresql.enable = true;
  };

  # Target-specific packages
  environment.systemPackages = with pkgs; [
    python3
    gcc
    R
    julia
  ];

  # Network configuration for this target
  networking = {
    interfaces.eth0.useDHCP = true;  # Or static IP
    # interfaces.eth0.ipv4.addresses = [{
    #   address = "192.168.1.50";
    #   prefixLength = 24;
    # }];
  };
}
```

### 5. Deployment Script (`deploy.sh`)

Create a robust deployment script:

```bash
#!/usr/bin/env bash
set -euo pipefail

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
        find targets -maxdepth 1 -type d -not -path targets -not -path "targets/common" \
            -exec basename {} \; | sort
    fi
    echo ""
    echo "Examples:"
    echo "  $0 lab-server 192.168.1.50"
    echo "  $0 dev-workstation dev-workstation.local"
    echo "  $0 media-center localhost"
    exit 1
fi

# Verify target configuration exists
if ! nix flake show --json 2>/dev/null | jq -e ".nixosConfigurations.\"$TARGET_NAME\"" >/dev/null; then
    print_error "Target configuration '$TARGET_NAME' not found in flake.nix"
    exit 1
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
        print_error "Cannot connect to monibahmed@$TARGET_ADDRESS via SSH"
        print_warning "Ensure:"
        print_warning "  - Target is reachable at $TARGET_ADDRESS"
        print_warning "  - SSH service is running on target"
        print_warning "  - User 'monibahmed' exists on target"
        print_warning "  - SSH keys are configured (or use ssh-agent)"
        exit 1
    fi
    
    # Remote deployment
    nixos-rebuild switch \
        --flake .#"$TARGET_NAME" \
        --target-host monibahmed@"$TARGET_ADDRESS" \
        --use-remote-sudo \
        --build-host localhost
fi

print_status "Deployment completed successfully!"
```

### 6. Batch Deployment Script (`deploy-all.sh`)

For deploying to multiple targets:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Define target mappings
declare -A TARGETS=(
    ["lab-server"]="192.168.1.50"
    ["dev-workstation"]="192.168.1.60"
    ["media-center"]="192.168.1.75"
)

# Deployment function
deploy_target() {
    local name=$1
    local addr=$2
    echo "Deploying $name to $addr..."
    if ./deploy.sh "$name" "$addr"; then
        echo "✓ $name deployed successfully"
    else
        echo "✗ $name deployment failed" >&2
        return 1
    fi
}

# Deploy all targets in parallel
export -f deploy_target
export -f print_status print_error print_warning

echo "Starting parallel deployment to all targets..."
echo ""

# Run deployments in parallel
for target in "${!TARGETS[@]}"; do
    deploy_target "$target" "${TARGETS[$target]}" &
done

# Wait for all background jobs
wait

echo ""
echo "All deployments completed!"
```

### 7. Target Discovery Script (`discover-targets.sh`)

Optional utility for network discovery:

```bash
#!/usr/bin/env bash

echo "Scanning for SSH-enabled hosts on local network..."
echo ""

# Get local subnet (adjust interface as needed)
SUBNET=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+\.\d+\.\d+\.\d+/\d+' | grep -v 127.0.0.1 | head -1)

if [ -z "$SUBNET" ]; then
    echo "Could not determine local subnet"
    exit 1
fi

echo "Scanning subnet: $SUBNET"
echo ""

# Scan for SSH hosts
nmap -p 22 --open -oG - "$SUBNET" 2>/dev/null | \
    grep "/open/" | \
    awk '{print $2}' | \
    while read -r host; do
        # Try to get hostname
        hostname=$(timeout 2 ssh -o BatchMode=yes -o ConnectTimeout=1 \
            monibahmed@"$host" hostname 2>/dev/null || echo "unknown")
        echo "$host - $hostname"
    done
```

## Testing Requirements

### 1. Flake Validation
- `nix flake check` should pass without errors
- `nix flake show` should list all target configurations

### 2. Build Testing
- Each configuration should build successfully:
  ```bash
  nix build .#nixosConfigurations.lab-server.config.system.build.toplevel
  ```

### 3. Deployment Testing
- Test local deployment: `./deploy.sh test-target localhost`
- Test remote deployment to at least one target
- Verify SSH connectivity and sudo access

### 4. Rollback Testing
- Verify `nixos-rebuild switch --rollback` works on targets
- Test git-based rollback by deploying previous commits

## Security Considerations

For this local-network deployment:

1. **SSH Security**
   - Use SSH keys instead of passwords (after bootstrap)
   - Configure `PasswordAuthentication = false` after initial setup
   - Consider fail2ban for exposed targets

2. **User Security**
   - Require sudo password by default
   - Limit wheel group membership
   - Regular password rotation for any password-based auth

3. **Network Security**
   - Document that this is for trusted local networks only
   - Consider implementing VLANs for different target types
   - Optional: Add firewall rules for deployment sources

## Error Handling

Scripts should handle common failure scenarios:

1. **Network Failures**
   - Connection timeouts
   - DNS resolution failures
   - SSH connection refused

2. **Permission Failures**
   - Missing sudo access
   - Incorrect SSH keys
   - File permission issues

3. **Build Failures**
   - Out of disk space
   - Network issues downloading packages
   - Configuration syntax errors

4. **Deployment Failures**
   - Service startup failures
   - Hardware incompatibilities
   - Bootloader issues

## Documentation Requirements

1. **Inline Comments**
   - Document all non-obvious configuration choices
   - Explain any workarounds or hacks
   - Note any target-specific requirements

2. **Per-Target README**
   - Each target directory should have a README
   - Document specific hardware requirements
   - Note any manual setup steps

3. **Troubleshooting Guide**
   - Common issues and solutions
   - How to access targets when deployment fails
   - Recovery procedures

## Future Considerations

Design with these potential enhancements in mind:

1. **Binary Cache**
   - Structure to support adding nix-serve later
   - Consider cache location and storage

2. **Secrets Management**
   - Prepare for adding agenix or sops-nix
   - Structure for secrets directory

3. **Monitoring Integration**
   - Hooks for deployment notifications
   - Health check endpoints

4. **CI/CD Integration**
   - GitHub Actions or similar
   - Automated testing of configurations

## Deliverables

1. **Core Files**
   - `flake.nix` with all target configurations
   - Base and user configuration modules
   - At least 2 example target configurations

2. **Scripts**
   - `deploy.sh` - Main deployment script
   - `deploy-all.sh` - Batch deployment
   - `discover-targets.sh` - Network discovery (optional)

3. **Documentation**
   - Updated README.md with all examples working
   - Per-target documentation as needed
   - Troubleshooting guide

4. **Bootstrap Guide**
   - Step-by-step for new target setup
   - Minimal configuration template
   - First deployment walkthrough
