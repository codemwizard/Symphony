#!/usr/bin/env bash
set -euo pipefail

# build_failure_index.sh
# TARGET: scripts/audit/build_failure_index.sh
#
# PURPOSE:
#   Scans all remediation casefiles (docs/plans/**/REM-*) and extracts
#   failure signatures, root causes, and solutions into a searchable index.
#   Cross-references docs/operations/failure_signatures.yml to annotate each
#   entry with the known remediation playbook.
#
#   Scans both PLAN.md and EXEC_LOG.md per casefile — root causes and
#   resolution details often live in EXEC_LOG.md.
#
#   Casefiles without a bare failure_signature: field are skipped with a
#   warning. This is intentional — many casefiles predate the machine-readable
#   field convention and should not be required to conform to it.
#
#   Output: docs/operations/failure_index.md
#
# USAGE:
#   bash scripts/audit/build_failure_index.sh

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

# Preflight: verify Python and PyYAML are available before doing any work.
if ! python3 -c "import yaml" 2>/dev/null; then
  echo "ERROR: PyYAML is required but not installed." >&2
  echo "  Install with: pip install pyyaml --break-system-packages" >&2
  exit 1
fi

REGISTRY="docs/operations/failure_signatures.yml"
INDEX_OUT="docs/operations/failure_index.md"
CASES_GLOB="docs/plans"

echo "==> Building failure index from remediation casefiles..."

# Collect all REM-* PLAN.md and EXEC_LOG.md files.
# PLAN.md is the primary source; EXEC_LOG.md is scanned for additional fields
# (root cause, resolution) that agents typically write there rather than PLAN.md.
mapfile -t PLAN_FILES < <(find "$CASES_GLOB" -type f \( -name "PLAN.md" -o -name "EXEC_LOG.md" \) -path "*/REM-*" | sort)

