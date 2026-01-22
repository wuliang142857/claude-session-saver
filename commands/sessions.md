---
allowed-tools: Bash(cat:*), Bash(python3:*)
description: List all named sessions
---

## Context

- Saved sessions: !`python3 ~/.claude/plugins/claude-session-saver/scripts/claude_session_saver_cli.py list 2>/dev/null || cat ~/.claude/session-names.json 2>/dev/null || echo '{}'`

## Your task

List all saved sessions.

Format the session list from context and output to user:

```
Named Sessions:
--------------------------------
  SessionName1  ->  SessionID1
  SessionName2  ->  SessionID2
  ...
```

If JSON is empty `{}`, tell user: No saved sessions yet. Use `/save "name"` to save the current session.
