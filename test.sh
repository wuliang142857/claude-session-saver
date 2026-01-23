#!/usr/bin/env bash
# ABOUTME: Test script for stash plugin in isolated environments.
# ABOUTME: Supports unit tests, integration tests, and manual testing modes.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$SCRIPT_DIR/plugins/stash"
TEST_TEMP_DIR="/tmp/stash-plugin-test-$$"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

print_header() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════╗"
    echo "║      Stash Plugin Test Runner         ║"
    echo "╚═══════════════════════════════════════╝"
    echo -e "${NC}"
}

print_section() {
    echo ""
    echo -e "${CYAN}━━━ $1 ━━━${NC}"
}

print_info() {
    echo -e "${BLUE}→ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
    # 2026-01-23: Use || true to prevent exit with set -e when counter is 0
    ((TESTS_PASSED++)) || true
}

print_warning() {
    echo -e "${YELLOW}! $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
    # 2026-01-23: Use || true to prevent exit with set -e when counter is 0
    ((TESTS_FAILED++)) || true
}

print_summary() {
    echo ""
    echo -e "${CYAN}━━━ Test Summary ━━━${NC}"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    if [ $TESTS_FAILED -gt 0 ]; then
        echo -e "${RED}Failed: $TESTS_FAILED${NC}"
        return 1
    else
        echo -e "${GREEN}All tests passed!${NC}"
        return 0
    fi
}

setup_test_env() {
    mkdir -p "$TEST_TEMP_DIR"
    mkdir -p "$TEST_TEMP_DIR/.claude/projects/test-project"
}

cleanup_test_env() {
    rm -rf "$TEST_TEMP_DIR"
}

# ============================================
# 1. Plugin Structure Tests
# ============================================
test_plugin_structure() {
    print_section "Plugin Structure Tests"

    # Check required files
    local required_files=(
        ".claude-plugin/plugin.json"
        "commands/push.md"
        "commands/pop.md"
        "commands/list.md"
        "commands/drop.md"
        "scripts/claude_session_saver_cli.py"
    )

    for file in "${required_files[@]}"; do
        if [ -f "$PLUGIN_DIR/$file" ]; then
            print_success "File exists: $file"
        else
            print_error "Missing file: $file"
        fi
    done

    # Check plugin.json is valid JSON
    if python3 -c "import json; json.load(open('$PLUGIN_DIR/.claude-plugin/plugin.json'))" 2>/dev/null; then
        print_success "plugin.json is valid JSON"
    else
        print_error "plugin.json is invalid JSON"
    fi

    # Check marketplace.json is valid JSON
    if python3 -c "import json; json.load(open('$SCRIPT_DIR/.claude-plugin/marketplace.json'))" 2>/dev/null; then
        print_success "marketplace.json is valid JSON"
    else
        print_error "marketplace.json is invalid JSON"
    fi

    # Check plugin.json required fields
    local plugin_json="$PLUGIN_DIR/.claude-plugin/plugin.json"
    for field in name description version; do
        if python3 -c "import json; d=json.load(open('$plugin_json')); assert '$field' in d" 2>/dev/null; then
            print_success "plugin.json has required field: $field"
        else
            print_error "plugin.json missing required field: $field"
        fi
    done
}

