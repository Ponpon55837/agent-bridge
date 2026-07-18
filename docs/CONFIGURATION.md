# Configuration

The example configuration is `.ai-bridge.example.yaml`. Copy it to the project as
`.ai-bridge.yaml` when configuration support is needed. Keep personal overrides in
`.ai-bridge.local.yaml`; both local runtime files should remain uncommitted.

## Project

`project.name` is a display name. `project.root` identifies the project where panes
and runtime state are created.

## Session

`session.name` must contain only letters, numbers, `_`, and `-`. Use a unique name per
project and per concurrent workflow. `pane_count` defaults to three and can be increased
with `--panes`; pane 0 is the orchestrator, pane 1 the implementer, and pane 2 the reviewer.

## Agents

Each agent has an `id`, a `runtime` (`codex`, `opencode`, or `claude`), a pane number,
and a role. Runtime adapters will own CLI-specific startup flags; do not put shell
metacharacters into runtime names or session names.

## Workflow

`mailbox` is the only completion notification channel. Agents write event files under
`.ai-bridge/mailbox/`; the supervisor records lifecycle events under `.ai-bridge/state/`.

The launcher automatically reads `.ai-bridge.yaml`. Use `--config PATH` for another file.
Explicit CLI options override configuration values.
