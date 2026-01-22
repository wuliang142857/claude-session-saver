---
allowed-tools: Bash(cat:*), Bash(python3:*), Bash(tmux:*)
description: Restore a named session (usage: /back "session name")
---

## Context

- Saved sessions: !`python3 ~/.claude/plugins/claude-session-saver/scripts/claude_session_saver_cli.py list 2>/dev/null || cat ~/.claude/session-names.json 2>/dev/null || echo '{}'`
- Currently in tmux: !`[ -n "$TMUX" ] && echo "yes" || echo "no"`

## Your task

The user wants to restore a previously saved session. The argument is the session name.

Steps:

1. Look up the session ID from the JSON in context by session name
2. If session ID is found:
   - If currently in tmux, tell user to execute the following command to restore session in **current window** (since current session will be replaced, Claude cannot auto-execute):
     ```bash
     claude --resume <session_id>
     ```
   - If not in tmux, can start in a **new tmux session**:
     ```bash
     tmux new-session -d -s "SessionName" "claude --resume <session_id>" && tmux attach -t "SessionName"
     ```
   - Tell user: Please copy and execute the above command to restore "SessionName" session

3. If not found, list all saved sessions for user to choose from.
