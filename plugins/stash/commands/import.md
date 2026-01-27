---
allowed-tools: Bash(python3:*)
description: Import sessions from zip file (usage: /stash:import "/path/to/input.zip" [--overwrite])
---

## Your task

The user wants to import sessions from a zip file (exported from this machine or another machine).

Arguments:
- First argument: input zip file path
- Optional: `--overwrite` flag to replace existing sessions with same names

Steps:

1. Parse the arguments. If input path is missing, tell user the usage: `/stash:import "/path/to/input.zip"` and stop.
2. Check if user wants to overwrite existing sessions (look for `--overwrite` in arguments)
3. Use the Python script to import sessions (try paths in order until one works):

   Without overwrite:
   ```bash
   python3 ~/.claude/plugins/marketplaces/wuliang142857/plugins/stash/scripts/stash.py import "/path/to/input.zip"
   ```

   With overwrite:
   ```bash
   python3 ~/.claude/plugins/marketplaces/wuliang142857/plugins/stash/scripts/stash.py import "/path/to/input.zip" --overwrite
   ```

   Or from local path:
   ```bash
   python3 ~/.claude/plugins/local/stash/scripts/stash.py import "/path/to/input.zip"
   ```

4. Report the result to user:
   - How many sessions were imported
   - Which sessions were skipped (if any, due to name conflicts)
   - Mention they can use `--overwrite` to replace existing sessions

Only perform the import operation, nothing else.
