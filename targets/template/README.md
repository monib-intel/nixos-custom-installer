# Target Configuration Template

This is a template for creating new target configurations.

## Creating a New Target

1. Copy this entire directory:
   ```bash
   cp -r targets/template targets/your-target-name
   ```

2. Edit `configuration.nix` with your target-specific settings

3. Generate hardware configuration on the target machine:
   ```bash
   nixos-generate-config --show-hardware-config > hardware-configuration.nix
   ```
   Then copy this file to your target directory.

4. Add the target to `flake.nix`:
   ```nix
   nixosConfigurations = {
     your-target-name = nixpkgs.lib.nixosSystem {
       system = "x86_64-linux";
       modules = [
         ./targets/common/base.nix
         ./targets/common/users.nix
         ./targets/your-target-name/configuration.nix
         { networking.hostName = "your-target-name"; }
       ];
     };
   };
   ```

5. Add to inventory.txt:
   ```
   your-target-name:192.168.1.XX
   ```

6. Deploy:
   ```bash
   ./deploy.sh your-target-name 192.168.1.XX
   ```

## Configuration Sections

### Boot Loader
Configure based on your boot method:
- UEFI: `boot.loader.systemd-boot.enable = true;`
- Legacy BIOS: `boot.loader.grub.enable = true;`

### File Systems
Required! Must match your actual disk layout.
Run `nixos-generate-config` to get correct values.

### Services
Add services specific to this target's purpose.

### Packages
Add packages needed for this target's workload.

### Network
Configure DHCP or static IP as needed.
