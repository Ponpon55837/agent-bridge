# Installation and removal

## Install into a project

```bash
git clone <agent-bridge-repository>
cd agent-bridge
./scripts/agent-bridge start --session my-project-ai --project /absolute/project/path
```

The installer does not copy scripts into the target project. It creates only the ignored
`.ai-bridge/` runtime directory. Start the orchestrator manually in pane 0, then use
the implementer and reviewer panes.

## Check status

```bash
./scripts/agent-bridge status --session my-project-ai --project /absolute/project/path
```

## Stop

```bash
./scripts/agent-bridge stop --session my-project-ai --project /absolute/project/path
```

## Remove runtime state

Removal is a dry run by default:

```bash
./scripts/agent-bridge uninstall --project /absolute/project/path
./scripts/agent-bridge uninstall --project /absolute/project/path --force
```

`--force` removes only `.ai-bridge/` and the specified session. It does not remove source
files, Git history, configuration, or unrelated tmux sessions.
