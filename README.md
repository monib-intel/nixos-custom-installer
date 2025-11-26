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

The installer includes two users:

- **User:**
  - **Username:** `monibahmed`
  - **Password:** `changeme1@`
  - **Groups:** wheel
  - **Privileges:** sudo access without password (installer convenience)
  - **Note:** Manual login required for security

**Important:** After installation, change the password using:
```bash
passwd monibahmed
```

## Network Setup

### WiFi Configuration

**Option 1: Pre-configure WiFi (Recommended for Personal Use)**

1. Edit `wifi-config.nix` and add your WiFi credentials:
   ```nix
   networking.wireless.networks = {
     "Your_SSID" = {
       psk = "your_password";
     };
   };
   ```

2. Uncomment the wifi-config import in `flake.nix`:
   ```nix
   ./wifi-config.nix
   ```

3. **Note**: `wifi-config.nix` is gitignored and won't be committed to version control

**Option 2: Manual WiFi Setup After Boot**

After booting the installer, connect to WiFi using NetworkManager:

```bash
# List available WiFi networks
nmcli device wifi list

# Connect to a WiFi network
nmcli device wifi connect "YOUR_SSID" password "YOUR_PASSWORD"

# Check connection status
nmcli connection show

# Get your IP address
ip addr show
```

### SSH Access

Once connected to your network:

1. Find your IP address: `ip addr show` (look for your WiFi interface, usually `wlan0` or `wlp*`)
2. From another machine: `ssh monibahmed@<IP_ADDRESS>`
3. Password: `changeme` (change this immediately!)

**Note**: SSH is enabled by default on boot. Make sure to change the default password for security!

## Testing the ISO

### Option 1: Test in QEMU (Recommended for Quick Testing)

```bash
./scripts/test-vm.sh
```

This will:
- Create a virtual machine with QEMU
- Boot from the ISO
- Forward SSH port 2222 → 22 (VM)
- Allow testing without writing to physical media

**During VM testing:**
- Check boot process
- Test WiFi commands (if configured)
- Test SSH: `ssh -p 2222 monibahmed@localhost`
- Verify all packages are installed
- Exit QEMU: Press `Ctrl+A` then `X`

**Requirements:**
- macOS: `brew install qemu`
- Linux: `sudo apt install qemu-system-x86` (Debian/Ubuntu)

### Option 2: Test in VirtualBox

1. Open VirtualBox
2. Create new VM (Type: Linux, Version: Other Linux 64-bit)
3. Settings → Storage → Add optical drive → Select ISO
4. Settings → Network → Adapter 1 → Bridged Adapter
5. Start VM and test

### Option 3: Test in VMware

1. Create new VM
2. Select "Install from disc image" → Browse to ISO
3. Configure network as Bridged
4. Start VM and test

### Option 4: Test on Physical Hardware

Write to USB and boot from it (see "Writing to USB Drive" section above)

## Customization

Edit `modules/installer.nix` to customize:
- Timezone and locale settings
- Additional packages for the installer
- Network configuration
- SSH and other services

Edit `modules/base.nix` to customize:
- User configuration for monibahmed
- System packages and services
- SSH settings and security options

## Features

- Based on NixOS minimal installation CD
- Pre-configured user: `monibahmed` with sudo privileges
- Optimized for home/webdav server with development support
- Pre-configured with essential tools: vim, git, wget, curl, htop, tmux, parted
- Development tools included: Node.js, Python3, GCC, make
- SSH enabled for remote installation and management
- VS Code Remote SSH ready (includes all required dependencies)
- NetworkManager for easy network configuration
- Flakes and nix-command experimental features enabled
- Security-hardened SSH (no root login, password authentication enabled)

## Contributing

Contributions are welcome! Please submit a pull request or open an issue for any enhancements or bug fixes.

## License

This project is licensed under the MIT License. See the LICENSE file for more details.