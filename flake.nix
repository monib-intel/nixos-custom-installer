{
  description = "NixOS configurations for local network deployment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      lib = nixpkgs.lib;

      # Test password used in QEMU VM tests (not a security concern - isolated test environment)
      testPassword = "testpassword";
    in
    {
      nixosConfigurations = {
        # Lab server configuration
        lab-server = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./targets/common/base.nix
            ./targets/common/users.nix
            ./targets/lab-server/configuration.nix
            { networking.hostName = "lab-server"; }
          ];
        };

        # Development workstation configuration
        dev-workstation = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./targets/common/base.nix
            ./targets/common/users.nix
            ./targets/dev-workstation/configuration.nix
            { networking.hostName = "dev-workstation"; }
          ];
        };

        # Media center configuration
        media-center = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./targets/common/base.nix
            ./targets/common/users.nix
            ./targets/media-center/configuration.nix
            { networking.hostName = "media-center"; }
          ];
        };

        # Test VM configuration - optimized for QEMU testing
        test-vm = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./targets/common/base.nix
            ./targets/common/users.nix
            ({ config, pkgs, lib, ... }: {
              networking.hostName = "test-vm";

              # Minimal boot configuration for VM
              boot.loader.grub.enable = false;
              boot.loader.systemd-boot.enable = false;

              # Use tmpfs for root in VM
              fileSystems."/" = lib.mkForce {
                device = "none";
                fsType = "tmpfs";
                options = [ "defaults" "size=2G" "mode=755" ];
              };
            })
          ];
        };
      };

      # QEMU-based tests - run with `nix flake check` or `nix build .#checks.x86_64-linux.<test-name>`
      checks.${system} = {
        # Basic health test - tests common base configuration
        basic-health-test = pkgs.testers.nixosTest {
          name = "basic-health-test";
          
          nodes.machine = { config, pkgs, lib, ... }: {
            imports = [
              ./targets/common/base.nix
              ./targets/common/users.nix
            ];

            virtualisation = {
              memorySize = 1024;
              cores = 2;
              graphics = false;
            };
          };

          testScript = ''
            machine.start()
            machine.wait_for_unit("multi-user.target")

            # Test SSH service
            machine.succeed("systemctl is-active sshd.service")

            # Test NetworkManager
            machine.succeed("systemctl is-active NetworkManager.service")

            # Test user setup
            machine.succeed("id monibahmed")
            machine.succeed("groups monibahmed | grep -q wheel")

            # Test essential packages
            machine.succeed("which vim")
            machine.succeed("which git")
            machine.succeed("which htop")
            machine.succeed("which tmux")
            machine.succeed("which curl")
            machine.succeed("which wget")

            # Test Nix flakes
            machine.succeed("nix --version")

            # Test firewall
            machine.succeed("systemctl is-active firewall.service")

            # Test timezone
            machine.succeed("timedatectl | grep -q 'America/Los_Angeles'")

            print("All basic health checks passed!")
          '';
        };

                # Lab server test
        lab-server-test = pkgs.testers.nixosTest {
          name = "lab-server-test";
          
          nodes.machine = { config, pkgs, lib, ... }: {
            imports = [
              ./targets/common/base.nix
              ./targets/common/users.nix
              ./targets/lab-server/configuration.nix
            ];

            networking.hostName = "lab-server";

            virtualisation = {
              memorySize = 2048;
              cores = 2;
              graphics = false;
              diskSize = 4096;
            };

            fileSystems = lib.mkForce {
              "/" = {
                device = "none";
                fsType = "tmpfs";
                options = [ "defaults" "size=2G" "mode=755" ];
              };
            };
          };

          testScript = ''
            machine.start()
            machine.wait_for_unit("multi-user.target")

            # Verify hostname
            result = machine.succeed("hostname").strip()
            assert result == "lab-server", f"Expected hostname 'lab-server', got '{result}'"

            # Verify SSH
            machine.succeed("systemctl is-active sshd.service")

            # Verify PostgreSQL
            machine.wait_for_unit("postgresql.service")
            machine.succeed("systemctl is-active postgresql.service")

            # Verify lab packages
            machine.succeed("which python3")
            machine.succeed("which gcc")
            machine.succeed("which cmake")
            machine.succeed("which gdb")

            # Verify Python numpy
            machine.succeed("python3 -c 'import numpy; print(numpy.__version__)'")

            print("All lab-server tests passed!")
          '';
        };

        # SSH connectivity test between two VMs
        # Note: Uses testPassword defined in flake let-binding for test isolation
        ssh-connectivity-test = pkgs.testers.nixosTest {
          name = "ssh-connectivity-test";

          nodes = {
            server = { config, pkgs, lib, ... }: {
              imports = [
                ./targets/common/base.nix
                ./targets/common/users.nix
              ];

              networking.hostName = "server";

              virtualisation = {
                memorySize = 512;
                cores = 1;
                graphics = false;
              };

              services.openssh.settings.PasswordAuthentication = true;
              # Test password for isolated VM testing only
              users.users.monibahmed.password = testPassword;
            };

            client = { config, pkgs, lib, ... }: {
              virtualisation = {
                memorySize = 512;
                cores = 1;
                graphics = false;
              };

              environment.systemPackages = with pkgs; [
                openssh
                sshpass
              ];
            };
          };

          testScript = ''
            server.start()
            client.start()

            server.wait_for_unit("multi-user.target")
            client.wait_for_unit("multi-user.target")

            server.wait_for_unit("sshd.service")

            # Test SSH port
            server.succeed("ss -tlnp | grep -q ':22'")

            # Test SSH connectivity (password is for isolated VM test environment only)
            server_ip = server.succeed("hostname -I").strip().split()[0]

            client.succeed(
                f"sshpass -p '${testPassword}' ssh -o StrictHostKeyChecking=no monibahmed@{server_ip} 'echo connected'"
            )

            # Verify command execution
            result = client.succeed(
                f"sshpass -p '${testPassword}' ssh -o StrictHostKeyChecking=no monibahmed@{server_ip} 'hostname'"
            ).strip()
            assert result == "server", f"Expected 'server', got '{result}'"

            print("All SSH connectivity tests passed!")
          '';
        };
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          git
          nixpkgs-fmt
          nil
        ];

        shellHook = ''
          echo "Welcome to the NixOS configuration development shell!"
        '';
      };

      # Provide a convenient way to run a test VM interactively
      # Run with: nix run .#test-vm
      apps.${system} = {
        test-vm = {
          type = "app";
          program = "${self.nixosConfigurations.test-vm.config.system.build.vm}/bin/run-test-vm-vm";
        };
      };
    };
}
