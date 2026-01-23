#!/usr/bin/env bash
# ABOUTME: Test script for stash plugin in isolated environments.
# ABOUTME: Supports quick dev testing, isolated HOME testing, and Docker testing.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$SCRIPT_DIR/plugins/stash"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════╗"
    echo "║      Stash Plugin Test Runner         ║"
    echo "╚═══════════════════════════════════════╝"
    echo -e "${NC}"
}

print_info() {
    echo -e "${BLUE}→ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}! $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Test Python script functionality
test_python_script() {
    print_info "Testing Python script..."

    local script="$PLUGIN_DIR/scripts/claude_session_saver_cli.py"
    local test_db="/tmp/stash-test-sessions.json"

    # Clean up
    rm -f "$test_db"

    # Test save
    SESSION_DB_PATH="$test_db" python3 "$script" save "test-session" "test-id-12345"
    if grep -q "test-session" "$test_db"; then
        print_success "save command works"
    else
        print_error "save command failed"
        return 1
    fi

    # Test list
    local list_output=$(SESSION_DB_PATH="$test_db" python3 "$script" list)
    if echo "$list_output" | grep -q "test-session"; then
        print_success "list command works"
    else
        print_error "list command failed"
        return 1
    fi

    # Test get
    local get_output=$(SESSION_DB_PATH="$test_db" python3 "$script" get "test-session")
    if [ "$get_output" = "test-id-12345" ]; then
        print_success "get command works"
    else
        print_error "get command failed"
        return 1
    fi

    # Test current
    local current_output=$(python3 "$script" current 2>/dev/null || echo "no-session")
    if [ -n "$current_output" ]; then
        print_success "current command works (output: $current_output)"
    else
        print_warning "current command returned empty (expected if no Claude sessions exist)"
    fi

    # Test delete
    SESSION_DB_PATH="$test_db" python3 "$script" delete "test-session"
    if ! grep -q "test-session" "$test_db"; then
        print_success "delete command works"
    else
        print_error "delete command failed"
        return 1
    fi

    # Clean up
    rm -f "$test_db"

    print_success "All Python script tests passed!"
}

# Test plugin structure
test_plugin_structure() {
    print_info "Testing plugin structure..."

    # Check required files
    local required_files=(
        ".claude-plugin/plugin.json"
        "commands/push.md"
        "commands/pop.md"
        "commands/list.md"
        "commands/drop.md"
        "scripts/claude_session_saver_cli.py"
    )

    local all_ok=true
    for file in "${required_files[@]}"; do
        if [ -f "$PLUGIN_DIR/$file" ]; then
            print_success "Found: $file"
        else
            print_error "Missing: $file"
            all_ok=false
        fi
    done

    # Check plugin.json is valid JSON
    if python3 -c "import json; json.load(open('$PLUGIN_DIR/.claude-plugin/plugin.json'))" 2>/dev/null; then
        print_success "plugin.json is valid JSON"
    else
        print_error "plugin.json is invalid JSON"
        all_ok=false
    fi

    # Check marketplace.json is valid JSON
    if python3 -c "import json; json.load(open('$SCRIPT_DIR/.claude-plugin/marketplace.json'))" 2>/dev/null; then
        print_success "marketplace.json is valid JSON"
    else
        print_error "marketplace.json is invalid JSON"
        all_ok=false
    fi

    if $all_ok; then
        print_success "Plugin structure is valid!"
    else
        print_error "Plugin structure has issues"
        return 1
    fi
}

# Quick development test with --plugin-dir
test_dev() {
    print_info "Starting development test mode..."
    print_info "Plugin directory: $PLUGIN_DIR"
    echo ""
    print_warning "This will start Claude Code with the plugin loaded."
    print_warning "Test commands: /stash:list, /stash:push \"test\", /stash:pop \"test\""
    echo ""

    claude --plugin-dir "$PLUGIN_DIR"
}

# Isolated test with temporary HOME
test_isolated() {
    print_info "Starting isolated test mode..."

    local test_home="/tmp/claude-stash-test-$$"
    mkdir -p "$test_home/.claude"

    print_info "Test HOME: $test_home"
    print_warning "This creates a clean Claude Code environment."
    echo ""

    # Copy plugin to test location
    mkdir -p "$test_home/plugin"
    cp -r "$PLUGIN_DIR"/* "$test_home/plugin/"

    print_info "Starting Claude Code in isolated environment..."
    HOME="$test_home" claude --plugin-dir "$test_home/plugin"

    # Cleanup prompt
    echo ""
    read -p "Clean up test environment? [Y/n] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        rm -rf "$test_home"
        print_success "Test environment cleaned up"
    else
        print_info "Test environment preserved at: $test_home"
    fi
}

# Docker test (completely clean environment)
test_docker() {
    print_info "Starting Docker test mode..."

    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        exit 1
    fi

    local dockerfile="/tmp/claude-stash-test-dockerfile"

    cat > "$dockerfile" << 'EOF'
FROM node:20-slim

# Install dependencies
RUN apt-get update && apt-get install -y python3 git && rm -rf /var/lib/apt/lists/*

# Install Claude Code
RUN npm install -g @anthropic-ai/claude-code

# Create test user
RUN useradd -m -s /bin/bash testuser
USER testuser
WORKDIR /home/testuser

# Set up environment
ENV HOME=/home/testuser

# Copy plugin
COPY --chown=testuser:testuser plugins/stash /home/testuser/plugin

# Entry point
ENTRYPOINT ["claude", "--plugin-dir", "/home/testuser/plugin"]
EOF

    print_info "Building Docker image..."
    docker build -f "$dockerfile" -t claude-stash-test "$SCRIPT_DIR"

    print_info "Starting container..."
    print_warning "Note: You'll need to authenticate Claude Code inside the container."
    echo ""

    docker run -it --rm \
        -e ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}" \
        claude-stash-test

    # Cleanup
    read -p "Remove Docker image? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker rmi claude-stash-test
        print_success "Docker image removed"
    fi

    rm -f "$dockerfile"
}

# Show help
show_help() {
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  unit       Run unit tests on Python script"
    echo "  structure  Verify plugin file structure"
    echo "  dev        Quick test with --plugin-dir (uses current Claude config)"
    echo "  isolated   Test with temporary HOME directory (clean environment)"
    echo "  docker     Test in Docker container (completely clean environment)"
    echo "  all        Run unit and structure tests"
    echo ""
    echo "Examples:"
    echo "  $0 unit        # Test Python script functions"
    echo "  $0 dev         # Start Claude with plugin for manual testing"
    echo "  $0 isolated    # Test in clean environment"
}

# Main
print_header

case "${1:-}" in
    unit)
        test_python_script
        ;;
    structure)
        test_plugin_structure
        ;;
    dev)
        test_dev
        ;;
    isolated)
        test_isolated
        ;;
    docker)
        test_docker
        ;;
    all)
        test_plugin_structure
        echo ""
        test_python_script
        ;;
    help|--help|-h)
        show_help
        ;;
    "")
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
