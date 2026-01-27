---
allowed-tools: Bash(python3:*)
description: Export a stashed session to zip file (usage: /stash:export "name" "/path/to/output.zip")
---

## Context

- Saved sessions: !`python3 ~/.claude/plugins/marketplaces/wuliang142857/plugins/stash/scripts/stash.py list 2>/dev/null || python3 ~/.claude/plugins/local/stash/scripts/stash.py list 2>/dev/null || cat ~/.claude/session-names.json 2>/dev/null || echo '{}'`

## Your task

The user wants to export a stashed session to a zip file for backup or transfer to another machine.

Arguments:
- First argument: session name to export
- Second argument: output file path (should end with .zip)

Steps:

1. Parse the arguments. If session name is missing, tell user the usage: `/stash:export "name" "/path/to/output.zip"` and stop.
2. If output path is missing, use a default like `~/session-export.zip`
3. Use the Python script to export the session (try paths in order until one works):
   ```bash
   python3 ~/.claude/plugins/marketplaces/wuliang142857/plugins/stash/scripts/stash.py export "SessionName" "/path/to/output.zip"
   ```
   or:
   ```bash
   python3 ~/.claude/plugins/local/stash/scripts/stash.py export "SessionName" "/path/to/output.zip"
   ```
4. Report the result to user. If successful, mention the file can be imported on another machine using `/stash:import`.

Only perform the export operation, nothing else.
