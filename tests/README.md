# NixOS QEMU-Based Testing Framework

This directory contains automated tests for the NixOS deployment system. Tests are run using the NixOS VM testing framework, which uses QEMU to boot actual NixOS systems and verify their configuration.

## Overview

The testing framework provides:

- **QEMU-based VM tests**: Each test boots a real NixOS VM using QEMU
- **Automated health checks**: Verify services, packages, and configurations
- **Multi-VM tests**: Test interactions between systems (e.g., SSH connectivity)
- **CI/CD integration**: Tests can be run in GitHub Actions or other CI systems

## Running Tests

### Prerequisites

- Nix with flakes enabled
- Linux system with KVM support (for best performance)

### Run All Tests

```bash
# From repository root
./run-tests.sh

# Or using nix directly
nix flake check
```

### Run Specific Tests

```bash
# Run a specific test
./run-tests.sh basic-health-test
./run-tests.sh lab-server-test
./run-tests.sh ssh-connectivity-test

# Or using nix
nix build .#checks.x86_64-linux.basic-health-test
```

### List Available Tests

```bash
./run-tests.sh list
```

### Interactive Testing

Start an interactive VM for manual testing:

```bash
./run-tests.sh interactive

# Or using nix
nix run .#test-vm
```

Login credentials for interactive VM:
- Username: `monibahmed`
- Password: `changeme`

## Available Tests

### basic-health-test

Tests the common base configuration shared by all targets:

- SSH service is running
- NetworkManager is active
- User `monibahmed` exists with correct groups
- Essential packages are installed (vim, git, htop, tmux, curl, wget)
- Nix flakes are enabled
- Firewall is active
- Timezone and locale are configured

### lab-server-test

Tests the lab server specific configuration:

- All basic health checks
- PostgreSQL service is running
- Development packages installed (Python, GCC, CMake, GDB)
- Python numpy is available
- Hostname is correctly set

### ssh-connectivity-test

Tests SSH connectivity between two VMs:

- Server VM with SSH enabled
- Client VM connecting to server
- Password authentication works
- Remote command execution
- User authentication

## Writing New Tests

### Basic Test Structure

```nix
pkgs.nixosTest {
  name = "my-test";
  
  nodes.machine = { config, pkgs, lib, ... }: {
    imports = [
      # Import modules to test
      ../targets/common/base.nix
    ];
    
    # VM-specific settings
    virtualisation = {
      memorySize = 1024;
      cores = 2;
      graphics = false;
    };
  };
  
  testScript = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")
    
    # Your test assertions
    machine.succeed("systemctl is-active sshd.service")
    
    print("Test passed!")
  '';
}
```

### Multi-VM Test

```nix
pkgs.nixosTest {
  name = "multi-vm-test";
  
  nodes = {
    server = { ... }: {
      # Server configuration
    };
    client = { ... }: {
      # Client configuration
    };
  };
  
  testScript = ''
    server.start()
    client.start()
    
    server.wait_for_unit("multi-user.target")
    client.wait_for_unit("multi-user.target")
    
    # Test interactions between VMs
  '';
}
```

### Test Script Commands

The test script is Python code with these machine methods:

- `machine.start()` - Boot the VM
- `machine.wait_for_unit("service.target")` - Wait for systemd unit
- `machine.succeed("command")` - Run command, fail if exit code != 0
- `machine.fail("command")` - Run command, fail if exit code == 0
- `machine.wait_until_succeeds("command")` - Retry until success
- `machine.shutdown()` - Shutdown the VM

## Adding Tests to the Flake

To add a new test, add it to the `checks` attribute in `flake.nix`:

```nix
checks.x86_64-linux = {
  # Existing tests...
  
  my-new-test = pkgs.nixosTest {
    # Test configuration
  };
};
```

## CI/CD Integration

### GitHub Actions

Tests can be run in GitHub Actions using the provided workflow:

```yaml
- name: Run NixOS VM tests
  run: nix flake check
```

The workflow is defined in `.github/workflows/test.yml`.

### Requirements for CI

- GitHub runner with Nix installed
- KVM support for faster VM execution (optional but recommended)
- Adequate memory (at least 4GB recommended)

## Troubleshooting

### Tests are slow

- Enable KVM support on your host
- Increase VM memory if tests timeout
- Run tests in parallel (each test is independent)

### "Permission denied" for KVM

```bash
# Add user to kvm group
sudo usermod -aG kvm $USER
# Log out and back in
```

### Flake check fails

```bash
# Check flake syntax
nix flake check --no-build

# Build specific test with verbose output
nix build .#checks.x86_64-linux.basic-health-test -L
```

### VM doesn't boot

- Check virtualisation settings in test config
- Ensure fileSystems is properly configured for VM
- Increase memory if OOM occurs

## Test Results

Test results are available as build outputs:

```bash
# After running a test
cat result/test-script
cat result/log
```

For verbose output during test execution:

```bash
VERBOSE=true ./run-tests.sh basic-health-test

# Or
nix build .#checks.x86_64-linux.basic-health-test --print-build-logs
```
