# Template configuration for new targets
# Copy this file to targets/<target-name>/configuration.nix
# and customize for your specific needs
{ config, pkgs, ... }: {
  # Hardware-specific imports
  imports = [
    # Include hardware scan results if available
    # Run: nixos-generate-config --show-hardware-config > hardware-configuration.nix
    # Then uncomment the line below:
    # ./hardware-configuration.nix
  ];

  # Boot configuration
  # Adjust based on your target's boot requirements
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # File systems (REQUIRED - adjust based on actual hardware)
  # Run nixos-generate-config on target to get correct values
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  # Target-specific services
  # Add services specific to this target's purpose
  services = {
    # Example services:
    # nginx.enable = true;
    # postgresql.enable = true;
  };

  # Target-specific packages
  environment.systemPackages = with pkgs; [
    # Add packages specific to this target
  ];

  # Network configuration for this target
  networking = {
    useDHCP = lib.mkDefault true;
    # For static IP, uncomment and configure:
    # interfaces.eth0 = {
    #   useDHCP = false;
    #   ipv4.addresses = [{
    #     address = "192.168.1.XX";  # Replace with actual IP
    #     prefixLength = 24;
    #   }];
    # };
    # defaultGateway = "192.168.1.1";
    # nameservers = [ "8.8.8.8" "8.8.4.4" ];
  };
}
