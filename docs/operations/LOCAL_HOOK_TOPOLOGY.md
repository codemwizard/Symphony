# Local Hook Topology

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Purpose

Define the canonical local hook topology for this repo so the tracked hook source, installed destination, and gate levels are explicit and mechanically verifiable.

## Canonical Model

- Tracked hook source: `.githooks/`
- Active installed destination: `.git/hooks/`
- Installer: `scripts/dev/install_git_hooks.sh`

The installer must copy tracked hook sources from `.githooks/` into `.git/hooks/`.
It must not synthesize hook bodies inline.

## Gate Levels

There are two local gate levels:

1. Light commit-path pre-flight
   - entrypoint: `.githooks/pre-commit`
   - script: `scripts/dev/pre_flight.sh`
   - intended behavior: run only the lightweight staged structural preflight

2. Heavy push-time pre-CI
   - entrypoint: `.githooks/pre-push`
   - script: `scripts/dev/pre_ci.sh`
   - intended behavior: run the expensive parity and governance gate stack

## Installation Rule

To install the canonical hook topology:

```bash
bash scripts/dev/install_git_hooks.sh
```

After installation:

- `.git/hooks/pre-commit` must match `.githooks/pre-commit`
- `.git/hooks/pre-push` must match `.githooks/pre-push`

## Drift Policy

Hook topology drift is a failure condition.

Examples:

- `.git/hooks/pre-commit` does not match `.githooks/pre-commit`
- `.git/hooks/pre-push` does not match `.githooks/pre-push`
- the installer no longer copies from `.githooks/`
- `pre_flight` starts calling `pre_ci`
- docs describe a different topology than the scripts implement
