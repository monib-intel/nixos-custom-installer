# Lab server specific test
# Tests the lab-server configuration in a QEMU VM
{ pkgs, lib, ... }:

pkgs.nixosTest {
  name = "lab-server-test";

  nodes.machine = { config, pkgs, ... }: {
    imports = [
      ../targets/common/base.nix
      ../targets/common/users.nix
      ../targets/lab-server/configuration.nix
    ];

    networking.hostName = "lab-server";

    # VM-specific settings for QEMU testing
    virtualisation = {
      memorySize = 2048;
      cores = 2;
      graphics = false;
      # Don't require a real disk
      diskSize = 4096;
    };

    # Override file systems for VM testing
    # The test framework provides its own root filesystem
    fileSystems = lib.mkForce {
      "/" = {
        device = "none";
        fsType = "tmpfs";
        options = [ "defaults" "size=2G" "mode=755" ];
      };
    };
  };

  testScript = ''
    # Wait for the machine to boot
    machine.start()
    machine.wait_for_unit("multi-user.target")

    # Basic service checks
    machine.succeed("systemctl is-active sshd.service")

    # Test 1: Verify hostname is set correctly
    result = machine.succeed("hostname")
    assert "lab-server" in result, f"Hostname should be lab-server, got {result}"

    # Test 2: Verify PostgreSQL is enabled
    machine.wait_for_unit("postgresql.service")
    machine.succeed("systemctl is-active postgresql.service")

    # Test 3: Verify lab-specific packages are installed
    machine.succeed("which python3")
    machine.succeed("which gcc")
    machine.succeed("which cmake")
    machine.succeed("which gdb")

    # Test 4: Verify Python with numpy is available
    machine.succeed("python3 -c 'import numpy; print(numpy.__version__)'")

    print("All lab-server tests passed!")
  '';
}
