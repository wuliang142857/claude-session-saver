---
allowed-tools: Bash(ls:*), Bash(cat:*), Bash(echo:*), Bash(pwd:*), Bash(sed:*), Bash(python3:*)
description: Stash current session with a name (usage: /stash:push "session name")
---

## Context

- Session database: ~/.claude/session-names.json
- Current working directory: !`pwd`
- Project path (encoded): !`pwd | sed 's|/|-|g'`
- Current session ID: !`PROJECT_PATH=$(pwd | sed 's|/|-|g'); ls -t ~/.claude/projects/${PROJECT_PATH}/*.jsonl 2>/dev/null | head -1 | xargs -I{} basename {} .jsonl`
- Saved sessions: !`cat ~/.claude/session-names.json 2>/dev/null || echo '{}'`
- Script path: !`dirname "$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$0")")" 2>/dev/null`/scripts/claude_session_saver_cli.py

## Your task

The user wants to save the current session. The argument is the session name (if not provided, use a default name like "Unnamed Session" plus current timestamp).

Steps:

1. Get the current session ID from context
2. Use the Python script to save the session:
   ```bash
   python3 ~/.claude/plugins/stash/scripts/claude_session_saver_cli.py save "SessionName" "SessionID"
   ```
   Note: If the plugin is installed elsewhere, adjust the path accordingly.
3. Confirm to user: Done! Session saved as "name" (ID: xxx...)

Only perform the save operation, nothing else.
