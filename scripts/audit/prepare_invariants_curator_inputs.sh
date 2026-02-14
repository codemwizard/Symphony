#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
source scripts/audit/lib/git_diff.sh

OUT_DIR="/tmp/invariants_ai"
mkdir -p "$OUT_DIR"

echo "==> Preparing invariants curator inputs (staged diff)"
echo "Repo: $ROOT"
echo "Output dir: $OUT_DIR"
echo ""

# Staged diff only: this is what will go into the commit/PR.
git_write_unified_diff_staged "$OUT_DIR/pr.diff" 0

echo "Wrote: $OUT_DIR/pr.diff"
echo ""

echo "==> Running structural detector on staged diff"
python3 scripts/audit/detect_structural_changes.py \
  --diff-file "$OUT_DIR/pr.diff" \
  --out "$OUT_DIR/detect.json"

echo "Wrote: $OUT_DIR/detect.json"
echo ""

# Friendly summary (best-effort; tolerate older detector output)
python3 - <<'PY' "$OUT_DIR/detect.json" || true
import json, sys
d=json.load(open(sys.argv[1]))
print(f"structural_change={d.get('structural_change')}")
print(f"confidence_hint={d.get('confidence_hint')}")
if d.get("primary_reason"):
  print(f"primary_reason={d.get('primary_reason')}")
if d.get("reason_types"):
  print("reason_types=" + ",".join(d.get("reason_types", [])))
print("")
matches=d.get("matches", [])[:12]
if matches:
  print("Top matches:")
  for m in matches:
    t=m.get("type","?")
    f=m.get("file","?")
    s=m.get("sign","?")
    line=(m.get("line","") or "").strip()
    print(f" - {t} | {f} | {s}: {line}")
PY

echo ""
echo "Next:"
echo "  1) Open .cursor/agents/invariants_curator.md in Cursor"
echo "  2) Run it as an agent prompt"
echo "  3) Apply the docs patch under docs/invariants/**"
echo "  4) Run: scripts/audit/run_invariants_fast_checks.sh"
