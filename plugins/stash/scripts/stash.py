#!/usr/bin/env python3
# ABOUTME: CLI tool for managing Claude Code session stash.
# ABOUTME: Handles push, pop, list, drop, export and import operations.

import json
import os
import shutil
import socket
import sys
import tempfile
import zipfile
from datetime import datetime, timezone
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


def cmd_push(name, session_id):
    """Push (save) a session with the given name and ID."""
    sessions = load_sessions()
    sessions[name] = session_id
    save_sessions(sessions)
    print(f"Pushed: {name} -> {session_id}")


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


def cmd_drop(name):
    """Drop (delete) a session by name."""
    sessions = load_sessions()
    if name in sessions:
        del sessions[name]
        save_sessions(sessions)
        print(f"Dropped: {name}")
        return 0
    else:
        print(f"Session '{name}' not found", file=sys.stderr)
        return 1


def cmd_current():
    """
    2026-01-23: Get the current session ID by finding the most recently modified .jsonl file.
    Scans all project directories under ~/.claude/projects/
    """
    projects_dir = Path.home() / ".claude" / "projects"
    if not projects_dir.exists():
        print("", end="")
        return 1

    # Find all .jsonl files and get the most recent one
    jsonl_files = list(projects_dir.glob("*/*.jsonl"))
    if not jsonl_files:
        print("", end="")
        return 1

    # Sort by modification time, most recent first
    most_recent = max(jsonl_files, key=lambda f: f.stat().st_mtime)
    session_id = most_recent.stem  # filename without extension
    print(session_id)
    return 0


def find_session_file(session_id):
    """
    2026-01-26: Find the JSONL file for a given session ID.
    Searches ~/.claude/projects/<encoded-path>/<session-id>.jsonl
    Returns Path if found, None otherwise.
    """
    projects_dir = Path.home() / ".claude" / "projects"
    if not projects_dir.exists():
        return None

    # Search for matching session file in all project directories
    for jsonl_file in projects_dir.glob(f"*/{session_id}.jsonl"):
        if jsonl_file.exists():
            return jsonl_file
    return None


def cmd_export(name, output_path):
    """
    2026-01-26: Export a single session to a zip file.
    Creates a zip with manifest.json, mappings.json, and sessions/<id>.jsonl
    """
    sessions = load_sessions()
    if name not in sessions:
        print(f"Session '{name}' not found", file=sys.stderr)
        return 1

    session_id = sessions[name]
    session_file = find_session_file(session_id)
    if not session_file:
        print(f"Session file for '{name}' (ID: {session_id}) not found", file=sys.stderr)
        return 1

    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    # Create manifest
    manifest = {
        "version": "1.0",
        "exported_at": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "source_machine": socket.gethostname(),
        "sessions_count": 1
    }

    # Create mappings (only include this session)
    mappings = {name: session_id}

    with zipfile.ZipFile(output_path, 'w', zipfile.ZIP_DEFLATED) as zf:
        zf.writestr("manifest.json", json.dumps(manifest, indent=2))
        zf.writestr("mappings.json", json.dumps(mappings, indent=2, ensure_ascii=False))
        zf.write(session_file, f"sessions/{session_id}.jsonl")

    print(f"Exported '{name}' to {output_path}")
    return 0


def cmd_export_all(output_path):
    """
    2026-01-26: Export all sessions to a zip file.
    Creates a zip with manifest.json, mappings.json, and sessions/*.jsonl
    """
    sessions = load_sessions()
    if not sessions:
        print("No sessions to export", file=sys.stderr)
        return 1

    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    # Find all session files
    exported_sessions = {}
    missing_sessions = []

    for name, session_id in sessions.items():
        session_file = find_session_file(session_id)
        if session_file:
            exported_sessions[name] = (session_id, session_file)
        else:
            missing_sessions.append(name)

    if not exported_sessions:
        print("No session files found to export", file=sys.stderr)
        return 1

    # Create manifest
    manifest = {
        "version": "1.0",
        "exported_at": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "source_machine": socket.gethostname(),
        "sessions_count": len(exported_sessions)
    }

    # Create mappings
    mappings = {name: sid for name, (sid, _) in exported_sessions.items()}

    with zipfile.ZipFile(output_path, 'w', zipfile.ZIP_DEFLATED) as zf:
        zf.writestr("manifest.json", json.dumps(manifest, indent=2))
        zf.writestr("mappings.json", json.dumps(mappings, indent=2, ensure_ascii=False))
        for name, (session_id, session_file) in exported_sessions.items():
            zf.write(session_file, f"sessions/{session_id}.jsonl")

    print(f"Exported {len(exported_sessions)} session(s) to {output_path}")
    if missing_sessions:
        print(f"Warning: {len(missing_sessions)} session(s) skipped (files not found): {', '.join(missing_sessions)}", file=sys.stderr)
    return 0


