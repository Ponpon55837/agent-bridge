#!/usr/bin/env python3
"""Read the small, documented Agent Bridge YAML subset without dependencies."""
import os, re, shlex, sys

path = sys.argv[1]
with open(path, encoding="utf-8") as config_file:
    base_text = config_file.read()
local_path = os.path.join(os.path.dirname(os.path.abspath(path)), ".ai-bridge.local.yaml")
texts = [base_text]
if os.path.abspath(path) != os.path.abspath(local_path) and os.path.isfile(local_path):
    with open(local_path, encoding="utf-8") as local_file:
        texts.insert(0, local_file.read())
def scalar(section, key, default=""):
    for text in texts:
        match = re.search(rf"(?ms)^{section}:\s*\n(.*?)(?=^[A-Za-z][A-Za-z0-9_-]*:|\Z)", text)
        if match:
            value = re.search(rf"(?m)^\s+{key}:\s*([^#\n]+)", match.group(1))
            if value:
                return value.group(1).strip().strip("'\"")
    return default

def block(section_id):
    for text in texts:
        match = re.search(rf"(?ms)^\s+- id:\s*{section_id}\s*\n(.*?)(?=^\s+- id:|^\S|\Z)", text)
        if match:
            return match.group(1)
    return ""

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
codex_block = block("codex")
values["CONFIG_ORCHESTRATOR_PANE"] = "0"
values["CONFIG_ORCHESTRATOR_ROLE"] = "orchestrator"
if codex_block:
    pane = re.search(r"(?m)^\s+pane:\s*([^#\n]+)", codex_block)
    role_value = re.search(r"(?m)^\s+role:\s*([^#\n]+)", codex_block)
    values["CONFIG_ORCHESTRATOR_PANE"] = pane.group(1).strip() if pane else "0"
    values["CONFIG_ORCHESTRATOR_ROLE"] = role_value.group(1).strip().strip("'\"") if role_value else "orchestrator"
def agent_block_for(agent_id, legacy_id=None):
    result = block(agent_id)
    if result or not legacy_id:
        return result
    return block(legacy_id)

for role, agent_id, legacy_id, default_pane, default_runtime in (
    ("IMPLEMENTER_A", "implementer-a", "implementer", "1", "opencode"),
    ("IMPLEMENTER_B", "implementer-b", None, "", "opencode"),
    ("REVIEWER", "reviewer", None, "2", "opencode"),
):
    agent_block = agent_block_for(agent_id, legacy_id)
    runtime = re.search(r"(?m)^\s+runtime:\s*([^#\n]+)", agent_block) if agent_block else None
    values[f"CONFIG_{role}_RUNTIME"] = runtime.group(1).strip().strip("'\"") if runtime else default_runtime
    pane = re.search(r"(?m)^\s+pane:\s*([^#\n]+)", agent_block) if agent_block else None
    role_value = re.search(r"(?m)^\s+role:\s*([^#\n]+)", agent_block) if agent_block else None
    values[f"CONFIG_{role}_PANE"] = pane.group(1).strip() if pane else default_pane
    values[f"CONFIG_{role}_ROLE"] = role_value.group(1).strip().strip("'\"") if role_value else role.lower()
values["CONFIG_IMPLEMENTER_ROLE"] = values["CONFIG_IMPLEMENTER_A_ROLE"]
values["CONFIG_IMPLEMENTER_PANE"] = values["CONFIG_IMPLEMENTER_A_PANE"]
values["CONFIG_IMPLEMENTER_RUNTIME"] = values["CONFIG_IMPLEMENTER_A_RUNTIME"]
for key, value in values.items():
    print(f"{key}={shlex.quote(value)}")
