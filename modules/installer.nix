{ config, pkgs, ... }:

{
  # Installer-specific configuration
  
  # Networking
  networking.wireless.enable = false;
  networking.networkmanager.enable = true;
  
  # Locale and timezone
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";
  
  # Console configuration
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };
  
  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # Additional useful packages for installation
  environment.systemPackages = with pkgs; [
    parted
    gptfdisk
    cryptsetup
  ];
}