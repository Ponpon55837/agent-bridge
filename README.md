# Agent Bridge

Agent Bridge is a standalone, configurable multi-agent workflow launcher for Codex,
OpenCode, Claude, and future CLI runtimes. It creates an isolated tmux session, keeps
runtime files out of Git, and coordinates completion through mailbox event files.

## Current status

The project is in the extraction phase. The three-pane launcher, supervisor, mailbox
runtime, status, stop, uninstall, and validation commands are available. Runtime adapter
configuration and arbitrary pane counts are planned next.

## Quick start

```bash
cd /path/to/agent-bridge
./scripts/agent-bridge start \
  --session my-project-ai \
  --project /absolute/path/to/project
```

Attach in another terminal:

```bash
tmux attach -t my-project-ai
```

Pane 0 is deliberately untouched by the launcher. Start Codex or another orchestrator
there manually. Pane 1 and pane 2 are prepared for implementation and review agents.

## Daily commands

```bash
./scripts/agent-bridge status --session my-project-ai --project /absolute/path/to/project
./scripts/agent-bridge stop --session my-project-ai --project /absolute/path/to/project
./scripts/agent-bridge validate
./scripts/agent-bridge sessions
./scripts/agent-bridge switch my-project-ai
./scripts/agent-bridge rename old-name new-name
./scripts/agent-bridge kill --session old-name
```

Starting an existing session is safe: the launcher reports the session and does not create
duplicate panes. Use a unique session name when working on multiple projects.

`sessions` marks the current tmux session with `*`. `switch` switches the current tmux
client or attaches from outside tmux. `kill` asks for confirmation unless `--force` is
provided. `rename` validates names and refuses to overwrite an existing session.

## Project integration

Agent Bridge does not copy its scripts into the target project. The target receives only
the ignored `.ai-bridge/` runtime directory. Keep shared settings in a future
`.ai-bridge.yaml` and personal overrides in `.ai-bridge.local.yaml`.

See [installation](docs/INSTALL.md), [configuration](docs/CONFIGURATION.md), and
[development](docs/DEVELOPMENT.md) for complete conventions.

## Removal

Always preview removal first:

```bash
./scripts/agent-bridge uninstall --project /absolute/path/to/project
```

Apply it only when the target and session are correct:

```bash
./scripts/agent-bridge uninstall --project /absolute/path/to/project --force
```

Removal stops the selected supervisor/session and deletes only `.ai-bridge/`. It leaves
source code, Git files, configuration, and unrelated tmux sessions intact.
