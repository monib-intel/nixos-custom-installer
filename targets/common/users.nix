# User configuration for all targets
{ config, pkgs, ... }: {
  users.users.monibahmed = {
    isNormalUser = true;
    description = "Monib Ahmed";
    extraGroups = [
      "wheel"           # For sudo access
      "networkmanager"  # Network configuration
      "audio"           # Audio access
      "video"           # Video device access
    ];
    shell = pkgs.bash;

    # SSH keys for deployment access
    openssh.authorizedKeys.keys = [
      # Add SSH public keys here
      # "ssh-ed25519 AAAAC3... monibahmed@hostname"
    ];

    # Initial password for bootstrap only
    # Remove after SSH keys are configured
    initialPassword = "changeme";
  };

  # Sudo configuration
  security.sudo = {
    wheelNeedsPassword = true;  # Set to false for passwordless sudo
  };
}
