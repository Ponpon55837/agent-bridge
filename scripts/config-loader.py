#!/usr/bin/env python3
"""Read the small, documented Agent Bridge YAML subset without dependencies."""
import re, shlex, sys

path = sys.argv[1]
text = open(path, encoding="utf-8").read()
def scalar(section, key, default=""):
    match = re.search(rf"(?ms)^{section}:\s*\n(.*?)(?=^[A-Za-z][A-Za-z0-9_-]*:|\Z)", text)
    if not match:
        return default
    value = re.search(rf"(?m)^\s+{key}:\s*([^#\n]+)", match.group(1))
    return value.group(1).strip().strip("'\"") if value else default

values = {
    "CONFIG_PROJECT_ROOT": scalar("project", "root", "."),
    "CONFIG_ORCHESTRATOR_RUNTIME": scalar("project", "orchestrator_runtime", "codex"),
    "CONFIG_SESSION": scalar("session", "name", "agent-bridge-dev"),
    "CONFIG_PANES": scalar("session", "pane_count", "3"),
    "CONFIG_NOTIFICATION": scalar("workflow", "notification", "mailbox"),
    "CONFIG_REQUIRE_LOCAL_VERIFICATION": scalar("workflow", "require_local_verification", "true"),
}
for key in ("implementation_summary", "changed_files", "verification_result", "reviewer_status"):
    values[f"CONFIG_HANDOFF_{key.upper()}"] = scalar("workflow", key, "optional")
codex_block = re.search(r"(?ms)^\s+- id:\s*codex\s*\n(.*?)(?=^\s+- id:|^\S|\Z)", text)
values["CONFIG_ORCHESTRATOR_PANE"] = "0"
values["CONFIG_ORCHESTRATOR_ROLE"] = "orchestrator"
if codex_block:
    pane = re.search(r"(?m)^\s+pane:\s*([^#\n]+)", codex_block.group(1))
    role_value = re.search(r"(?m)^\s+role:\s*([^#\n]+)", codex_block.group(1))
    values["CONFIG_ORCHESTRATOR_PANE"] = pane.group(1).strip() if pane else "0"
    values["CONFIG_ORCHESTRATOR_ROLE"] = role_value.group(1).strip().strip("'\"") if role_value else "orchestrator"
for role, agent_id, default in (("IMPLEMENTER", "implementer", "opencode"), ("REVIEWER", "reviewer", "opencode")):
    block = re.search(rf"(?ms)^\s+- id:\s*{agent_id}\s*\n(.*?)(?=^\s+- id:|^\S|\Z)", text)
    runtime = re.search(r"(?m)^\s+runtime:\s*([^#\n]+)", block.group(1)) if block else None
    values[f"CONFIG_{role}_RUNTIME"] = runtime.group(1).strip().strip("'\"") if runtime else default
    block = re.search(rf"(?ms)^\s+- id:\s*{agent_id}\s*\n(.*?)(?=^\s+- id:|^\S|\Z)", text)
    pane = re.search(r"(?m)^\s+pane:\s*([^#\n]+)", block.group(1)) if block else None
    role_value = re.search(r"(?m)^\s+role:\s*([^#\n]+)", block.group(1)) if block else None
    values[f"CONFIG_{role}_PANE"] = pane.group(1).strip() if pane else ("1" if role == "IMPLEMENTER" else "2")
    values[f"CONFIG_{role}_ROLE"] = role_value.group(1).strip().strip("'\"") if role_value else role.lower()
for key, value in values.items():
    print(f"{key}={shlex.quote(value)}")
