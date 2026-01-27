# Stash

[English](README.md) | [简体中文](README.zh-CN.md)

Save and restore named Claude Code sessions for easy context switching. Inspired by `git stash`.

## Commands

| Command | Description |
|---------|-------------|
| `/stash:push "name"` | Save current session with a name |
| `/stash:list` | List all saved sessions |
| `/stash:pop "name"` | Restore a saved session |
| `/stash:drop "name"` | Delete a saved session |
| `/stash:export "name" "path"` | Export a session to zip file |
| `/stash:export-all "path"` | Export all sessions to zip file |
| `/stash:import "path"` | Import sessions from zip file |

## Export/Import (Cross-Machine Migration)

Sessions can be exported to zip files and imported on another machine:

```bash
# Export a single session
/stash:export "my-session" "~/my-session.zip"

# Export all sessions
/stash:export-all "~/all-sessions.zip"

# Import sessions (skips existing names by default)
/stash:import "~/all-sessions.zip"

# Import with overwrite (replaces existing sessions)
/stash:import "~/all-sessions.zip" --overwrite
```

The export file contains session mappings and data, making it easy to backup or transfer sessions between machines.

## Requirements

- Python 3 (pre-installed on macOS/Linux)
- **tmux** or **screen** (optional, for auto-restore feature)

### About tmux/screen Dependency

The `/stash:pop` command supports automatic session restoration:

| Environment | Behavior |
|-------------|----------|
| **In tmux** | Automatically opens a new window with the restored session and closes the current pane |
| **In screen** | Automatically opens a new window with the restored session and closes the current window |
| **Neither** | Displays the `claude --resume <session_id>` command for manual execution |

If you want the seamless auto-restore experience, install tmux or screen:

```bash
# macOS
brew install tmux
# or
brew install screen

# Ubuntu/Debian
sudo apt install tmux
# or
sudo apt install screen
```

## Installation

In Claude Code, run the following commands:

```bash
# Add the marketplace
/plugin marketplace add wuliang142857/claude-stash

# Install the plugin
/plugin install stash@wuliang142857
```

## Update / Uninstall

```bash
# Update
/plugin update stash@wuliang142857

# Uninstall
/plugin uninstall stash@wuliang142857
```

## License

MIT
