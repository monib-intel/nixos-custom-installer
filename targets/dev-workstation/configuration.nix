# Development workstation specific configuration
{ config, pkgs, ... }: {
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

  # Enable X11/Wayland for desktop environment
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  # Audio configuration
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Development workstation specific packages
  environment.systemPackages = with pkgs; [
    # Editors and IDEs
    vscode
    neovim

    # Version control
    git
    gh

    # Languages and runtimes
    python3
    python3Packages.pip
    nodejs
    go
    rustup

    # Build tools
    gcc
    gnumake
    cmake

    # Containers
    docker
    docker-compose

    # Utilities
    jq
    ripgrep
    fd
    bat
    eza
  ];

  # Enable Docker
  virtualisation.docker.enable = true;
  users.users.monibahmed.extraGroups = [ "docker" ];

  # Network configuration for this target
  networking = {
    useDHCP = lib.mkDefault true;
    # For static IP, uncomment and configure:
    # interfaces.eth0 = {
    #   useDHCP = false;
    #   ipv4.addresses = [{
    #     address = "192.168.1.60";
    #     prefixLength = 24;
    #   }];
    # };
    # defaultGateway = "192.168.1.1";
    # nameservers = [ "8.8.8.8" "8.8.4.4" ];
  };
}
