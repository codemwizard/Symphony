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
#   Scans both PLAN.md and EXEC_LOG.md per casefile ΓÇö root causes and
#   resolution details often live in EXEC_LOG.md.
#
#   Output: docs/operations/failure_index.md
#
# USAGE:
#   bash scripts/audit/build_failure_index.sh

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

# Preflight: verify Python and PyYAML are available before doing any work.
# Fail with a clear message rather than a confusing ModuleNotFoundError mid-run.
if ! python3 -c "import yaml" 2>/dev/null; then
  echo "ERROR: PyYAML is required but not installed." >&2
  echo "  Install it with:  pip install pyyaml  (or: pip install pyyaml --break-system-packages)" >&2
  echo "  Or add pyyaml to your requirements.txt and run: pip install -r requirements.txt" >&2
  exit 1
fi

REGISTRY="docs/operations/failure_signatures.yml"
INDEX_OUT="docs/operations/failure_index.md"
CASES_GLOB="docs/plans"

echo "==> Building failure index from remediation casefiles..."

# Collect all REM-* PLAN.md and EXEC_LOG.md files, deduplicated by casefile directory.
# PLAN.md is the primary source; EXEC_LOG.md is scanned for additional fields
# (root cause, resolution) that agents typically write there rather than in PLAN.md.
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
from pathlib import Path
from datetime import datetime, timezone

root = Path(os.getcwd())
registry_path = Path(os.environ["REGISTRY_PATH"])
index_out = Path(os.environ["INDEX_OUT"])
all_files = json.loads(os.environ["PLAN_FILES_JSON"])

# Load signature registry using yaml.safe_load ΓÇö handles multiline descriptions
# and any other valid YAML constructs without brittle line-by-line parsing.
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
# into one entry per incident rather than creating two separate index rows.
from collections import defaultdict
by_dir = defaultdict(list)
for f in all_files:
    p = Path(f)
    by_dir[p.parent].append(p)

entries = []
for case_dir_path, file_list in by_dir.items():
    # Merge text from all files in the casefile directory
    combined_text = ""
    for fp in sorted(file_list):
        combined_text += fp.read_text(encoding="utf-8", errors="ignore") + "\n"

    sig_match = re.search(r"^failure_signature:\s*(.+)$", combined_text, re.MULTILINE)
    gate_match = re.search(r"^origin_gate_id:\s*(.+)$", combined_text, re.MULTILINE)
    status_match = re.search(r"^final_status:\s*(.+)$", combined_text, re.MULTILINE)
    repro_match = re.search(r"^repro_command:\s*(.+)$", combined_text, re.MULTILINE)

    signature = sig_match.group(1).strip() if sig_match else "UNKNOWN"
    gate = gate_match.group(1).strip() if gate_match else ""
    status = status_match.group(1).strip() if status_match else "UNKNOWN"
    repro = repro_match.group(1).strip() if repro_match else ""

    # Fail on casefiles missing a failure_signature ΓÇö silent UNKNOWN classification
    # makes incidents undiscoverable. Treat a missing field as a malformed casefile
    # and refuse to build a misleading index. Fix the casefile, then re-run.
    if signature == "UNKNOWN":
        print(f"ERROR: {case_dir_path} is missing a failure_signature field.", file=sys.stderr)
        print(f"  Add 'failure_signature: PRECI.YOUR.SIGNATURE' to PLAN.md or EXEC_LOG.md.", file=sys.stderr)
        sys.exit(1)

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

# Group by signature, most recent first within each group
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
    f"Casefiles scanned: {len(entries)}",
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
        status_icon = "Γ£à" if e["status"] == "RESOLVED" else "≡ƒö┤" if e["status"] == "OPEN" else "ΓÜá∩╕Å"
        lines.append(f"- {status_icon} `{e['case_dir']}` ({e['date']}) ΓÇö status: {e['status']}")
        lines.append(f"  - Plan: `{e['plan_path']}`")
        if e["repro"]:
            lines.append(f"  - Repro: `{e['repro']}`")
    if len(sig_entries) > 5:
        lines.append(f"- ... and {len(sig_entries) - 5} more")
    lines.append("")
    lines.append("---")
    lines.append("")

index_out.parent.mkdir(parents=True, exist_ok=True)
# Write atomically: write to a temp file first, then rename into place.
# This prevents a partial or corrupted index if two runs overlap.
import tempfile
tmp_path = index_out.with_suffix(".tmp")
tmp_path.write_text("\n".join(lines), encoding="utf-8")
tmp_path.replace(index_out)
print(f"Index written: {index_out} ({len(by_sig)} signatures, {len(entries)} casefiles)")
PY

echo "==> Failure index built: $INDEX_OUT"
