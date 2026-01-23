---
allowed-tools: Bash(cat:*), Bash(python3:*), Bash(tmux:*), Bash(screen:*), Bash(grep:*)
description: Pop/restore a stashed session (usage: /stash:pop "session name")
---

## Context

- Saved sessions: !`python3 ~/.claude/plugins/marketplaces/wuliang142857/plugins/stash/scripts/claude_session_saver_cli.py list 2>/dev/null || python3 ~/.claude/plugins/local/stash/scripts/claude_session_saver_cli.py list 2>/dev/null || cat ~/.claude/session-names.json 2>/dev/null || echo '{}'`
- Currently in tmux: !`[ -n "$TMUX" ] && echo "yes" || echo "no"`
- Current tmux pane: !`echo "$TMUX_PANE"`
- Currently in screen: !`[ -n "$STY" ] && echo "yes" || echo "no"`
- Current screen window: !`echo "$WINDOW"`

## Your task

The user wants to restore a previously stashed session. The argument is the session name.

Steps:

1. Look up the session ID from the JSON in context by session name
2. If session ID is found, **validate the session first**:
   - Check if session file exists and contains actual conversation data:
     ```bash
     grep -c '"message"' ~/.claude/projects/-Users-admin/<session_id>.jsonl 2>/dev/null || echo "0"
     ```
   - If the count is 0, the session data is corrupted/missing. Tell user: "Session '<name>' exists but conversation data is missing or corrupted. Please use /stash:push to save it again from the original session."
   - If the count > 0, proceed to restore

3. If session is valid:
   - **If in tmux**, automatically restore by running:
     ```bash
     tmux new-window -n "SessionName" "claude --resume <session_id>" \; kill-pane -t <current_pane_id>
     ```
   - **If in screen**, automatically restore by running:
     ```bash
     screen -X eval "screen -t 'SessionName' bash -lc 'claude --resume <session_id>'" "kill"
     ```
   - **If not in tmux or screen**, tell user to manually run:
     ```bash
     claude --resume <session_id>
     ```

4. After running the command, output: "Popping session: SessionName..."

5. If session name not found, list all saved sessions for user to choose from.
