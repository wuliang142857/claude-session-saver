#!/usr/bin/env python3
# ABOUTME: CLI tool for managing Claude Code session name mappings.
# ABOUTME: Handles save, list, and lookup operations on session-names.json.

import json
import os
import sys
from pathlib import Path

DEFAULT_DB_PATH = Path.home() / ".claude" / "session-names.json"


def get_db_path():
    """Return the session database file path."""
    return Path(os.environ.get("SESSION_DB_PATH", DEFAULT_DB_PATH))


def load_sessions():
    """Load sessions from JSON file, return empty dict if not exists."""
    db_path = get_db_path()
    if not db_path.exists():
        return {}
    try:
        with open(db_path, "r", encoding="utf-8") as f:
            return json.load(f)
    except (json.JSONDecodeError, IOError):
        return {}


def save_sessions(data):
    """Save sessions to JSON file."""
    db_path = get_db_path()
    db_path.parent.mkdir(parents=True, exist_ok=True)
    with open(db_path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)


def cmd_save(name, session_id):
    """Save a session with the given name and ID."""
    sessions = load_sessions()
    sessions[name] = session_id
    save_sessions(sessions)
    print(f"Saved: {name} -> {session_id}")


def cmd_list():
    """List all saved sessions as JSON."""
    sessions = load_sessions()
    print(json.dumps(sessions, indent=2, ensure_ascii=False))


def cmd_get(name):
    """Get session ID by name, exit 1 if not found."""
    sessions = load_sessions()
    if name in sessions:
        print(sessions[name])
        return 0
    else:
        print(f"Session '{name}' not found", file=sys.stderr)
        return 1


def cmd_delete(name):
    """Delete a session by name."""
    sessions = load_sessions()
    if name in sessions:
        del sessions[name]
        save_sessions(sessions)
        print(f"Deleted: {name}")
        return 0
    else:
        print(f"Session '{name}' not found", file=sys.stderr)
        return 1


def print_usage():
    """Print usage information."""
    usage = """
Usage: session_manager.py <command> [args]

Commands:
  save <name> <session_id>   Save a session with name and ID
  list                       List all saved sessions (JSON output)
  get <name>                 Get session ID by name
  delete <name>              Delete a session by name

Environment:
  SESSION_DB_PATH            Override default database path
                             (default: ~/.claude/session-names.json)
"""
    print(usage.strip())


def main():
    if len(sys.argv) < 2:
        print_usage()
        sys.exit(1)

    cmd = sys.argv[1]

    if cmd == "save" and len(sys.argv) == 4:
        cmd_save(sys.argv[2], sys.argv[3])
    elif cmd == "list":
        cmd_list()
    elif cmd == "get" and len(sys.argv) == 3:
        sys.exit(cmd_get(sys.argv[2]))
    elif cmd == "delete" and len(sys.argv) == 3:
        sys.exit(cmd_delete(sys.argv[2]))
    elif cmd in ("-h", "--help", "help"):
        print_usage()
    else:
        print(f"Unknown command or invalid arguments: {' '.join(sys.argv[1:])}", file=sys.stderr)
        print_usage()
        sys.exit(1)


if __name__ == "__main__":
    main()
