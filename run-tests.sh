#!/usr/bin/env bash
set -euo pipefail

# NixOS QEMU-based test runner
# Runs automated tests using NixOS VM testing framework

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}==>${NC} $1"
}

print_error() {
    echo -e "${RED}Error:${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}Warning:${NC} $1"
}

print_info() {
    echo -e "${BLUE}Info:${NC} $1"
}

# Check if running from git repository
if [ ! -f "flake.nix" ]; then
    print_error "Must be run from the nixos-config repository root"
    exit 1
fi

# Check if nix is available
if ! command -v nix &> /dev/null; then
    print_error "Nix is not installed. Please install Nix first."
    print_info "Visit: https://nixos.org/download.html"
    exit 1
fi

# Check if flakes are enabled
if ! nix flake --help &> /dev/null; then
    print_error "Nix flakes are not enabled."
    print_info "Add 'experimental-features = nix-command flakes' to your nix.conf"
    exit 1
fi

# Parse arguments
TEST_NAME=${1:-all}
VERBOSE=${VERBOSE:-false}

show_usage() {
    echo "Usage: $0 [test-name|all|list|interactive]"
    echo ""
    echo "Commands:"
    echo "  all          Run all tests (default)"
    echo "  list         List available tests"
    echo "  interactive  Start an interactive test VM"
    echo "  <test-name>  Run a specific test"
    echo ""
    echo "Available tests:"
    echo "  basic-health-test     - Test basic system configuration"
    echo "  lab-server-test       - Test lab server configuration"
    echo "  ssh-connectivity-test - Test SSH connectivity between VMs"
    echo ""
    echo "Options:"
    echo "  VERBOSE=true ./run-tests.sh  - Show verbose output"
    echo ""
    echo "Examples:"
    echo "  $0                           # Run all tests"
    echo "  $0 basic-health-test         # Run only basic health test"
    echo "  $0 list                      # List available tests"
    echo "  $0 interactive               # Start interactive VM for manual testing"
}

list_tests() {
    print_status "Available tests:"
    echo ""
    nix flake show --json 2>/dev/null | jq -r '.checks."x86_64-linux" | keys[]' 2>/dev/null || {
        # Fallback if jq not available
        echo "  - basic-health-test"
        echo "  - lab-server-test"
        echo "  - ssh-connectivity-test"
    }
}

run_test() {
    local test_name=$1
    print_status "Running test: $test_name"
    
    local start_time=$(date +%s)
    
    if [ "$VERBOSE" = "true" ]; then
        nix build ".#checks.x86_64-linux.${test_name}" --print-build-logs
    else
        nix build ".#checks.x86_64-linux.${test_name}"
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    print_status "Test '$test_name' passed in ${duration}s"
}

run_all_tests() {
    print_status "Running all tests..."
    echo ""
    
    local failed=0
    local passed=0
    local tests=("basic-health-test" "lab-server-test" "ssh-connectivity-test")
    
    for test in "${tests[@]}"; do
        if run_test "$test"; then
            ((passed++))
        else
            print_error "Test '$test' failed"
            ((failed++))
        fi
        echo ""
    done
    
    echo ""
    print_status "Test results: $passed passed, $failed failed"
    
    if [ $failed -gt 0 ]; then
        exit 1
    fi
}

run_interactive() {
    print_status "Starting interactive test VM..."
    print_info "You can log in with user 'monibahmed' and password 'changeme'"
    print_info "Press Ctrl+A X to exit QEMU"
    echo ""
    
    nix run .#test-vm
}

# Main logic
case "$TEST_NAME" in
    -h|--help|help)
        show_usage
        ;;
    list)
        list_tests
        ;;
    all)
        run_all_tests
        ;;
    interactive)
        run_interactive
        ;;
    *)
        run_test "$TEST_NAME"
        ;;
esac
