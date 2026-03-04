#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

MANIFEST="$ROOT/agent_manifest.yml"

die() {
  echo "ERROR: $*" >&2
  exit 1
}

hr() {
  echo "------------------------------------------------------------"
}

if [[ ! -f "$MANIFEST" ]]; then
  die "Missing agent manifest: $MANIFEST"
fi

echo "==> Symphony Agent Bootstrap (deterministic, fail-closed)"
echo "ROOT: $ROOT"
echo "MANIFEST: $MANIFEST"
hr

python3 - <<'PY'
import os
from pathlib import Path
import yaml  # type: ignore

root = Path(os.getcwd())
manifest = root / "agent_manifest.yml"

data = yaml.safe_load(manifest.read_text(encoding="utf-8"))
canon = data.get("canonical_docs") or []
boot = data.get("mandatory_boot_sequence") or []

print("Canonical docs:")
for d in canon:
    print(f"  - {d}")

print("\nMandatory boot sequence:")
for c in boot:
    print(f"  - {c}")

if not canon or not boot:
    raise SystemExit("ERROR: manifest missing canonical_docs or mandatory_boot_sequence")
PY

hr
echo "==> Running conformance gate"
scripts/audit/verify_agent_conformance.sh

hr
echo "==> Running pre-CI local parity gate"
scripts/dev/pre_ci.sh

hr
echo "==> Bootstrap complete"
echo "Next: run a task deterministically:"
echo "  scripts/agent/run_task.sh <TASK_ID>"
