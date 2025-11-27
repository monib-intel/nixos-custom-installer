# Media center specific configuration
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

  # Enable X11/Wayland for media playback
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

  # Media center specific services
  services = {
    # Plex Media Server
    plex = {
      enable = true;
      openFirewall = true;
    };
  };

  # Open firewall for media services
  networking.firewall = {
    allowedTCPPorts = [
      8096   # Jellyfin
      32400  # Plex
    ];
    allowedUDPPorts = [
      1900   # DLNA
      7359   # Jellyfin discovery
    ];
  };

  # Media center specific packages
  environment.systemPackages = with pkgs; [
    # Media players
    vlc
    mpv

    # Media tools
    ffmpeg
    yt-dlp

    # Remote control support
    kodi
  ];

  # Network configuration for this target
  networking = {
    useDHCP = lib.mkDefault true;
    # For static IP, uncomment and configure:
    # interfaces.eth0 = {
    #   useDHCP = false;
    #   ipv4.addresses = [{
    #     address = "192.168.1.75";
    #     prefixLength = 24;
    #   }];
    # };
    # defaultGateway = "192.168.1.1";
    # nameservers = [ "8.8.8.8" "8.8.4.4" ];
  };
}
