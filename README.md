# NixOS Installer

This project provides a set of configurations and scripts for generating installation media for NixOS. It includes the necessary files to customize the installation process and ensure a smooth setup.

## Project Structure

- **configuration.nix**: Main configuration file for the NixOS installation, defining system settings, services, and packages.
- **hardware-configuration.nix**: Contains hardware-specific configurations generated during the installation process.
- **flake.nix**: Defines the Nix flake for building the installation media, specifying inputs and outputs.
- **flake.lock**: Locks the versions of inputs specified in `flake.nix` for reproducibility.
- **modules/**: Contains reusable base configurations and installation-specific modules.
  - **base.nix**: Base configurations and modules.
  - **installer.nix**: Configurations and functions related to the NixOS installation process.
- **overlays/**: Defines overlays to modify or extend the Nix package set.
  - **default.nix**: Custom package versions or additional packages.
- **scripts/**: Automation scripts for building and testing the installation media.
  - **build-iso.sh**: Automates the ISO building process.
  - **test-vm.sh**: Sets up a virtual machine to test the installation media.

## Prerequisites

Install Nix on macOS:
```bash
sh <(curl -L https://nixos.org/nix/install)
```

## Usage

### Building the ISO

**Method 1: Using the build script**
```bash
./scripts/build-iso.sh
```

**Method 2: Direct nix build**
```bash
nix build .#nixosConfigurations.installer.config.system.build.isoImage
```

**Important Note:** Building on macOS (especially ARM/M-series Macs) requires cross-compilation to x86_64-linux. This process will take 1-2 hours and download several GB of dependencies.

The generated ISO will be named `nixos-custom-installer.iso`.

### Writing to USB Drive

**On macOS:**
```bash
diskutil list  # Find your USB drive (e.g., /dev/disk2)
diskutil unmountDisk /dev/diskX
sudo dd if=nixos-custom-installer.iso of=/dev/rdiskX bs=4m status=progress
```

**On Linux:**
```bash
sudo dd if=nixos-custom-installer.iso of=/dev/sdX bs=4M status=progress
```

### Testing in VM
```bash
./scripts/test-vm.sh
```

## Default Credentials

- **Username:** `nixos`
- **Password:** `nixos`

## Customization

Edit `modules/installer.nix` to customize:
- Timezone and locale settings
- Additional packages for the installer
- Network configuration
- SSH and other services

## Features

- Based on NixOS minimal installation CD
- Pre-configured with useful tools: vim, git, wget, curl, htop, tmux, parted, cryptsetup
- SSH enabled for remote installation
- NetworkManager for easy network configuration
- Flakes and nix-command experimental features enabled

## Contributing

Contributions are welcome! Please submit a pull request or open an issue for any enhancements or bug fixes.

## License

This project is licensed under the MIT License. See the LICENSE file for more details.