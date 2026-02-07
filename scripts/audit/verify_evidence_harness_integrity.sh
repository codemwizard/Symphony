#!/usr/bin/env bash
set -euo pipefail

# verify_evidence_harness_integrity.sh
#
# "Watch-the-watcher" verifier:
# Enforce a few high-signal, low-noise anti-bypass rules on evidence-producing gate scripts.
#
# Locked decisions (AuditAnswers.txt):
# - forbid: `set +e`
# - forbid: `|| true` unless explicitly annotated
# - forbid: `2>/dev/null` unless explicitly annotated
# - require: `set -euo pipefail` near top
#
# Scope: scripts listed as required gates in docs/control_planes/CONTROL_PLANES.yml

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CP_FILE="$ROOT_DIR/docs/control_planes/CONTROL_PLANES.yml"
EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/evidence_harness_integrity.json"

mkdir -p "$EVIDENCE_DIR"
source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

if [[ ! -f "$CP_FILE" ]]; then
  echo "ERROR: missing control planes file: $CP_FILE" >&2
  exit 2
fi

python3 - <<'PY' "$CP_FILE" "$ROOT_DIR" "$EVIDENCE_FILE"
import json
import os
import re
import sys
from pathlib import Path

cp_file = Path(sys.argv[1])
root = Path(sys.argv[2])
out_path = Path(sys.argv[3])

ts = os.environ.get("EVIDENCE_TS")
sha = os.environ.get("EVIDENCE_GIT_SHA")
fp = os.environ.get("EVIDENCE_SCHEMA_FP")

try:
    import yaml  # type: ignore
except Exception as e:
    raise SystemExit(f"pyyaml_missing:{e}")

cp = yaml.safe_load(cp_file.read_text(encoding="utf-8")) or {}
planes = cp.get("control_planes") or {}

scripts = []
for plane in (planes or {}).values():
    for g in (plane.get("required_gates") or []):
        s = (g or {}).get("script")
        if s:
            scripts.append(str(s))

scripts = sorted(set(scripts))

violations = []
scanned = []

set_strict_re = re.compile(r"^\s*set\s+-euo\s+pipefail\s*$")
set_plus_e_re = re.compile(r"^\s*set\s+\+e\b")
or_true_re = re.compile(r"\|\|\s*true\b")
stderr_suppress_re = re.compile(r"2>\s*/dev/null")

allow_or_true_re = re.compile(r"symphony:allow_or_true")
allow_stderr_re = re.compile(r"symphony:allow_stderr_suppress")

for rel in scripts:
    p = root / rel
    if not p.exists():
        violations.append({"script": rel, "kind": "missing_script"})
        continue

    txt = p.read_text(encoding="utf-8", errors="ignore").splitlines()
    scanned.append(rel)

    # Rule 1: strict mode near top (first 12 lines).
    if not any(set_strict_re.match(ln) for ln in txt[:12]):
        violations.append({"script": rel, "kind": "missing_set_euo_pipefail"})

    # Rule 2: forbid set +e anywhere.
    for i, ln in enumerate(txt, 1):
        if ln.lstrip().startswith("#"):
            continue
        if set_plus_e_re.search(ln):
            violations.append({"script": rel, "kind": "forbidden_set_plus_e", "lineno": i, "line": ln.strip()})

    # Rule 3/4: ban `|| true` and `2>/dev/null` unless annotated.
    for i, ln in enumerate(txt, 1):
        if ln.lstrip().startswith("#"):
            continue
        prev = txt[i - 2] if i >= 2 else ""
        annotated_or_true = allow_or_true_re.search(ln) or allow_or_true_re.search(prev)
        annotated_stderr = allow_stderr_re.search(ln) or allow_stderr_re.search(prev)

        if or_true_re.search(ln) and not annotated_or_true:
            violations.append({"script": rel, "kind": "forbidden_or_true", "lineno": i, "line": ln.strip()})
        if stderr_suppress_re.search(ln) and not annotated_stderr:
            violations.append({"script": rel, "kind": "forbidden_stderr_suppress", "lineno": i, "line": ln.strip()})

status = "PASS" if not violations else "FAIL"

out = {
    "check_id": "EVIDENCE-HARNESS-INTEGRITY",
    "timestamp_utc": ts,
    "git_sha": sha,
    "schema_fingerprint": fp,
    "status": status,
    "control_planes_file": str(cp_file),
    "scripts_scanned": scanned,
    "violation_count": len(violations),
    "violations": violations,
    "annotations": {
        "allow_or_true": "symphony:allow_or_true",
        "allow_stderr_suppress": "symphony:allow_stderr_suppress",
    },
}

out_path.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")

if status != "PASS":
    print(f"❌ Evidence harness integrity failed. Evidence: {out_path}", file=sys.stderr)
    for v in violations[:50]:
        msg = f"{v.get('script')} {v.get('kind')}"
        if v.get("lineno"):
            msg += f":{v.get('lineno')}"
        print(f" - {msg}", file=sys.stderr)
    raise SystemExit(1)

print(f"Evidence harness integrity OK. Evidence: {out_path}")
PY
