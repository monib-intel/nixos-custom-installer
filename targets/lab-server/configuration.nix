# Lab server specific configuration
{ config, pkgs, lib, ... }: {
  # Hardware-specific imports
  imports = [
    # Include hardware scan results if available
    # ./hardware-configuration.nix
  ];

  # Boot configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # File systems (adjust based on actual hardware)
  # These are placeholder values - run nixos-generate-config on target for real values
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  # Lab server specific services
  services = {
    # Enable PostgreSQL for data storage
    postgresql = {
      enable = true;
      package = pkgs.postgresql_15;
    };
  };

  # Lab server specific packages
  environment.systemPackages = with pkgs; [
    python3
    python3Packages.pip
    python3Packages.numpy
    gcc
    gnumake
    cmake
    gdb
  ];

  # Network configuration for this target
  networking = {
    useDHCP = lib.mkDefault true;
    # For static IP, uncomment and configure:
    # interfaces.eth0 = {
    #   useDHCP = false;
    #   ipv4.addresses = [{
    #     address = "192.168.1.50";
    #     prefixLength = 24;
    #   }];
    # };
    # defaultGateway = "192.168.1.1";
    # nameservers = [ "8.8.8.8" "8.8.4.4" ];
  };
}