def cmd_import(input_path, overwrite=False):
    """
    2026-01-26: Import sessions from a zip file.
    By default, skips sessions with existing names unless overwrite=True.
    """
    input_path = Path(input_path)
    if not input_path.exists():
        print(f"File not found: {input_path}", file=sys.stderr)
        return 1

    if not zipfile.is_zipfile(input_path):
        print(f"Invalid zip file: {input_path}", file=sys.stderr)
        return 1

    projects_dir = Path.home() / ".claude" / "projects"
    projects_dir.mkdir(parents=True, exist_ok=True)

    with zipfile.ZipFile(input_path, 'r') as zf:
        # Read and validate manifest
        try:
            manifest_data = zf.read("manifest.json")
            manifest = json.loads(manifest_data)
        except (KeyError, json.JSONDecodeError) as e:
            print(f"Invalid export file: missing or invalid manifest.json", file=sys.stderr)
            return 1

        # Read mappings
        try:
            mappings_data = zf.read("mappings.json")
            import_mappings = json.loads(mappings_data)
        except (KeyError, json.JSONDecodeError) as e:
            print(f"Invalid export file: missing or invalid mappings.json", file=sys.stderr)
            return 1

        # Load current sessions
        current_sessions = load_sessions()

        imported = []
        skipped = []

        for name, session_id in import_mappings.items():
            # Check for name conflict
            if name in current_sessions and not overwrite:
                skipped.append(name)
                continue

            # Check if session file exists in zip
            session_file_path = f"sessions/{session_id}.jsonl"
            try:
                session_data = zf.read(session_file_path)
            except KeyError:
                print(f"Warning: Session file '{session_file_path}' not found in archive, skipping '{name}'", file=sys.stderr)
                continue

            # Find or create target directory
            # Use a generic "imported" directory for cross-machine sessions
            target_dir = projects_dir / "-imported-sessions-"
            target_dir.mkdir(parents=True, exist_ok=True)

            # Write session file
            target_file = target_dir / f"{session_id}.jsonl"
            target_file.write_bytes(session_data)

            # Update mapping
            current_sessions[name] = session_id
            imported.append(name)

        # Save updated mappings
        save_sessions(current_sessions)

        print(f"Imported {len(imported)} session(s)")
        if imported:
            print(f"  Imported: {', '.join(imported)}")
        if skipped:
            print(f"  Skipped (already exists): {', '.join(skipped)}")
            print("  Use --overwrite to replace existing sessions")

    return 0


def print_usage():
    """Print usage information."""
    # 2026-01-27: Rename commands to match /stash:* naming convention
    usage = """
Usage: stash.py <command> [args]

Commands:
  push <name> <session_id>    Push (save) a session with name and ID
  list                        List all saved sessions (JSON output)
  get <name>                  Get session ID by name
  drop <name>                 Drop (delete) a session by name
  current                     Get current session ID (most recent .jsonl)
  export <name> <path>        Export a single session to zip file
  export-all <path>           Export all sessions to zip file
  import <path> [--overwrite] Import sessions from zip file

Environment:
  SESSION_DB_PATH             Override default database path
                              (default: ~/.claude/session-names.json)
"""
    print(usage.strip())


def main():
    # 2026-01-27: Update command names to match /stash:* convention
    if len(sys.argv) < 2:
        print_usage()
        sys.exit(1)

    cmd = sys.argv[1]

    if cmd == "push" and len(sys.argv) == 4:
        cmd_push(sys.argv[2], sys.argv[3])
    elif cmd == "list":
        cmd_list()
    elif cmd == "get" and len(sys.argv) == 3:
        sys.exit(cmd_get(sys.argv[2]))
    elif cmd == "drop" and len(sys.argv) == 3:
        sys.exit(cmd_drop(sys.argv[2]))
    elif cmd == "current":
        sys.exit(cmd_current())
    elif cmd == "export" and len(sys.argv) == 4:
        sys.exit(cmd_export(sys.argv[2], sys.argv[3]))
    elif cmd == "export-all" and len(sys.argv) == 3:
        sys.exit(cmd_export_all(sys.argv[2]))
    elif cmd == "import" and len(sys.argv) >= 3:
        overwrite = "--overwrite" in sys.argv
        sys.exit(cmd_import(sys.argv[2], overwrite))
    elif cmd in ("-h", "--help", "help"):
        print_usage()
    else:
        print(f"Unknown command or invalid arguments: {' '.join(sys.argv[1:])}", file=sys.stderr)
        print_usage()
        sys.exit(1)


if __name__ == "__main__":
    main()
