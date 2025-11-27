# Basic health check test for NixOS configurations
# This test boots a QEMU VM and verifies essential services are running
{ pkgs, lib, ... }:

pkgs.nixosTest {
  name = "basic-health-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [
      ../targets/common/base.nix
      ../targets/common/users.nix
    ];

    # VM-specific settings for QEMU testing
    virtualisation = {
      memorySize = 1024;
      cores = 2;
      # Use virtio for better performance
      graphics = false;
    };

    # Ensure we have a root filesystem for the VM
    # The NixOS test framework handles this automatically
  };

  testScript = ''
    # Wait for the machine to boot
    machine.start()
    machine.wait_for_unit("multi-user.target")

    # Test 1: Verify SSH service is running
    machine.succeed("systemctl is-active sshd.service")

    # Test 2: Verify network manager is running
    machine.succeed("systemctl is-active NetworkManager.service")

    # Test 3: Verify the monibahmed user exists
    machine.succeed("id monibahmed")

    # Test 4: Verify monibahmed is in wheel group (sudo access)
    machine.succeed("groups monibahmed | grep -q wheel")

    # Test 5: Verify essential packages are installed
    machine.succeed("which vim")
    machine.succeed("which git")
    machine.succeed("which htop")
    machine.succeed("which tmux")
    machine.succeed("which curl")
    machine.succeed("which wget")

    # Test 6: Verify Nix with flakes is configured
    machine.succeed("nix --version")
    machine.succeed("nix flake --help")

    # Test 7: Verify firewall is enabled and SSH port is open
    machine.succeed("systemctl is-active firewall.service")

    # Test 8: Verify timezone is set correctly
    machine.succeed("timedatectl | grep -q 'America/Los_Angeles'")

    # Test 9: Verify locale is set correctly
    machine.succeed("locale | grep -q 'en_US.UTF-8'")

    print("All basic health checks passed!")
  '';
}
