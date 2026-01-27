---
allowed-tools: Bash(ls:*), Bash(cat:*), Bash(echo:*), Bash(pwd:*), Bash(sed:*), Bash(python3:*)
description: Stash current session with a name (usage: /stash:push "session name")
---

## Context

- Current session ID: !`python3 ~/.claude/plugins/marketplaces/wuliang142857/plugins/stash/scripts/stash.py current 2>/dev/null || python3 ~/.claude/plugins/local/stash/scripts/stash.py current 2>/dev/null`
- Saved sessions: !`cat ~/.claude/session-names.json 2>/dev/null || echo '{}'`

## Your task

The user wants to save the current session. The argument is the session name (if not provided, use a default name like "Unnamed Session" plus current timestamp).

Steps:

1. Get the current session ID from context. If empty, tell user "Unable to detect current session ID" and stop.
2. Use the Python script to push the session (try paths in order until one works):
   ```bash
   python3 ~/.claude/plugins/marketplaces/wuliang142857/plugins/stash/scripts/stash.py push "SessionName" "SessionID"
   ```
   or:
   ```bash
   python3 ~/.claude/plugins/local/stash/scripts/stash.py push "SessionName" "SessionID"
   ```
3. Confirm to user: Done! Session saved as "name" (ID: xxx...)

Only perform the push operation, nothing else.