if [[ ${#PLAN_FILES[@]} -eq 0 ]]; then
  echo "No remediation casefiles found under $CASES_GLOB"
  exit 0
fi

echo "Found ${#PLAN_FILES[@]} casefile documents (PLAN.md + EXEC_LOG.md)"

REGISTRY_PATH="$ROOT/$REGISTRY" \
PLAN_FILES_JSON="$(printf '%s\n' "${PLAN_FILES[@]}" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().splitlines()))')" \
INDEX_OUT="$ROOT/$INDEX_OUT" \
python3 - <<'PY'
import json
import os
import re
import sys
import yaml
from collections import defaultdict
from pathlib import Path
from datetime import datetime, timezone

root = Path(os.getcwd())
registry_path = Path(os.environ["REGISTRY_PATH"])
index_out = Path(os.environ["INDEX_OUT"])
all_files = json.loads(os.environ["PLAN_FILES_JSON"])

# Load signature registry using yaml.safe_load.
registry = {}
if registry_path.exists():
    raw = yaml.safe_load(registry_path.read_text(encoding="utf-8")) or {}
    for sig, entry in raw.items():
        if isinstance(entry, dict):
            registry[sig] = {
                "description": str(entry.get("description", "")).strip(),
                "remediation_playbook": str(entry.get("remediation_playbook", "")).strip(),
                "drd_level": str(entry.get("drd_level", "")).strip(),
                "owner": str(entry.get("owner", "")).strip(),
            }

# Group files by casefile directory so PLAN.md and EXEC_LOG.md are merged
# into one entry per incident.
by_dir = defaultdict(list)
for f in all_files:
    p = Path(f)
    by_dir[p.parent].append(p)

entries = []
skipped = []

for case_dir_path, file_list in by_dir.items():
    combined_text = ""
    for fp in sorted(file_list):
        combined_text += fp.read_text(encoding="utf-8", errors="ignore") + "\n"

    sig_match = re.search(r"^failure_signature:\s*(\S.*)$", combined_text, re.MULTILINE)
    gate_match = re.search(r"^origin_gate_id:\s*(\S.*)$", combined_text, re.MULTILINE)
    status_match = re.search(r"^final_status:\s*(\S.*)$", combined_text, re.MULTILINE)
    repro_match = re.search(r"^repro_command:\s*(\S.*)$", combined_text, re.MULTILINE)

    # Casefiles without a bare failure_signature: field are skipped, not failed.
    # Many casefiles predate the machine-readable convention — they should not
    # be required to conform to it. New casefiles created by
    # new_remediation_casefile.sh will always have the field.
    if not sig_match:
        skipped.append(str(case_dir_path))
        continue

    signature = sig_match.group(1).strip()
    gate = gate_match.group(1).strip() if gate_match else ""
    status = status_match.group(1).strip() if status_match else "UNKNOWN"
    repro = repro_match.group(1).strip() if repro_match else ""

    case_dir = case_dir_path.name
    date_match = re.match(r"REM-(\d{4}-\d{2}-\d{2})", case_dir)
    case_date = date_match.group(1) if date_match else "unknown"

    reg_entry = registry.get(signature, {})

    entries.append({
        "signature": signature,
        "gate": gate,
        "status": status,
        "repro": repro,
        "date": case_date,
        "case_dir": case_dir,
        "plan_path": str(case_dir_path / "PLAN.md"),
        "description": reg_entry.get("description", ""),
        "playbook": reg_entry.get("remediation_playbook", ""),
        "drd_level": reg_entry.get("drd_level", ""),
    })

if skipped:
    print(f"NOTE: {len(skipped)} casefile(s) skipped (no bare failure_signature: field — "
          f"pre-convention format):", file=sys.stderr)
    for s in skipped:
        print(f"  {s}", file=sys.stderr)

# Group by signature, most recent first within each group.
by_sig = {}
for e in sorted(entries, key=lambda x: x["date"], reverse=True):
    sig = e["signature"]
    if sig not in by_sig:
        by_sig[sig] = []
    by_sig[sig].append(e)

lines = [
    "# Symphony Failure Index",
    "",
    "Auto-generated by `scripts/audit/build_failure_index.sh`",
    f"Last updated: {datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')}",
    f"Casefiles indexed: {len(entries)} (skipped {len(skipped)} pre-convention)",
    f"Unique signatures: {len(by_sig)}",
    "",
    "Use this index to find prior remediation for a known failure signature.",
    "Search by signature name (e.g., `PRECI.DB.ENVIRONMENT`) to find all prior incidents.",
    "",
    "---",
    "",
]

for sig, sig_entries in sorted(by_sig.items()):
    latest = sig_entries[0]
    lines.append(f"## {sig}")
    if latest["description"]:
        lines.append("")
        lines.append(f"**Description:** {latest['description']}")
    if latest["playbook"]:
        lines.append(f"**Remediation playbook:** `{latest['playbook']}`")
    if latest["drd_level"]:
        lines.append(f"**DRD level:** {latest['drd_level']}")
    lines.append("")
    lines.append(f"**Prior incidents ({len(sig_entries)}):**")
    lines.append("")
    for e in sig_entries[:5]:
        status_icon = "✅" if e["status"] == "RESOLVED" else "🔴" if e["status"] == "OPEN" else "⚠️"
        lines.append(f"- {status_icon} `{e['case_dir']}` ({e['date']}) — status: {e['status']}")
        lines.append(f"  - Plan: `{e['plan_path']}`")
        if e["repro"]:
            lines.append(f"  - Repro: `{e['repro']}`")
    if len(sig_entries) > 5:
        lines.append(f"- ... and {len(sig_entries) - 5} more")
    lines.append("")
    lines.append("---")
    lines.append("")

index_out.parent.mkdir(parents=True, exist_ok=True)
tmp_path = index_out.with_suffix(".tmp")
tmp_path.write_text("\n".join(lines), encoding="utf-8")
tmp_path.replace(index_out)
print(f"Index written: {index_out} ({len(by_sig)} signatures, {len(entries)} indexed, {len(skipped)} skipped)")
PY

echo "==> Failure index built: $INDEX_OUT"
