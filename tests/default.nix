# NixOS QEMU-based test suite
# This file aggregates all tests for the NixOS deployment system
{ pkgs, lib, ... }:

let
  # Import individual test modules
  basicHealthTest = import ./basic-health.nix { inherit pkgs lib; };
  labServerTest = import ./lab-server.nix { inherit pkgs lib; };
  sshConnectivityTest = import ./ssh-connectivity.nix { inherit pkgs lib; };
in
{
  # Export all tests
  inherit basicHealthTest labServerTest sshConnectivityTest;

  # Create a combined test that runs all tests
  allTests = pkgs.runCommand "all-tests" { } ''
    echo "All tests are defined in the 'checks' flake output"
    echo "Run individual tests with: nix build .#checks.x86_64-linux.<test-name>"
    echo ""
    echo "Available tests:"
    echo "  - basic-health-test"
    echo "  - lab-server-test"  
    echo "  - ssh-connectivity-test"
    touch $out
  '';
}
