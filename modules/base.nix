{ config, pkgs, ... }:

{
  # Base system configuration for monibahmed
  
  # User configuration
  users.users.monibahmed = {
    isNormalUser = true;
    home = "/home/monibahmed";
    description = "Monib Ahmed";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.bash;
    # Set a proper password using: passwd monibahmed after installation
  };
  
  # Hostname
  networking.hostName = "monib-server";
  
  # Timezone
  time.timeZone = "America/Los_Angeles";  # PST/PDT
  
  # Networking
  networking.networkmanager.enable = true;
  
  # Firewall configuration
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];  # SSH only for now
  };
  
  # Enable sudo for wheel group
  security.sudo.wheelNeedsPassword = true;
  
  # Basic system packages for server and development
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
    # VS Code SSH remote development dependencies
    nodejs
    python3
    gcc
    gnumake
    openssh
  ];
  
  # Enable common services
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
  
  # Programs needed for VS Code Remote SSH
  programs.bash.enableCompletion = true;
  programs.git.enable = true;
}