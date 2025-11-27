# Desktop environment configuration module
{ config, pkgs, lib, ... }: {
  # Enable X11/Wayland for desktop environment
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  # Audio configuration with PipeWire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Desktop packages
  environment.systemPackages = with pkgs; [
    # Browsers
    firefox
    chromium

    # Office
    libreoffice

    # Media
    vlc
    mpv

    # Communication
    slack
    discord

    # Utilities
    gnome.gnome-tweaks
    gnome-extension-manager
  ];

  # Enable printing
  services.printing.enable = true;

  # Fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    jetbrains-mono
  ];
}
