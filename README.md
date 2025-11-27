# NixOS Server Setup

Automated NixOS server deployment using flakes, nixos-anywhere, and home-manager for a declarative, reproducible server configuration.

## Overview

This repository contains the complete configuration for deploying a NixOS server with:
- Automated installation via nixos-anywhere
- Declarative disk partitioning with disko
- User environment management with home-manager
- Remote development access via SSH/VS Code
- WebDAV and other services for PKM workflow

## Prerequisites

### On Your Local Machine
- Nix with flakes enabled
- SSH access configured
- Git for version control

### On Target Server
- Physical or remote access to boot a live environment
- For bare metal: USB drive or IPMI/iDRAC for ISO mounting
- For hosted: Provider's rescue mode
- Network connectivity

## Repository Structure

```
.
├── flake.nix                 # Main flake configuration
├── flake.lock               # Locked dependency versions
├── configuration.nix        # System-level configuration
├── hardware-configuration.nix # Hardware-specific settings
├── disko-config.nix         # Disk partitioning layout
├── home.nix                 # User environment (home-manager)
└── README.md                # This file
```

## Quick Start

### 1. Enable Flakes on Your Local Machine

```bash
# Add to ~/.config/nix/nix.conf or /etc/nix/nix.conf
experimental-features = nix-command flakes
```

### 2. Clone and Customize This Repository

```bash
git clone <your-repo-url>
cd nixos-server-config

# Edit configuration files:
# - configuration.nix: System settings, services, users
# - disko-config.nix: Disk layout
# - home.nix: User dotfiles and packages
```

### 3. Add Your SSH Key

```nix
# In configuration.nix
users.users.monib = {
  openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3... your-public-key"
  ];
};
```

### 4. Boot Target Server into Live Environment

**Option A: USB Boot (Home Lab)**
```bash
# Build custom installer ISO
nix build .#nixosConfigurations.installer.config.system.build.isoImage

# Write to USB
sudo dd if=result/iso/nixos-*.iso of=/dev/sdX bs=4M status=progress

# Boot target server from USB
```

**Option B: Remote Management (IPMI/iDRAC)**
- Access remote management interface
- Mount the built ISO as virtual media
- Boot from virtual media

**Option C: Hosting Provider Rescue Mode**
- Boot into provider's rescue system via control panel

### 5. Deploy with nixos-anywhere

Once the target is booted and accessible via SSH:

```bash
# From your local machine
nix run github:nix-community/nixos-anywhere -- \
  --flake .#your-server \
  root@<target-ip>
```

This will:
- Partition disks according to disko-config.nix
- Install NixOS with your configuration
- Set up home-manager for your user
- Reboot into the new system

### 6. Connect via VS Code

After installation completes:

```bash
# Test SSH connection
ssh monib@<server-ip>

# In VS Code:
# 1. Install "Remote - SSH" extension
# 2. Connect to: monib@<server-ip>
# 3. VS Code will auto-install its server components
```

## Configuration Files Explained

### flake.nix
Defines inputs (nixpkgs, home-manager, disko) and outputs (system configurations). This is the entry point for your entire system definition.

### configuration.nix
System-level settings:
- Network configuration
- Enabled services (SSH, WebDAV, etc.)
- User accounts
- Firewall rules
- System packages

### disko-config.nix
Declarative disk partitioning:
- Partition layout (EFI, swap, root)
- Filesystem types
- Mount points

### home.nix
User-level configuration via home-manager:
- Shell environment (zsh, bash)
- Development tools (git, neovim, etc.)
- Dotfiles and personal settings
- User packages

## Common Tasks

### Update System Configuration

```bash
# Edit configuration files
vim configuration.nix

# Test configuration locally (if on NixOS)
sudo nixos-rebuild test --flake .#your-server

# Deploy to remote server
nixos-rebuild switch --flake .#your-server \
  --target-host monib@<server-ip> \
  --use-remote-sudo
```

### Update Dependencies

```bash
# Update flake inputs
nix flake update

# Review changes
git diff flake.lock

# Deploy updated system
nixos-rebuild switch --flake .#your-server --target-host monib@<server-ip>
```

### Add New Service

```nix
# In configuration.nix
services.yourservice = {
  enable = true;
  # configuration options
};

# Open firewall if needed
networking.firewall.allowedTCPPorts = [ 8080 ];
```

### Rollback

NixOS keeps previous generations:

```bash
# SSH to server
ssh monib@<server-ip>

# List generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rollback to previous
sudo nixos-rebuild switch --rollback

# Or boot into specific generation via bootloader menu
```

## Troubleshooting

### nixos-anywhere fails with disk errors
Check disko-config.nix device paths match your target hardware. Boot into live environment and run `lsblk` to verify disk names.

### SSH connection refused after install
Verify firewall settings in configuration.nix allow SSH (port 22). Check that openssh.enable = true.

### VS Code remote connection issues
Ensure your user has proper shell and permissions. VS Code needs write access to ~/.vscode-server.

### Build fails with sandbox errors
Some ISO builds need `--option sandbox false`. Try without it first for security.

## Security Considerations

- Use SSH keys, not passwords
- Keep PermitRootLogin = "no"
- Configure firewall to only allow necessary ports
- Regularly update with `nix flake update`
- Review configuration changes before deploying

## Advanced Topics

### Multiple Machines
Define multiple configurations in flake.nix:

```nix
nixosConfigurations = {
  server1 = nixpkgs.lib.nixosSystem { ... };
  server2 = nixpkgs.lib.nixosSystem { ... };
};
```

### Secrets Management
Consider using sops-nix or agenix for managing secrets like passwords and API keys.

### Backup Strategy
NixOS configuration is in git, but data needs separate backup. Consider:
- Regular backups of /home and /var
- Automated backup services (restic, borg)
- Version control for configuration files

## Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [nixos-anywhere Documentation](https://github.com/nix-community/nixos-anywhere)
- [home-manager Manual](https://nix-community.github.io/home-manager/)
- [disko Documentation](https://github.com/nix-community/disko)
- [Nix Flakes](https://nixos.wiki/wiki/Flakes)

## Support

For issues specific to this configuration, open an issue in this repository.

For NixOS questions, consult the official documentation or community forums.
