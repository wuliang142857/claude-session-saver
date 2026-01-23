---
allowed-tools: Bash(cat:*), Bash(python3:*)
description: List all stashed sessions
---

## Context

- Saved sessions: !`python3 ~/.claude/plugins/stash/scripts/claude_session_saver_cli.py list 2>/dev/null || cat ~/.claude/session-names.json 2>/dev/null || echo '{}'`

## Your task

List all stashed sessions.

Format the session list from context and output to user:

```
Stashed Sessions:
--------------------------------
  SessionName1  ->  SessionID1
  SessionName2  ->  SessionID2
  ...
```

If JSON is empty `{}`, tell user: No stashed sessions yet. Use `/stash:push "name"` to stash the current session.
