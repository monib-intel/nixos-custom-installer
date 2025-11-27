# Base system configuration shared by all targets
{ config, pkgs, lib, ... }: {
  # System state version - set appropriately for your NixOS version
  system.stateVersion = "23.11";

  # Nix daemon configuration
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
  };

  # Essential services
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;  # Set to false after SSH keys are configured
      PermitRootLogin = "no";
    };
  };

  # Network configuration
  networking = {
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];  # SSH
    };
  };

  # Basic packages all systems need
  environment.systemPackages = with pkgs; [
    vim
    git
    htop
    tmux
    wget
    curl
  ];

  # Time and locale
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  # Console configuration
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };
}