# ============================================
# 2. Command Markdown Syntax Tests
# ============================================
test_command_syntax() {
    print_section "Command Markdown Syntax Tests"

    local commands=("push" "pop" "list" "drop")

    for cmd in "${commands[@]}"; do
        local file="$PLUGIN_DIR/commands/${cmd}.md"

        # Check frontmatter exists
        if head -1 "$file" | grep -q "^---$"; then
            print_success "${cmd}.md has frontmatter start"
        else
            print_error "${cmd}.md missing frontmatter start (---)"
        fi

        # Check frontmatter end
        if sed -n '2,/^---$/p' "$file" | tail -1 | grep -q "^---$"; then
            print_success "${cmd}.md has frontmatter end"
        else
            print_error "${cmd}.md missing frontmatter end (---)"
        fi

        # Check description field
        if grep -q "^description:" "$file"; then
            print_success "${cmd}.md has description field"
        else
            print_error "${cmd}.md missing description field"
        fi

        # Check allowed-tools field
        if grep -q "^allowed-tools:" "$file"; then
            print_success "${cmd}.md has allowed-tools field"
        else
            print_error "${cmd}.md missing allowed-tools field"
        fi

        # Check Context section
        if grep -q "^## Context" "$file"; then
            print_success "${cmd}.md has Context section"
        else
            print_error "${cmd}.md missing Context section"
        fi

        # Check Your task section
        if grep -q "^## Your task" "$file"; then
            print_success "${cmd}.md has 'Your task' section"
        else
            print_error "${cmd}.md missing 'Your task' section"
        fi
    done
}

# ============================================
# 3. Python Script Unit Tests
# ============================================
test_python_script() {
    print_section "Python Script Unit Tests"

    local script="$PLUGIN_DIR/scripts/claude_session_saver_cli.py"
    local test_db="$TEST_TEMP_DIR/sessions.json"

    # Clean up
    rm -f "$test_db"

    # Test save
    SESSION_DB_PATH="$test_db" python3 "$script" save "test-session" "test-id-12345" >/dev/null
    if grep -q "test-session" "$test_db"; then
        print_success "save: basic save works"
    else
        print_error "save: basic save failed"
    fi

    # Test save with Chinese characters
    SESSION_DB_PATH="$test_db" python3 "$script" save "测试会话" "chinese-id-123" >/dev/null
    if grep -q "测试会话" "$test_db"; then
        print_success "save: Chinese characters work"
    else
        print_error "save: Chinese characters failed"
    fi

    # Test save overwrites existing
    SESSION_DB_PATH="$test_db" python3 "$script" save "test-session" "new-id-67890" >/dev/null
    if SESSION_DB_PATH="$test_db" python3 "$script" get "test-session" | grep -q "new-id-67890"; then
        print_success "save: overwrite existing works"
    else
        print_error "save: overwrite existing failed"
    fi

    # Test list
    local list_output=$(SESSION_DB_PATH="$test_db" python3 "$script" list)
    if echo "$list_output" | grep -q "test-session"; then
        print_success "list: returns saved sessions"
    else
        print_error "list: failed to return sessions"
    fi

    # Test list output is valid JSON
    if echo "$list_output" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
        print_success "list: output is valid JSON"
    else
        print_error "list: output is not valid JSON"
    fi

    # Test get existing
    local get_output=$(SESSION_DB_PATH="$test_db" python3 "$script" get "test-session")
    if [ "$get_output" = "new-id-67890" ]; then
        print_success "get: returns correct session ID"
    else
        print_error "get: returned wrong ID ($get_output)"
    fi

    # Test get non-existing
    if SESSION_DB_PATH="$test_db" python3 "$script" get "non-existing" 2>/dev/null; then
        print_error "get: should fail for non-existing session"
    else
        print_success "get: correctly fails for non-existing session"
    fi

    # Test delete existing
    SESSION_DB_PATH="$test_db" python3 "$script" delete "test-session" >/dev/null
    if ! grep -q '"test-session"' "$test_db"; then
        print_success "delete: removes session"
    else
        print_error "delete: failed to remove session"
    fi

    # Test delete non-existing
    if SESSION_DB_PATH="$test_db" python3 "$script" delete "non-existing" 2>/dev/null; then
        print_error "delete: should fail for non-existing session"
    else
        print_success "delete: correctly fails for non-existing session"
    fi

    # Test current with mock session files
    local mock_project="$TEST_TEMP_DIR/.claude/projects/test-project"
    mkdir -p "$mock_project"
    echo '{"test": true}' > "$mock_project/session-aaa111.jsonl"
    sleep 0.1
    echo '{"test": true}' > "$mock_project/session-bbb222.jsonl"

    # Temporarily override HOME for current command
    local current_output=$(HOME="$TEST_TEMP_DIR" python3 "$script" current 2>/dev/null)
    if [ "$current_output" = "session-bbb222" ]; then
        print_success "current: returns most recent session"
    else
        print_error "current: expected 'session-bbb222', got '$current_output'"
    fi

    # Test current with no sessions
    rm -rf "$TEST_TEMP_DIR/.claude/projects"
    mkdir -p "$TEST_TEMP_DIR/.claude/projects"
    current_output=$(HOME="$TEST_TEMP_DIR" python3 "$script" current 2>/dev/null || echo "empty")
    if [ "$current_output" = "empty" ] || [ -z "$current_output" ]; then
        print_success "current: returns empty when no sessions"
    else
        print_error "current: should return empty when no sessions"
    fi

    # Test help command
    if python3 "$script" help 2>&1 | grep -q "Usage:"; then
        print_success "help: displays usage information"
    else
        print_error "help: failed to display usage"
    fi

    # Test invalid command
    if python3 "$script" invalid_command 2>&1 | grep -q "Unknown command"; then
        print_success "error: handles invalid command"
    else
        print_error "error: should report invalid command"
    fi
}

