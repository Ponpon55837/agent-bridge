# Development

## Change workflow

1. Create a focused change in a feature branch.
2. Update scripts, docs, and the example configuration together.
3. Run `./scripts/agent-bridge validate`.
4. Test start/status/stop against a disposable project and session.
5. Confirm `.ai-bridge/` remains ignored.
6. Commit with a short imperative message.

## Runtime adapter rules

Adapters must not send messages to the orchestrator pane. Completion is reported by an
atomic mailbox event file. Every event includes the agent, status, Unix timestamp, summary,
files, tests, and remaining risks.

## Compatibility

Shell scripts must pass `bash -n` and avoid assumptions about macOS-only utilities. Use
`shasum` with a `sha256sum` fallback where hashing is needed.
