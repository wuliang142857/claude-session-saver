#!/usr/bin/env bash
# ABOUTME: Installation script for claude-session-saver plugin.
# ABOUTME: Supports install, update, and uninstall operations.

set -e

PLUGIN_NAME="claude-session-saver"
PLUGIN_DIR="$HOME/.claude/plugins/$PLUGIN_NAME"
COMMANDS_DIR="$HOME/.claude/commands"
REPO_URL="https://github.com/wuliang142857/claude-session-saver"
RAW_URL="https://raw.githubusercontent.com/wuliang142857/claude-session-saver/main"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_banner() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════╗"
    echo "║     Claude Session Saver Installer    ║"
    echo "╚═══════════════════════════════════════╝"
    echo -e "${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}→ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}! $1${NC}"
}

check_requirements() {
    print_info "Checking requirements..."

    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is required but not installed."
        exit 1
    fi
    print_success "Python 3 found"

    if ! command -v git &> /dev/null; then
        print_warning "Git not found. Will use curl for installation."
        return 1
    fi
    print_success "Git found"
    return 0
}

install_with_git() {
    print_info "Downloading plugin via git..."
    mkdir -p "$(dirname "$PLUGIN_DIR")"

    if [ -d "$PLUGIN_DIR" ]; then
        print_warning "Plugin directory exists, updating..."
        cd "$PLUGIN_DIR"
        git pull --ff-only
    else
        git clone --depth 1 "$REPO_URL.git" "$PLUGIN_DIR"
    fi
    print_success "Plugin downloaded to $PLUGIN_DIR"
}

install_with_curl() {
    print_info "Downloading plugin via curl..."
    mkdir -p "$PLUGIN_DIR/commands" "$PLUGIN_DIR/scripts" "$PLUGIN_DIR/.claude-plugin"

    # Download files
    curl -fsSL "$RAW_URL/scripts/claude_session_saver_cli.py" -o "$PLUGIN_DIR/scripts/claude_session_saver_cli.py"
    curl -fsSL "$RAW_URL/commands/save.md" -o "$PLUGIN_DIR/commands/save.md"
    curl -fsSL "$RAW_URL/commands/sessions.md" -o "$PLUGIN_DIR/commands/sessions.md"
    curl -fsSL "$RAW_URL/commands/back.md" -o "$PLUGIN_DIR/commands/back.md"
    curl -fsSL "$RAW_URL/.claude-plugin/plugin.json" -o "$PLUGIN_DIR/.claude-plugin/plugin.json"
    curl -fsSL "$RAW_URL/README.md" -o "$PLUGIN_DIR/README.md"
    curl -fsSL "$RAW_URL/LICENSE" -o "$PLUGIN_DIR/LICENSE"

    chmod +x "$PLUGIN_DIR/scripts/claude_session_saver_cli.py"
    print_success "Plugin downloaded to $PLUGIN_DIR"
}

create_symlinks() {
    print_info "Creating command symlinks..."
    mkdir -p "$COMMANDS_DIR"

    ln -sf "$PLUGIN_DIR/commands/save.md" "$COMMANDS_DIR/save.md"
    ln -sf "$PLUGIN_DIR/commands/sessions.md" "$COMMANDS_DIR/sessions.md"
    ln -sf "$PLUGIN_DIR/commands/back.md" "$COMMANDS_DIR/back.md"

    print_success "Symlinks created in $COMMANDS_DIR"
}

remove_symlinks() {
    print_info "Removing command symlinks..."

    for cmd in save.md sessions.md back.md; do
        if [ -L "$COMMANDS_DIR/$cmd" ]; then
            rm -f "$COMMANDS_DIR/$cmd"
        fi
    done

    print_success "Symlinks removed"
}

do_install() {
    print_info "Starting installation..."

    # Check if already installed
    if [ -L "$COMMANDS_DIR/save.md" ] && [ -d "$PLUGIN_DIR" ]; then
        print_warning "Plugin already installed."
        read -p "Reinstall? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Cancelled."
            exit 0
        fi
        remove_symlinks
        rm -rf "$PLUGIN_DIR"
    fi

    if check_requirements; then
        install_with_git
    else
        install_with_curl
    fi

    chmod +x "$PLUGIN_DIR/scripts/claude_session_saver_cli.py"
    create_symlinks

    echo ""
    print_success "Installation complete!"
    echo ""
    echo "Available commands:"
    echo "  /save \"name\"    - Save current session"
    echo "  /sessions       - List all sessions"
    echo "  /back \"name\"    - Restore a session"
    echo ""
    print_info "Restart Claude Code to use the plugin."
}

do_update() {
    print_info "Starting update..."

    if [ ! -d "$PLUGIN_DIR" ]; then
        print_error "Plugin not installed. Run install first."
        exit 1
    fi

    if [ -d "$PLUGIN_DIR/.git" ]; then
        print_info "Updating via git pull..."
        cd "$PLUGIN_DIR"
        git pull --ff-only
    else
        print_info "Reinstalling via curl..."
        rm -rf "$PLUGIN_DIR"
        install_with_curl
    fi

    # Recreate symlinks in case paths changed
    create_symlinks

    print_success "Updated successfully!"
}

do_uninstall() {
    print_info "Starting uninstall..."

    if [ ! -d "$PLUGIN_DIR" ] && [ ! -L "$COMMANDS_DIR/save.md" ]; then
        print_error "Plugin not installed."
        exit 1
    fi

    remove_symlinks
    rm -rf "$PLUGIN_DIR"
    print_success "Plugin uninstalled"

    # Ask about session data
    if [ -f "$HOME/.claude/session-names.json" ]; then
        echo ""
        read -p "Remove saved session data (~/.claude/session-names.json)? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -f "$HOME/.claude/session-names.json"
            print_success "Session data removed."
        else
            print_info "Session data preserved."
        fi
    fi
}

show_menu() {
    echo ""
    echo "Select an option:"
    echo "  1) Install"
    echo "  2) Update"
    echo "  3) Uninstall"
    echo "  4) Exit"
    echo ""
    read -p "Enter choice [1-4]: " choice

    case $choice in
        1) do_install ;;
        2) do_update ;;
        3) do_uninstall ;;
        4) echo "Bye!"; exit 0 ;;
        *) print_error "Invalid option"; show_menu ;;
    esac
}

show_help() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  install     Install the plugin"
    echo "  update      Update the plugin"
    echo "  uninstall   Remove the plugin"
    echo "  help        Show this help message"
    echo ""
    echo "If no command is provided, interactive menu will be shown."
}

# Main
print_banner

case "${1:-}" in
    install)
        do_install
        ;;
    update)
        do_update
        ;;
    uninstall)
        do_uninstall
        ;;
    help|--help|-h)
        show_help
        ;;
    "")
        show_menu
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
