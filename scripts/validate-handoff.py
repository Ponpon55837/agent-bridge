#!/usr/bin/env python3
"""Validate Agent Bridge handoff metadata without reading handoff content."""
import json
import os
import sys

if len(sys.argv) != 2:
    print("Usage: validate-handoff.py FILE.json", file=sys.stderr)
    raise SystemExit(2)

with open(sys.argv[1], encoding="utf-8") as stream:
    data = json.load(stream)

required = {"schema_version", "type", "agent", "status", "timestamp", "mailbox_file"}
missing = required.difference(data)
if missing:
    print(f"missing fields: {', '.join(sorted(missing))}", file=sys.stderr)
    raise SystemExit(1)
if data["schema_version"] != 1 or data["type"] != "agent_handoff":
    print("unsupported handoff schema", file=sys.stderr)
    raise SystemExit(1)
if not all(isinstance(data[key], str) and data[key] for key in ("agent", "status", "mailbox_file")):
    print("agent, status, and mailbox_file must be non-empty strings", file=sys.stderr)
    raise SystemExit(1)
if not isinstance(data["timestamp"], int) or data["timestamp"] <= 0:
    print("timestamp must be a positive integer", file=sys.stderr)
    raise SystemExit(1)
if not data["mailbox_file"].endswith(".md") or os.path.basename(data["mailbox_file"]) != data["mailbox_file"]:
    print("mailbox_file must be a Markdown filename without path traversal", file=sys.stderr)
    raise SystemExit(1)
print("handoff metadata valid")
