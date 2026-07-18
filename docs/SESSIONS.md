# Session management

Use a unique name per project, such as `lucky50-ai` or `agent-bridge-dev`.

## List and identify

```bash
./scripts/agent-bridge sessions
```

The current tmux session is marked with `*`.

## Switch

```bash
./scripts/agent-bridge switch lucky50-ai
```

Inside tmux this switches the current client. Outside tmux it attaches to the target.

## Rename

```bash
./scripts/agent-bridge rename old-name new-name
```

Names may contain only letters, numbers, `_`, and `-`. Existing sessions are never
overwritten. Rename does not move or delete project files.

## Remove an unused session

```bash
./scripts/agent-bridge kill --session old-name
./scripts/agent-bridge kill --session old-name --force
```

Without `--force`, confirmation is required. Only the exact named session is killed;
wildcards and empty names are rejected. Remove project runtime separately with
`agent-bridge uninstall --project /path/to/project --force`.
