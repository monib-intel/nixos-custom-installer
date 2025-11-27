{
  description = "NixOS configurations for local network deployment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations = {
      # Lab server configuration
      lab-server = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./targets/common/base.nix
          ./targets/common/users.nix
          ./targets/lab-server/configuration.nix
          { networking.hostName = "lab-server"; }
        ];
      };

      # Development workstation configuration
      dev-workstation = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./targets/common/base.nix
          ./targets/common/users.nix
          ./targets/dev-workstation/configuration.nix
          { networking.hostName = "dev-workstation"; }
        ];
      };

      # Media center configuration
      media-center = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./targets/common/base.nix
          ./targets/common/users.nix
          ./targets/media-center/configuration.nix
          { networking.hostName = "media-center"; }
        ];
      };
    };
  };
}
