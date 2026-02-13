#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SCRIPT="$ROOT/scripts/security/lint_dotnet_quality.sh"

if [[ ! -x "$SCRIPT" ]]; then
  echo "Required script missing or not executable: $SCRIPT" >&2
  exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

mkdir -p "$tmp_dir/scripts/lib" "$tmp_dir/evidence/phase1"
cp "$ROOT/scripts/lib/evidence.sh" "$tmp_dir/scripts/lib/evidence.sh"

set +e
DOTNET_LINT_ROOT="$tmp_dir" "$SCRIPT"
rc=$?
set -e

if [[ "$rc" -ne 0 ]]; then
  echo "Expected pass when no dotnet projects exist; got rc=$rc" >&2
  exit 1
fi

python3 - <<'PY' "$tmp_dir/evidence/phase1/dotnet_lint_quality.json"
import json,sys
data=json.load(open(sys.argv[1],encoding="utf-8"))
if data.get("status") != "PASS":
    raise SystemExit("status not PASS")
if data.get("note") != "no_dotnet_projects_found":
    raise SystemExit("note mismatch")
if data.get("targets_count") != 0:
    raise SystemExit("targets_count mismatch")
print("ok")
PY

echo "test_lint_dotnet_quality.sh passed"
