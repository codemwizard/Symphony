#!/bin/bash
set -euo pipefail

CI_WORKFLOW=".github/workflows/invariants.yml"
requires=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --require)
      requires+=("${2:-}")
      shift 2
      ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if [[ ! -f "$CI_WORKFLOW" ]]; then
  echo "❌ CI workflow file not found: $CI_WORKFLOW" >&2
  exit 1
fi

REQS_JOINED="$(printf '%s\n' "${requires[@]:-}" | paste -sd, -)"

CI_WORKFLOW="$CI_WORKFLOW" REQS_JOINED="$REQS_JOINED" python3 - <<'PY'
import os
import sys
from pathlib import Path

import yaml

wf = Path(os.environ["CI_WORKFLOW"])
reqs_joined = os.environ.get("REQS_JOINED", "")
requires = [x for x in reqs_joined.split(",") if x]

doc = yaml.safe_load(wf.read_text(encoding="utf-8")) or {}
jobs = doc.get("jobs") or {}
security_scan = jobs.get("security_scan")
if not isinstance(security_scan, dict):
    print("❌ security_scan job not found")
    raise SystemExit(1)

steps = security_scan.get("steps") or []
run_text = "\n".join((s.get("run") or "") for s in steps if isinstance(s, dict))

print("✅ security_scan job found")
print("\n=== Checking Required Tools ===")
for req in requires:
    if req in run_text:
        print(f"✅ {req} found in security_scan")
    else:
        print(f"❌ {req} NOT found in security_scan")
        raise SystemExit(1)

if "semgrep" in run_text:
    print("✅ semgrep found in security_scan")
else:
    print("⚠️  semgrep not found in security_scan")

print("\n=== Checking Fail-Closed Behavior ===")
if str(security_scan.get("continue-on-error", "")).lower() == "true":
    print("❌ security_scan has continue-on-error: true")
    raise SystemExit(1)
print("✅ security_scan appears fail-closed")

print("\n=== Summary ===")
print("✅ security_scan include checks passed")
PY
