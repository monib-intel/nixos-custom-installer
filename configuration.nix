{ 
  "imports": [ 
    ./hardware-configuration.nix 
  ], 
  "boot.loader.grub.device": "/dev/sda", 
  "fileSystems.root": { 
    "device": "/dev/disk/by-uuid/your-root-uuid", 
    "fsType": "ext4" 
  }, 
  "networking.hostName": "nixos", 
  "networking.networks." : { 
    "eth0": { 
      "dhcp": true 
    } 
  }, 
  "services.openssh.enable": true, 
  "environment.systemPackages": with pkgs; [ 
    vim 
    git 
    wget 
  ], 
  "system.stateVersion": "22.05" 
}