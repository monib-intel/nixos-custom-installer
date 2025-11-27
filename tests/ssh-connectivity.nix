# SSH connectivity test
# Verifies that SSH authentication and connections work correctly
{ pkgs, lib, ... }:

pkgs.nixosTest {
  name = "ssh-connectivity-test";

  nodes = {
    # Server node - the target machine
    server = { config, pkgs, ... }: {
      imports = [
        ../targets/common/base.nix
        ../targets/common/users.nix
      ];

      networking.hostName = "server";

      virtualisation = {
        memorySize = 512;
        cores = 1;
        graphics = false;
      };

      # Enable password authentication for testing
      services.openssh.settings.PasswordAuthentication = true;

      # Set a known password for testing
      users.users.monibahmed.password = "testpassword";
    };

    # Client node - the deployment machine
    client = { config, pkgs, ... }: {
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
    # Start both machines
    server.start()
    client.start()

    # Wait for both to be ready
    server.wait_for_unit("multi-user.target")
    client.wait_for_unit("multi-user.target")

    # Wait for SSH service
    server.wait_for_unit("sshd.service")

    # Test 1: Verify SSH port is listening
    server.succeed("ss -tlnp | grep -q ':22'")

    # Test 2: Test SSH connectivity from client to server
    # First, get server's IP address
    server_ip = server.succeed("hostname -I").strip().split()[0]

    # Test password-based SSH connection using sshpass
    client.succeed(
        f"sshpass -p 'testpassword' ssh -o StrictHostKeyChecking=no monibahmed@{server_ip} 'echo connected'"
    )

    # Test 3: Verify user can execute commands via SSH
    result = client.succeed(
        f"sshpass -p 'testpassword' ssh -o StrictHostKeyChecking=no monibahmed@{server_ip} 'hostname'"
    )
    assert "server" in result, f"Expected hostname 'server', got {result}"

    # Test 4: Verify sudo access works via SSH
    result = client.succeed(
        f"sshpass -p 'testpassword' ssh -o StrictHostKeyChecking=no monibahmed@{server_ip} 'echo testpassword | sudo -S whoami'"
    )
    assert "root" in result, f"Expected sudo to return 'root', got {result}"

    print("All SSH connectivity tests passed!")
  '';
}
