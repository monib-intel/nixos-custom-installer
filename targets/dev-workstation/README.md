# Development Workstation Target

This configuration is designed for a development workstation with a full desktop environment.

## Features

- GNOME desktop environment
- VS Code and Neovim editors
- Docker container support
- Multiple programming languages (Python, Node.js, Go, Rust)
- Build tools and compilers
- Modern CLI utilities (ripgrep, fd, bat, eza)

## Hardware Requirements

- x86_64 architecture
- UEFI boot support
- At least 16GB RAM recommended
- Graphics card with driver support
- Network connectivity

## Initial Setup

1. Install minimal NixOS from USB/ISO
2. Run hardware detection:
   ```bash
   nixos-generate-config --show-hardware-config > hardware-configuration.nix
   ```
3. Copy hardware-configuration.nix to this directory
4. Uncomment the import in configuration.nix
5. Deploy from any host:
   ```bash
   ./deploy.sh dev-workstation <ip-address>
   ```

## Customization

Edit `configuration.nix` to:
- Add additional development tools
- Configure IDE settings
- Add language-specific packages
- Enable additional services

## Post-Deployment

After first deployment:
1. Login as monibahmed
2. Change initial password: `passwd`
3. Configure Git:
   ```bash
   git config --global user.name "Monib Ahmed"
   git config --global user.email "your@email.com"
   ```
4. Setup SSH keys for GitHub/GitLab
5. Add additional GNOME extensions as needed
