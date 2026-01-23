---
allowed-tools: Bash(python3:*), Bash(cat:*)
description: Drop a stashed session entry (usage: /stash:drop "session name")
---

## Context

- Saved sessions: !`python3 ~/.claude/plugins/stash/scripts/claude_session_saver_cli.py list 2>/dev/null || cat ~/.claude/session-names.json 2>/dev/null || echo '{}'`

## Your task

The user wants to drop a stashed session entry. The argument is the session name.

Steps:

1. Look up the session name from the JSON in context
2. If session name is found:
   - Delete the entry using the Python script:
     ```bash
     python3 ~/.claude/plugins/stash/scripts/claude_session_saver_cli.py delete "SessionName"
     ```
   - Confirm to user: "Dropped session: SessionName"
   - Note: This only removes the name mapping, not the actual session data in ~/.claude/projects/

3. If session name not found, tell user: "Session 'name' not found." and list all stashed sessions.
