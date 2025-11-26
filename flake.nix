{
  description = "Custom NixOS installation media";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations = {
      installer = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          ./modules/installer.nix
          {
            # Add custom packages to the installer
            environment.systemPackages = with nixpkgs.legacyPackages.x86_64-linux; [
              vim
              git
              wget
              curl
              htop
              tmux
            ];
            
            # Enable SSH for remote installation
            services.openssh.enable = true;
            
            # Set a default password for easier access
            users.users.nixos.initialPassword = "nixos";
          }
        ];
      };
    };
  };
}