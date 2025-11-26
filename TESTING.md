# Testing Guide for N### ✅ User Login
- [ ] Login prompt appears
- [ ] Login as `monibahmed` with password `changeme1@`
- [ ] User has proper shell (bash)
- [ ] User can use sudo without passwordCustom Installer

## Quick Test Workflow

### 1. Build the ISO
```bash
./scripts/build-iso.sh
```

### 2. Test in QEMU VM
```bash
./scripts/test-vm.sh
```

## What to Test

### ✅ Boot Process
- [ ] ISO boots successfully
- [ ] No boot errors
- [ ] Reaches login prompt

### ✅ User Login
- [ ] System auto-logs in as `monibahmed`
- [ ] User has proper shell (bash)
- [ ] User can use sudo without password
- [ ] Password is `changeme` (test with `su - monibahmed`)

### ✅ Network (if WiFi configured)
- [ ] WiFi auto-connects (if wifi-config.nix enabled)
- [ ] Get IP address: `ip addr show`
- [ ] Test internet: `ping -c 3 google.com`

### ✅ Network (manual setup)
```bash
# List WiFi networks
nmcli device wifi list

# Connect to WiFi
nmcli device wifi connect "SSID" password "PASSWORD"

# Verify connection
nmcli connection show
ip addr show
```

### ✅ SSH Access
From your host machine (when using QEMU test script):
```bash
ssh -p 2222 monibahmed@localhost
```

From another machine (if on same network):
```bash
ssh monibahmed@<VM_IP>
```

### ✅ Installed Packages
Test that all essential tools are available:
```bash
vim --version
git --version
htop --version
tmux -V
curl --version
wget --version
python3 --version
node --version
gcc --version
```

### ✅ System Tools
```bash
# Disk partitioning tools
parted --version

# System info
htop

# File management
tree --version
unzip -v
```

### ✅ Development Environment
```bash
# Check if git is configured
git config --list

# Test tmux
tmux new -s test
# Exit: Ctrl+B then D

# Check compiler
gcc --version
make --version
```

## QEMU Testing Tips

### Port Forwarding
The test script forwards port 2222 to VM's port 22:
```bash
ssh -p 2222 monibahmed@localhost
```

### Exit QEMU
Press: `Ctrl+A` then `X`

### Performance
If VM is slow, make sure KVM is enabled (Linux only):
```bash
# Check KVM support
lsmod | grep kvm
```

On macOS, QEMU runs without KVM (slower but functional).

### Network Testing
QEMU uses user-mode networking by default:
- Internet access works
- VM gets internal IP (10.0.2.x)
- Can SSH via port forwarding: `-p 2222`

## VirtualBox Testing

### Network Setup
1. Adapter 1: Bridged Adapter (for WiFi testing)
   - OR -
2. Adapter 1: NAT + Port Forwarding (Host: 2222 → Guest: 22)

### Guest Additions
Not needed for basic testing, but can be installed later if needed.

## Physical Hardware Testing

### Writing to USB
```bash
# macOS
diskutil list
diskutil unmountDisk /dev/diskX
sudo dd if=nixos-custom-installer.iso of=/dev/rdiskX bs=4m status=progress

# Linux
lsblk
sudo dd if=nixos-custom-installer.iso of=/dev/sdX bs=4M status=progress
```

### BIOS/UEFI
- Make sure Secure Boot is disabled
- Boot from USB
- Test on actual hardware

## Common Issues

### WiFi not connecting
- Check `wifi-config.nix` has correct SSID/password
- Verify `./wifi-config.nix` is uncommented in `flake.nix`
- Check `networking.wireless.enable = true` in `installer.nix`

### SSH connection refused
- Verify VM has network: `ip addr show`
- Check SSH is running: `systemctl status sshd`
- Test locally first: `ssh monibahmed@localhost` (on VM)

### Can't login
- Username: `monibahmed`
- Password: `changeme1@`
- Caps lock off? Password is case-sensitive
- Check user exists: Boot to recovery and check /etc/passwd

### Missing packages
- Check if package exists: `nix search nixpkgs <package>`
- Add to `environment.systemPackages` in `modules/base.nix`
- Rebuild ISO

## Success Criteria

✅ **Minimum Requirements:**
- Boots successfully
- Can login as monibahmed
- Network connectivity works
- SSH access works
- All essential packages present

✅ **Ready for Production:**
- All above tests pass
- WiFi auto-connects (if configured)
- VS Code SSH connects successfully
- Password changed from default
- Can install NixOS to disk

## Next Steps After Testing

1. Change default password: `passwd monibahmed`
2. Configure additional services (WebDAV, etc.)
3. Install to physical disk
4. Set up your development environment
