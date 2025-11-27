# NixOS Network Deployment System

A git-based, reproducible NixOS deployment system that enables any host on the network to deploy configurations to any target machine.

## Overview

This system allows you to:
- Deploy NixOS configurations from any machine to any target on your local network
- Maintain named configurations for specific machines (lab-server, dev-workstation, etc.)
- Track all system configurations in git for reproducibility
- Deploy without complex security infrastructure (designed for trusted local networks)

## Quick Start

### Deploy to a target
```bash
# From any host machine, deploy a named configuration to a target
./deploy.sh lab-server 192.168.1.50

# Deploy to multiple targets
./deploy-all.sh
```

### Self-deployment
```bash
# SSH into target and deploy to itself
ssh monibahmed@lab-server
cd nixos-config
./deploy.sh lab-server localhost
```

## Project Structure

```
nixos-config/
├── flake.nix              # Nix flake defining all target configurations
├── flake.lock             # Locked dependencies for reproducibility
├── deploy.sh              # Main deployment script
├── deploy-all.sh          # Batch deployment script
├── run-tests.sh           # Test runner script
├── inventory.txt          # Target name to IP mapping (optional)
├── targets/               # Target-specific configurations
│   ├── common/            # Shared configuration modules
│   │   ├── base.nix       # Base system configuration
│   │   └── users.nix      # User configuration (monibahmed)
│   ├── lab-server/        # Lab server specific config
│   │   └── configuration.nix
│   ├── dev-workstation/   # Development workstation config
│   │   └── configuration.nix
│   └── media-center/      # Media center config
│       └── configuration.nix
├── modules/               # Optional reusable modules
│   ├── desktop.nix        # Desktop environment config
│   ├── development.nix    # Development tools
│   └── services.nix       # Common services
├── tests/                 # QEMU-based VM tests
│   ├── README.md          # Testing documentation
│   ├── basic-health.nix   # Basic health check test
│   ├── lab-server.nix     # Lab server test
│   └── ssh-connectivity.nix # SSH connectivity test
└── .github/workflows/     # CI/CD workflows
    └── test.yml           # Automated test workflow
```

## Terminology

- **Host**: The machine initiating the deployment (where you run deploy commands)
- **Target**: The machine receiving the deployment (where NixOS will be installed/updated)
- **Configuration**: A named NixOS configuration (e.g., lab-server, dev-workstation)

## Adding a New Target

1. Create a new directory under `targets/`:
   ```bash
   mkdir targets/new-machine
   ```

2. Create configuration file:
   ```bash
   cp targets/template/configuration.nix targets/new-machine/
   ```

3. Edit the configuration for your specific needs

4. Add to `flake.nix`:
   ```nix
   nixosConfigurations = {
     new-machine = nixpkgs.lib.nixosSystem {
       system = "x86_64-linux";
       modules = [
         ./targets/common/base.nix
         ./targets/new-machine/configuration.nix
         { networking.hostName = "new-machine"; }
       ];
     };
   };
   ```

5. Deploy:
   ```bash
   ./deploy.sh new-machine 192.168.1.XX
   ```

## Initial Target Setup

For a new machine that needs NixOS:

1. Install minimal NixOS from USB/ISO
2. Enable SSH and create user:
   ```nix
   {
     services.openssh.enable = true;
     users.users.monibahmed = {
       isNormalUser = true;
       extraGroups = [ "wheel" ];
       initialPassword = "changeme";  # Change after first deploy
     };
   }
   ```
3. Note the IP address
4. From any host machine:
   ```bash
   ./deploy.sh target-name <ip-address>
   ```

## Network Discovery

Find available NixOS targets on your network:

```bash
# Using nmap
nmap -p 22 192.168.1.0/24

# Using the discovery script
./discover-targets.sh
```

## Deployment Examples

### Deploy specific configuration to specific IP
```bash
./deploy.sh lab-server 192.168.1.50
```

### Deploy using hostname (if mDNS is configured)
```bash
./deploy.sh dev-workstation dev-workstation.local
```

### Deploy from configuration directory
```bash
cd /path/to/nixos-config
nix run .#deploy lab-server 192.168.1.50
```

### Update all targets
```bash
./deploy-all.sh
```

## Configuration Management

### Update configurations
```bash
# Pull latest changes
git pull

# Deploy to specific target
./deploy.sh lab-server 192.168.1.50
```

### Test changes
```bash
# Create a test branch
git checkout -b test-changes

# Make your changes
vim targets/lab-server/configuration.nix

# Deploy to test target
./deploy.sh lab-server 192.168.1.50

# If successful, merge to main
git checkout main
git merge test-changes
```

### Rollback
```bash
# On the target machine
sudo nixos-rebuild switch --rollback

# Or redeploy previous git commit
git checkout <previous-commit>
./deploy.sh lab-server 192.168.1.50
```

## Troubleshooting

### SSH connection issues
- Ensure `monibahmed` user exists on target
- Check SSH service is running: `systemctl status sshd`
- Verify network connectivity: `ping <target-ip>`

### Build failures
- Check flake.nix syntax: `nix flake check`
- Verify configuration: `nix build .#nixosConfigurations.lab-server.config.system.build.toplevel`
- Review logs: `journalctl -xe`

### Permission issues
- Ensure monibahmed is in wheel group
- Check sudo configuration on target

## Testing

This project includes a QEMU-based testing framework that boots real NixOS VMs to verify configurations.

### Quick Test Commands

```bash
# Run all tests
./run-tests.sh

# Run a specific test
./run-tests.sh basic-health-test

# List available tests
./run-tests.sh list

# Start interactive VM for manual testing
./run-tests.sh interactive
```

### Using Nix Directly

```bash
# Check all configurations and run tests
nix flake check

# Run specific test
nix build .#checks.x86_64-linux.basic-health-test

# Start interactive test VM
nix run .#test-vm
```

### Available Tests

| Test | Description |
|------|-------------|
| `basic-health-test` | Verifies base configuration, services, and packages |
| `lab-server-test` | Tests lab server with PostgreSQL and dev tools |
| `ssh-connectivity-test` | Tests SSH between two VMs |

### CI/CD Integration

Tests run automatically on push and pull requests via GitHub Actions. The workflow:

1. Checks flake syntax
2. Validates all configurations can build
3. Runs QEMU-based VM tests

See [tests/README.md](tests/README.md) for detailed testing documentation.

## Requirements

### On Host (deployment machine)
- Nix with flakes enabled
- Network access to targets
- This git repository cloned

### On Target (machines being deployed to)
- NixOS installed (minimal is fine)
- SSH enabled
- User `monibahmed` with sudo access

## Future Enhancements

- Binary cache for faster deployments
- Automatic target discovery
- ~~Health checks and monitoring~~ ✅ Implemented via QEMU tests
- Secrets management with agenix
- Deployment notifications
