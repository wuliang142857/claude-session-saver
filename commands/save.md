---
allowed-tools: Bash(ls:*), Bash(cat:*), Bash(jq:*), Bash(echo:*), Bash(mv:*), Bash(pwd:*), Bash(sed:*)
description: Save current session with a name (usage: /save "session name")
---

## Context

- Session database: ~/.claude/session-names.json
- Current working directory: !`pwd`
- Project path (encoded): !`pwd | sed 's|/|-|g'`
- Current session ID: !`PROJECT_PATH=$(pwd | sed 's|/|-|g'); ls -t ~/.claude/projects/${PROJECT_PATH}/*.jsonl 2>/dev/null | head -1 | xargs -I{} basename {} .jsonl`
- Saved sessions: !`cat ~/.claude/session-names.json 2>/dev/null || echo '{}'`

## Your task

The user wants to save the current session. The argument is the session name (if not provided, use a default name like "Unnamed Session" plus current timestamp).

Steps:

1. Get the current session ID from context
2. Ensure database file exists: `[ ! -f ~/.claude/session-names.json ] && echo '{}' > ~/.claude/session-names.json`
3. Use jq to save name and ID to JSON:
   ```bash
   jq --arg name "SessionName" --arg id "SessionID" '.[$name] = $id' ~/.claude/session-names.json > /tmp/session-db.json && mv /tmp/session-db.json ~/.claude/session-names.json
   ```
4. Confirm to user: Done! Session saved as "name" (ID: xxx...)

Only perform the save operation, nothing else.
