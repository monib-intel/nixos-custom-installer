# NixOS Installation Guide - monibahmed Server

## Pre-Installation Setup

Your custom ISO includes:
- ✅ Auto-login as `monibahmed`
- ✅ WiFi auto-connects to "ahmsa"
- ✅ SSH enabled
- ✅ All development tools pre-installed

## Step 1: Boot from USB

1. Insert USB drive and boot from it
2. System will auto-login as `monibahmed`
3. WiFi should connect automatically (wait ~10 seconds)

## Step 2: Verify Network Connection

```bash
# Check WiFi connection
ip addr show

# Test internet
ping -c 3 nixos.org

# If WiFi didn't connect automatically:
sudo wpa_supplicant -B -i wlan0 -c <(wpa_passphrase "ahmsa" "89423546")
sudo dhcpcd wlan0
```

## Step 3: Partition Disk (Full Disk Usage)

⚠️ **WARNING: This will ERASE ALL DATA on /dev/sda**

```bash
# Identify your disk (usually /dev/sda or /dev/nvme0n1)
lsblk

# For standard SATA/SSD drives (/dev/sda):
export DISK=/dev/sda

# For NVMe drives, use:
# export DISK=/dev/nvme0n1

# Partition the disk (GPT, EFI boot + root)
sudo parted $DISK -- mklabel gpt
sudo parted $DISK -- mkpart ESP fat32 1MiB 512MiB
sudo parted $DISK -- set 1 esp on
sudo parted $DISK -- mkpart primary 512MiB 100%

# Format partitions
# For SATA/SSD (/dev/sda):
sudo mkfs.fat -F 32 -n boot ${DISK}1
sudo mkfs.ext4 -L nixos ${DISK}2

# For NVMe (/dev/nvme0n1):
# sudo mkfs.fat -F 32 -n boot ${DISK}p1
# sudo mkfs.ext4 -L nixos ${DISK}p2

# Mount filesystems
sudo mount /dev/disk/by-label/nixos /mnt
sudo mkdir -p /mnt/boot
sudo mount /dev/disk/by-label/boot /mnt/boot

# Verify mounts
df -h | grep /mnt
```

## Step 4: Generate Configuration

```bash
# Generate hardware configuration
sudo nixos-generate-config --root /mnt

# This creates:
# /mnt/etc/nixos/configuration.nix
# /mnt/etc/nixos/hardware-configuration.nix (auto-detected hardware)
```

## Step 5: Edit Configuration

```bash
# Edit the main configuration
sudo vim /mnt/etc/nixos/configuration.nix
```

Replace the contents with this minimal SSH-ready configuration:

```nix
{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix  # Auto-generated hardware config
  ];

  # Boot loader (UEFI)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Hostname
  networking.hostName = "monib-server";
  
  # Networking
  networking.networkmanager.enable = true;
  
  # Timezone
  time.timeZone = "America/Los_Angeles";

  # Locale
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # User account
  users.users.monibahmed = {
    isNormalUser = true;
    home = "/home/monibahmed";
    description = "Monib Ahmed";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.bash;
    # Password will be set after installation
  };

  # Sudo configuration
  security.sudo.wheelNeedsPassword = true;

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
    htop
    tmux
    tree
    unzip
    zip
    # Development tools for VS Code SSH
    nodejs
    python3
    gcc
    gnumake
    openssh
  ];

  # SSH Configuration
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
      # VS Code SSH requirements
      X11Forwarding = false;
      AllowTcpForwarding = true;
      PermitTunnel = true;
    };
  };

  # Firewall - SSH only
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];  # SSH
  };

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Git configuration
  programs.bash.enableCompletion = true;
  programs.git.enable = true;

  # This value determines the NixOS release with which your system is compatible
  # DON'T CHANGE THIS after installation!
  system.stateVersion = "24.11";
}
```

**Save and exit** (`:wq` in vim)

## Step 6: Install NixOS

```bash
# Start installation
sudo nixos-install

# You'll be prompted to set the root password
# Enter a secure password (you won't use this much, but keep it safe)
```

Installation will take 10-20 minutes depending on your hardware.

## Step 7: Reboot

```bash
# Reboot into your new system
reboot

# Remove USB drive when prompted
```

## Step 8: First Boot Configuration

After reboot:

1. **Login as monibahmed** (no password yet - will be prompted to create one)

2. **Set your password:**
   ```bash
   passwd
   # Enter a strong password
   ```

3. **Connect to WiFi:**
   ```bash
   nmcli device wifi list
   nmcli device wifi connect "ahmsa" password "89423546"
   ```

4. **Check network and get IP:**
   ```bash
   ip addr show
   # Note your IP address for SSH access
   ```

5. **Test SSH from another machine:**
   ```bash
   ssh monibahmed@<YOUR_IP_ADDRESS>
   ```

6. **Update system (optional but recommended):**
   ```bash
   sudo nixos-rebuild switch --upgrade
   ```

## Verification Checklist

After installation, verify:

- [ ] System boots successfully
- [ ] You can login as `monibahmed`
- [ ] WiFi connects automatically
- [ ] SSH works from remote machine
- [ ] Sudo requires password
- [ ] Firewall is active: `sudo iptables -L`
- [ ] All packages installed: `vim --version`, `git --version`, etc.
- [ ] VS Code SSH can connect (if testing)

## Troubleshooting

### WiFi not connecting after reboot
```bash
nmcli device wifi list
nmcli device wifi connect "ahmsa" password "89423546"
```

### Can't SSH - Connection refused
```bash
# On server:
sudo systemctl status sshd
sudo systemctl start sshd

# Check firewall:
sudo iptables -L | grep ssh
```

### Forgot password
Boot from installer USB and reset:
```bash
sudo mount /dev/disk/by-label/nixos /mnt
sudo nixos-enter --root /mnt
passwd monibahmed
exit
reboot
```

## Next Steps

After successful installation and SSH access:

1. **Configure WebDAV** (when ready)
2. **Set up Nginx** (when ready)
3. **Configure automatic backups**
4. **Set up development environment via VS Code SSH**
5. **Harden security** (SSH keys, fail2ban, etc.)

## Quick Reference

### Rebuild system after config changes:
```bash
sudo nixos-rebuild switch
```

### Upgrade system:
```bash
sudo nixos-rebuild switch --upgrade
```

### List installed packages:
```bash
nix-env -qa
```

### Check system state:
```bash
sudo systemctl status
```

---

**Installation Time:** ~30-45 minutes total
**Difficulty:** Intermediate
**Prerequisites:** Backup of important data, bootable USB ready
