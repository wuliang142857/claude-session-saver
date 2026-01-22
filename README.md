# Claude Session Saver

[English](README.md) | [简体中文](README.zh-CN.md)

Save and restore named Claude Code sessions for easy context switching.

## Commands

| Command | Description |
|---------|-------------|
| `/save "name"` | Save current session with a name |
| `/sessions` | List all saved sessions |
| `/back "name"` | Restore a saved session |

## Installation

### Option 1: One-line Install

```bash
curl -fsSL https://raw.githubusercontent.com/wuliang142857/claude-session-saver/main/install.sh | bash -s install
```

### Option 2: Manual Install

```bash
# Clone to plugins directory
git clone https://github.com/wuliang142857/claude-session-saver.git ~/.claude/plugins/claude-session-saver

# Create symlinks to commands directory
ln -sf ~/.claude/plugins/claude-session-saver/commands/save.md ~/.claude/commands/
ln -sf ~/.claude/plugins/claude-session-saver/commands/sessions.md ~/.claude/commands/
ln -sf ~/.claude/plugins/claude-session-saver/commands/back.md ~/.claude/commands/
```

## Update / Uninstall

```bash
# Update
curl -fsSL https://raw.githubusercontent.com/wuliang142857/claude-session-saver/main/install.sh | bash -s update

# Uninstall
curl -fsSL https://raw.githubusercontent.com/wuliang142857/claude-session-saver/main/install.sh | bash -s uninstall
```

## Requirements

- Python 3 (pre-installed on macOS/Linux)

## License

MIT
