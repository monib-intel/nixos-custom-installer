# Common services configuration module
{ config, pkgs, lib, ... }: {
  # SSH service (typically already in base)
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Automatic updates
  system.autoUpgrade = {
    enable = false;  # Set to true for automatic updates
    allowReboot = false;
  };

  # Garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Avahi for mDNS (hostname.local discovery)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      domain = true;
      hinfo = true;
      userServices = true;
      workstation = true;
    };
  };

  # Enable fail2ban for SSH protection
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "10m";
    bantime-increment = {
      enable = true;
      maxtime = "48h";
    };
  };

  # Enable NTP for time synchronization
  services.timesyncd.enable = true;

  # Tailscale VPN (optional)
  # services.tailscale.enable = true;

  # Monitoring tools
  environment.systemPackages = with pkgs; [
    htop
    btop
    iotop
    nethogs
    ncdu
  ];
}
