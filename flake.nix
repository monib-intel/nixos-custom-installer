{
  description = "NixOS server deployment with custom installer";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, disko, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      # Main server configuration for deployment
      nixosConfigurations.server = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          disko.nixosModules.disko
          ./configuration.nix
          ./disko-config.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.monib = import ./home.nix;
          }
        ];
      };

      # Minimal installer ISO configuration
      nixosConfigurations.installer = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          ({ pkgs, lib, ... }: {
            # Enable SSH in the installer
            services.openssh = {
              enable = true;
              settings = {
                PermitRootLogin = "yes";
                PasswordAuthentication = false;
              };
            };

            # Add SSH key for root access during installation
            users.users.root.openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOcip7Kce5IxHRkxZIkW0h7qO5RifTMJ5q2jkasicRus ahmmo@Monib-Desktop"
            ];

            # Enable networking
            networking = {
              useDHCP = lib.mkForce true;
              wireless.enable = false;
            };

            # Include useful installation tools
            environment.systemPackages = with pkgs; [
              git
              vim
              curl
              wget
              parted
              gptfdisk
            ];

            # Set a hostname for the installer
            networking.hostName = "nixos-installer";

            # Enable nix flakes
            nix.settings.experimental-features = [ "nix-command" "flakes" ];

            # ISO image configuration
            isoImage = {
              makeEfiBootable = true;
              makeUsbBootable = true;
            };
          })
        ];
      };
    };
}
