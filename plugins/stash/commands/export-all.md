---
allowed-tools: Bash(python3:*)
description: Export all stashed sessions to zip file (usage: /stash:export-all "/path/to/output.zip")
---

## Context

- Saved sessions: !`python3 ~/.claude/plugins/marketplaces/wuliang142857/plugins/stash/scripts/stash.py list 2>/dev/null || python3 ~/.claude/plugins/local/stash/scripts/stash.py list 2>/dev/null || cat ~/.claude/session-names.json 2>/dev/null || echo '{}'`

## Your task

The user wants to export all stashed sessions to a single zip file for backup or transfer to another machine.

Arguments:
- First argument: output file path (should end with .zip)

Steps:

1. Parse the argument. If output path is missing, use a default like `~/all-sessions-export.zip`
2. Use the Python script to export all sessions (try paths in order until one works):
   ```bash
   python3 ~/.claude/plugins/marketplaces/wuliang142857/plugins/stash/scripts/stash.py export-all "/path/to/output.zip"
   ```
   or:
   ```bash
   python3 ~/.claude/plugins/local/stash/scripts/stash.py export-all "/path/to/output.zip"
   ```
3. Report the result to user. If successful, mention the file can be imported on another machine using `/stash:import`.

Only perform the export operation, nothing else.