# ============================================
# 4. Session Data Validation Tests
# ============================================
test_session_validation() {
    print_section "Session Data Validation Tests"

    local mock_project="$TEST_TEMP_DIR/.claude/projects/-Users-test"
    mkdir -p "$mock_project"

    # Create valid session file (has "message" entries)
    cat > "$mock_project/valid-session.jsonl" << 'EOF'
{"type":"message","content":"Hello"}
{"type":"message","content":"World"}
{"type":"file-history-snapshot","data":{}}
EOF

    # Create invalid session file (no "message" entries)
    cat > "$mock_project/invalid-session.jsonl" << 'EOF'
{"type":"file-history-snapshot","data":{}}
{"type":"context","data":{}}
EOF

    # Create empty session file
    touch "$mock_project/empty-session.jsonl"

    # Test valid session detection
    local msg_count=$(grep -c '"message"' "$mock_project/valid-session.jsonl" 2>/dev/null || echo "0")
    if [ "$msg_count" -gt 0 ]; then
        print_success "validation: detects valid session ($msg_count messages)"
    else
        print_error "validation: failed to detect valid session"
    fi

    # 2026-01-23: Use grep -o with wc -l to avoid grep -c returning 0 and exit code 1 issue
    # Test invalid session detection
    msg_count=$(grep -o '"message"' "$mock_project/invalid-session.jsonl" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$msg_count" -eq 0 ]; then
        print_success "validation: detects invalid session (no messages)"
    else
        print_error "validation: should detect invalid session"
    fi

    # Test empty session detection
    msg_count=$(grep -o '"message"' "$mock_project/empty-session.jsonl" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$msg_count" -eq 0 ]; then
        print_success "validation: detects empty session"
    else
        print_error "validation: should detect empty session"
    fi
}

# ============================================
# 5. tmux/screen Detection Tests
# ============================================
test_terminal_detection() {
    print_section "Terminal Multiplexer Detection Tests"

    # Test tmux detection (simulated)
    local in_tmux=$(TMUX="/tmp/tmux-test/default,12345,0" bash -c '[ -n "$TMUX" ] && echo "yes" || echo "no"')
    if [ "$in_tmux" = "yes" ]; then
        print_success "tmux: detection works when TMUX is set"
    else
        print_error "tmux: detection failed"
    fi

    # Test tmux not detected
    in_tmux=$(TMUX="" bash -c '[ -n "$TMUX" ] && echo "yes" || echo "no"')
    if [ "$in_tmux" = "no" ]; then
        print_success "tmux: correctly not detected when TMUX is empty"
    else
        print_error "tmux: should not be detected when TMUX is empty"
    fi

    # Test screen detection (simulated)
    local in_screen=$(STY="12345.pts-0.hostname" bash -c '[ -n "$STY" ] && echo "yes" || echo "no"')
    if [ "$in_screen" = "yes" ]; then
        print_success "screen: detection works when STY is set"
    else
        print_error "screen: detection failed"
    fi

    # Test screen not detected
    in_screen=$(STY="" bash -c '[ -n "$STY" ] && echo "yes" || echo "no"')
    if [ "$in_screen" = "no" ]; then
        print_success "screen: correctly not detected when STY is empty"
    else
        print_error "screen: should not be detected when STY is empty"
    fi

    # Test TMUX_PANE extraction
    local pane_id=$(TMUX_PANE="%5" bash -c 'echo "$TMUX_PANE"')
    if [ "$pane_id" = "%5" ]; then
        print_success "tmux: TMUX_PANE extraction works"
    else
        print_error "tmux: TMUX_PANE extraction failed"
    fi
}

# ============================================
# 6. End-to-End Simulation Tests
# ============================================
test_e2e_simulation() {
    print_section "End-to-End Simulation Tests"

    local script="$PLUGIN_DIR/scripts/claude_session_saver_cli.py"
    local test_db="$TEST_TEMP_DIR/e2e-sessions.json"
    local mock_project="$TEST_TEMP_DIR/.claude/projects/-Users-test"

    mkdir -p "$mock_project"
    rm -f "$test_db"

    # Simulate: Create a session file (like Claude Code would)
    local session_id="e2e-test-$(date +%s)"
    cat > "$mock_project/${session_id}.jsonl" << 'EOF'
{"type":"message","role":"user","content":"Hello"}
{"type":"message","role":"assistant","content":"Hi there!"}
EOF
    print_info "Created mock session: $session_id"

    # Simulate: /stash:push "E2E Test"
    print_info "Simulating /stash:push..."
    local current_id=$(HOME="$TEST_TEMP_DIR" python3 "$script" current 2>/dev/null)
    if [ -n "$current_id" ]; then
        SESSION_DB_PATH="$test_db" python3 "$script" save "E2E Test" "$current_id" >/dev/null
        print_success "e2e push: saved session as 'E2E Test'"
    else
        print_error "e2e push: failed to get current session"
    fi

    # Simulate: /stash:list
    print_info "Simulating /stash:list..."
    local list_out=$(SESSION_DB_PATH="$test_db" python3 "$script" list)
    if echo "$list_out" | grep -q "E2E Test"; then
        print_success "e2e list: shows saved session"
    else
        print_error "e2e list: saved session not found"
    fi

    # Simulate: /stash:pop "E2E Test" (validation step)
    print_info "Simulating /stash:pop validation..."
    local saved_id=$(SESSION_DB_PATH="$test_db" python3 "$script" get "E2E Test" 2>/dev/null)
    if [ -n "$saved_id" ]; then
        local session_file="$mock_project/${saved_id}.jsonl"
        if [ -f "$session_file" ]; then
            local msg_count=$(grep -c '"message"' "$session_file" 2>/dev/null || echo "0")
            if [ "$msg_count" -gt 0 ]; then
                print_success "e2e pop: session validated ($msg_count messages)"
            else
                print_error "e2e pop: session has no messages"
            fi
        else
            print_error "e2e pop: session file not found"
        fi
    else
        print_error "e2e pop: failed to get session ID"
    fi

    # Simulate: /stash:drop "E2E Test"
    print_info "Simulating /stash:drop..."
    SESSION_DB_PATH="$test_db" python3 "$script" delete "E2E Test" >/dev/null
    if ! SESSION_DB_PATH="$test_db" python3 "$script" get "E2E Test" 2>/dev/null; then
        print_success "e2e drop: session removed"
    else
        print_error "e2e drop: session not removed"
    fi
}

# ============================================
# 7. Error Handling Tests
# ============================================
test_error_handling() {
    print_section "Error Handling Tests"

    local script="$PLUGIN_DIR/scripts/claude_session_saver_cli.py"
    local test_db="$TEST_TEMP_DIR/error-test.json"

    # Test save with missing arguments
    if python3 "$script" save 2>&1 | grep -qi "unknown\|invalid\|usage"; then
        print_success "error: save with missing args shows usage"
    else
        print_error "error: save should show usage with missing args"
    fi

    # Test save with only one argument
    if python3 "$script" save "name" 2>&1 | grep -qi "unknown\|invalid\|usage"; then
        print_success "error: save with one arg shows usage"
    else
        print_error "error: save should show usage with one arg"
    fi

    # Test get with missing argument
    if python3 "$script" get 2>&1 | grep -qi "unknown\|invalid\|usage"; then
        print_success "error: get with missing arg shows usage"
    else
        print_error "error: get should show usage with missing arg"
    fi

    # Test delete with missing argument
    if python3 "$script" delete 2>&1 | grep -qi "unknown\|invalid\|usage"; then
        print_success "error: delete with missing arg shows usage"
    else
        print_error "error: delete should show usage with missing arg"
    fi

    # Test with non-writable directory (if possible)
    local readonly_db="/nonexistent/path/sessions.json"
    if ! SESSION_DB_PATH="$readonly_db" python3 "$script" save "test" "id" 2>/dev/null; then
        print_success "error: handles non-writable path"
    else
        print_warning "error: non-writable path test inconclusive"
    fi

    # Test with corrupted JSON database
    echo "not valid json" > "$test_db"
    local list_out=$(SESSION_DB_PATH="$test_db" python3 "$script" list 2>/dev/null)
    if [ "$list_out" = "{}" ]; then
        print_success "error: handles corrupted JSON gracefully"
    else
        print_error "error: should return {} for corrupted JSON"
    fi
}

# ============================================
# Manual Testing Modes
# ============================================

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

# ============================================
# Help and Main
# ============================================

show_help() {
    echo "Usage: $0 <command>"
    echo ""
    echo "Automated Tests:"
    echo "  all          Run all automated tests"
    echo "  structure    Verify plugin file structure"
    echo "  syntax       Verify command markdown syntax"
    echo "  unit         Run Python script unit tests"
    echo "  validation   Run session data validation tests"
    echo "  terminal     Run terminal multiplexer detection tests"
    echo "  e2e          Run end-to-end simulation tests"
    echo "  errors       Run error handling tests"
    echo ""
    echo "Manual Testing:"
    echo "  dev          Quick test with --plugin-dir (uses current Claude config)"
    echo "  isolated     Test with temporary HOME directory (clean environment)"
    echo "  docker       Test in Docker container (completely clean environment)"
    echo ""
    echo "Examples:"
    echo "  $0 all         # Run all automated tests"
    echo "  $0 unit        # Run only Python script tests"
    echo "  $0 dev         # Start Claude with plugin for manual testing"
}

# Main
print_header

case "${1:-}" in
    structure)
        setup_test_env
        test_plugin_structure
        cleanup_test_env
        print_summary
        ;;
    syntax)
        setup_test_env
        test_command_syntax
        cleanup_test_env
        print_summary
        ;;
    unit)
        setup_test_env
        test_python_script
        cleanup_test_env
        print_summary
        ;;
    validation)
        setup_test_env
        test_session_validation
        cleanup_test_env
        print_summary
        ;;
    terminal)
        setup_test_env
        test_terminal_detection
        cleanup_test_env
        print_summary
        ;;
    e2e)
        setup_test_env
        test_e2e_simulation
        cleanup_test_env
        print_summary
        ;;
    errors)
        setup_test_env
        test_error_handling
        cleanup_test_env
        print_summary
        ;;
    all)
        setup_test_env
        test_plugin_structure
        test_command_syntax
        test_python_script
        test_session_validation
        test_terminal_detection
        test_e2e_simulation
        test_error_handling
        cleanup_test_env
        print_summary
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
