# Lab Server Target

This configuration is designed for a lab/research server.

## Features

- PostgreSQL database server
- Python development environment
- GCC and build tools
- Debugging tools (gdb)

## Hardware Requirements

- x86_64 architecture
- UEFI boot support
- At least 8GB RAM recommended
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
   ./deploy.sh lab-server <ip-address>
   ```

## Customization

Edit `configuration.nix` to:
- Add specific services for your lab needs
- Configure static IP if required
- Add additional packages

## Network Configuration

Default: DHCP

For static IP, edit configuration.nix and uncomment the static IP section:
```nix
networking.interfaces.eth0 = {
  useDHCP = false;
  ipv4.addresses = [{
    address = "192.168.1.50";
    prefixLength = 24;
  }];
};
```
