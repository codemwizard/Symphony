#!/bin/bash
set -euo pipefail

CI_WORKFLOW=".github/workflows/invariants.yml"

if [[ ! -f "$CI_WORKFLOW" ]]; then
  echo "❌ CI workflow file not found: $CI_WORKFLOW" >&2
  exit 1
fi

CI_WORKFLOW="$CI_WORKFLOW" python3 - <<'PY'
import os
from pathlib import Path

import yaml

wf = Path(os.environ["CI_WORKFLOW"])
doc = yaml.safe_load(wf.read_text(encoding="utf-8")) or {}
jobs = doc.get("jobs") or {}
security_scan = jobs.get("security_scan")
if not isinstance(security_scan, dict):
    print("❌ security_scan job not found")
    raise SystemExit(1)

steps = security_scan.get("steps") or []
run_text = "\n".join((s.get("run") or "") for s in steps if isinstance(s, dict))

print("✅ security_scan job found")
print("\n=== Checking Continue-On-Error ===")
if str(security_scan.get("continue-on-error", "")).lower() == "true":
    print("❌ security_scan has continue-on-error: true")
    raise SystemExit(1)
print("✅ continue-on-error is not enabled")

print("\n=== Checking Shell Fail-Closed ===")
if "set -euo pipefail" in run_text:
    print("✅ set -euo pipefail found in security_scan steps")
else:
    print("❌ set -euo pipefail missing from security_scan steps")
    raise SystemExit(1)

print("\n=== Checking Semgrep Blocking Mode ===")
if "--error" in run_text or "semgrep --config=security/semgrep/rules.yml --quiet --error" in run_text:
    print("✅ semgrep blocking mode present")
else:
    print("❌ semgrep blocking mode not detected")
    raise SystemExit(1)

print("\n=== Summary ===")
print("✅ security_scan fail-closed verification passed")
PY
