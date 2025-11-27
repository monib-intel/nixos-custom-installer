# Media Center Target

This configuration is designed for a home media center/entertainment system.

## Features

- GNOME desktop environment (optimized for media)
- Plex Media Server
- VLC and MPV media players
- Kodi media center
- FFmpeg and yt-dlp for media management
- Audio via PipeWire

## Hardware Requirements

- x86_64 architecture
- UEFI boot support
- At least 8GB RAM recommended
- GPU with video acceleration (recommended)
- Large storage for media files
- Network connectivity

## Initial Setup

1. Install minimal NixOS from USB/ISO
2. Run hardware detection:
   ```bash
   nixos-generate-config --show-hardware-config > hardware-configuration.nix
   ```
3. Copy hardware-configuration.nix to this directory
4. Uncomment the import in configuration.nix
5. Deploy from any host:
   ```bash
   ./deploy.sh media-center <ip-address>
   ```

## Customization

Edit `configuration.nix` to:
- Configure Plex library paths
- Add Jellyfin as alternative to Plex
- Configure media storage mounts
- Enable hardware video acceleration

## Network Ports

The following ports are opened by default:
- 22 (SSH)
- 8096 (Jellyfin)
- 32400 (Plex)
- 1900/UDP (DLNA)
- 7359/UDP (Jellyfin discovery)

## Post-Deployment

1. Access Plex setup at http://media-center:32400/web
2. Configure media library locations
3. Set up remote access if needed
4. Configure transcoding settings based on hardware
