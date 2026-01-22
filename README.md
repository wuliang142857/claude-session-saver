# Claude Session Saver

Save, list, and restore named Claude Code sessions for easy context switching.

## Overview

Claude Session Saver is a Claude Code plugin that helps you manage your coding sessions. Instead of losing context when switching between projects or tasks, you can save your current session with a memorable name and restore it later.

## Commands

### `/save "name"`

Save the current session with a given name.

**Usage:**
```bash
/save "feature-auth"
/save "debugging-api-issue"
/save "refactoring-database"
```

**What it does:**
1. Captures the current session ID
2. Associates it with the provided name
3. Stores the mapping in `~/.claude/session-names.json`

### `/sessions`

List all saved sessions.

**Usage:**
```bash
/sessions
```

**Output example:**
```
Named Sessions:
--------------------------------
  feature-auth        ->  abc123...
  debugging-api       ->  def456...
  refactoring-db      ->  ghi789...
```

### `/back "name"`

Restore a previously saved session.

**Usage:**
```bash
/back "feature-auth"
```

**What it does:**
1. Looks up the session ID by name
2. Provides the command to restore the session:
   - In tmux: `claude --resume <session_id>`
   - Outside tmux: Creates a new tmux session with the restored context

## Installation

### Option 1: Clone from GitHub

```bash
cd ~/.claude/plugins
git clone https://github.com/wuliang142857/claude-session-saver.git
```

### Option 2: Manual Installation

1. Create the plugin directory:
   ```bash
   mkdir -p ~/.claude/plugins/claude-session-saver
   ```

2. Copy all files from this repository to the directory

3. Restart Claude Code

## How It Works

Sessions are stored in a simple JSON file at `~/.claude/session-names.json`:

```json
{
  "feature-auth": "abc123-def456-ghi789",
  "debugging-api": "xyz123-uvw456-rst789"
}
```

The plugin uses Claude Code's native `--resume` flag to restore sessions, preserving the full conversation history and context.

## Use Cases

### Multi-tasking
Switch between different features or bugs without losing context:
```bash
/save "feature-A"
# Work on something else
/back "feature-A"  # Resume right where you left off
```

### Long-running Projects
Save milestone sessions for complex refactoring:
```bash
/save "refactor-phase1-complete"
# Continue working...
/save "refactor-phase2-complete"
```

### Team Collaboration
Share session names with teammates:
```bash
/save "bug-123-investigation"
# Share the session ID for debugging together
```

## Requirements

- Claude Code CLI
- `jq` (JSON processor)
- Optional: `tmux` for session management

## Troubleshooting

### Session not found
- Run `/sessions` to see all saved sessions
- Check if `~/.claude/session-names.json` exists

### Cannot restore session
- Ensure the session hasn't expired
- Check if you have permission to access the session files

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

MIT License

## Author

wuliang142857 (wuliang@wuliang142857.me)
