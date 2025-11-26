{ config, pkgs, ... }:

{
  # Installer-specific configuration
  
  # Networking - Explicitly disable NetworkManager and use wpa_supplicant
  networking.networkmanager.enable = pkgs.lib.mkForce false;
  
  # Use wpa_supplicant for pre-configured WiFi auto-connect
  networking.wireless = {
    enable = true;
    networks = {
      "ahmsa" = {
        psk = "89423546";
      };
    };
  };
  
  # Locale and timezone
  time.timeZone = "America/Los_Angeles";  # PST/PDT
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
    # WiFi utilities
    networkmanagerapplet
    wirelesstools
  ];
}