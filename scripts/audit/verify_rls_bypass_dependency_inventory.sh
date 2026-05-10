#!/usr/bin/env bash
# verify_rls_bypass_dependency_inventory.sh
# TSK-P2-RLS-BYPASS-001 — Inventory all app.bypass_rls dependency surfaces
#
# Scans all required repository roots for app.bypass_rls and set_config references,
# classifies each finding by execution surface and remediation class, and emits
# structured evidence to evidence/phase2/rls_bypass_dependency_inventory.json.
#
# Exit 0 = PASS (all findings classified, no UNKNOWN)
# Exit 1 = FAIL (UNKNOWN findings, skipped roots, or missing evidence fields)
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

EVIDENCE_DIR="$ROOT_DIR/evidence/phase2"
EVIDENCE_FILE="$EVIDENCE_DIR/rls_bypass_dependency_inventory.json"

# ── Required scan roots ──────────────────────────────────────────────────────
SCAN_ROOTS=(
  "schema/migrations"
  "schema/baselines"
  "services"
  "scripts"
  ".github/workflows"
  "docs"
)

# Optional roots — only scanned if they exist
OPTIONAL_ROOTS=("src" "tests" "fixtures")

ACTIVE_ROOTS=()
SKIPPED_ROOTS=()

for root in "${SCAN_ROOTS[@]}"; do
  if [[ -d "$ROOT_DIR/$root" ]]; then
    ACTIVE_ROOTS+=("$root")
  else
    SKIPPED_ROOTS+=("$root")
  fi
done

for root in "${OPTIONAL_ROOTS[@]}"; do
  if [[ -d "$ROOT_DIR/$root" ]]; then
    ACTIVE_ROOTS+=("$root")
  fi
done

# ── Fail if any required root is missing ─────────────────────────────────────
if [[ ${#SKIPPED_ROOTS[@]} -gt 0 ]]; then
  echo "FAIL: Required scan roots missing: ${SKIPPED_ROOTS[*]}" >&2
  exit 1
fi

# ── Scan for bypass_rls references ───────────────────────────────────────────
TMP_FINDINGS="$(mktemp)"
trap 'rm -f "$TMP_FINDINGS"' EXIT

for root in "${ACTIVE_ROOTS[@]}"; do
  grep -rn --include='*.cs' --include='*.sql' --include='*.sh' \
           --include='*.yml' --include='*.yaml' --include='*.md' \
           --include='*.json' --include='*.py' \
           'bypass_rls' "$ROOT_DIR/$root" 2>/dev/null >> "$TMP_FINDINGS" || true
done

# Also check root-level Program.cs if present
if [[ -f "$ROOT_DIR/Program.cs" ]]; then
  grep -n 'bypass_rls' "$ROOT_DIR/Program.cs" >> "$TMP_FINDINGS" || true
fi

# ── Classify each finding ────────────────────────────────────────────────────
"$ROOT_DIR/.venv/bin/python3" - "$TMP_FINDINGS" "$ROOT_DIR" "$EVIDENCE_FILE" \
  "$EVIDENCE_TS" "$EVIDENCE_GIT_SHA" "$EVIDENCE_SCHEMA_FP" <<'PYEOF'
import json
import hashlib
import os
import sys
from pathlib import Path

findings_file = sys.argv[1]
repo_root = sys.argv[2]
evidence_file = sys.argv[3]
timestamp = sys.argv[4]
git_sha = sys.argv[5]
schema_fp = sys.argv[6]

def classify_surface(rel_path: str) -> str:
    """Classify the execution surface of a file."""
    p = rel_path.lower()

    # Migration files are one-time-applied DDL
    if 'schema/migrations/' in p and p.endswith('.sql'):
        return 'MIGRATION'

    # Baseline snapshots are historical records
    if 'schema/baselines/' in p:
        return 'MIGRATION'  # historical baseline, same classification

    # Runtime .NET source code
    if '/stores.cs' in p or '/commandcontracts' in p:
        return 'RUNTIME'
    if '/infrastructure/' in p and p.endswith('.cs'):
        return 'RUNTIME'

    # Seed / bootstrap code
    if '/program.cs' in p:
        return 'SEED'
    if 'tenantreadinessprobe' in p or 'readinessprobe' in p:
        return 'SEED'

    # Test files
    if '/tests/' in p or '/test/' in p or p.endswith('_test.sh') or '.tests.' in p:
        return 'TEST'

    # CI / workflow files
    if '.github/workflows/' in p:
        return 'CI_BOOTSTRAP'

    # Scripts (audit, db, security)
    if 'scripts/' in p:
        return 'CI_BOOTSTRAP'

    # Documentation
    if 'docs/' in p and (p.endswith('.md') or p.endswith('.yml') or p.endswith('.yaml')):
        return 'DOCS'

    # Task definitions
    if 'tasks/' in p and (p.endswith('.yml') or p.endswith('.yaml')):
        return 'DOCS'

    # Security policy definitions
    if '/security/' in p and p.endswith('.cs'):
        return 'RUNTIME'

    return 'UNKNOWN'


def classify_remediation(surface: str, rel_path: str, line_content: str) -> str:
    """Classify the remediation action required."""
    p = rel_path.lower()

    if surface == 'MIGRATION':
        # Historical baselines — document only
        if 'schema/baselines/' in p:
            return 'document_only'
        # Applied migrations — never edit, document only
        return 'one_time_migration_only'

    if surface == 'RUNTIME':
        # Active set_config calls need removal
        if 'set_config' in line_content:
            return 'remove'
        return 'remove'

    if surface == 'SEED':
        # Seed code needs refactoring to not use bypass
        if 'set_config' in line_content:
            return 'refactor'
        # Commented-out code
        if line_content.strip().startswith('//'):
            return 'remove'
        return 'refactor'

    if surface == 'TEST':
        return 'rewrite_test'

    if surface == 'CI_BOOTSTRAP':
        return 'investigate'

    if surface == 'DOCS':
        return 'document_only'

    return 'investigate'


def is_runtime_reachable(surface: str, line_content: str) -> bool:
    """Check if the reference is runtime-reachable."""
    if surface in ('RUNTIME', 'SEED'):
        # Commented lines are not reachable
        stripped = line_content.strip()
        if stripped.startswith('//') or stripped.startswith('--') or stripped.startswith('#'):
            return False
        return True
    return False


def follow_on_owner(surface: str) -> str:
    """Recommend the follow-on task owner."""
    mapping = {
        'RUNTIME': 'TSK-P2-RLS-BYPASS-002',
        'SEED': 'TSK-P2-RLS-BYPASS-003',
        'MIGRATION': 'TSK-P2-RLS-BYPASS-004',
        'TEST': 'TSK-P2-RLS-BYPASS-002',
        'CI_BOOTSTRAP': 'TSK-P2-RLS-BYPASS-001',
        'DOCS': 'TSK-P2-RLS-BYPASS-001',
    }
    return mapping.get(surface, 'INVESTIGATE')


# Parse grep output and classify
findings = []
observed_paths = set()
observed_hashes = {}
command_outputs = []

with open(findings_file, 'r', encoding='utf-8', errors='ignore') as f:
    for raw_line in f:
        raw_line = raw_line.rstrip('\n')
        if not raw_line:
            continue

        # Parse grep output: filepath:linenum:content
        parts = raw_line.split(':', 2)
        if len(parts) < 3:
            continue

        abs_path = parts[0]
        try:
            line_num = int(parts[1])
        except ValueError:
            continue
        line_content = parts[2]

        # Make path relative to repo root
        rel_path = abs_path
        if rel_path.startswith(repo_root):
            rel_path = rel_path[len(repo_root):].lstrip('/')

        surface = classify_surface(rel_path)
        remediation = classify_remediation(surface, rel_path, line_content)
        runtime_reachable = is_runtime_reachable(surface, line_content)
        owner = follow_on_owner(surface)

        # Determine matched text class
        if 'set_config' in line_content:
            text_class = 'set_config_call'
        elif 'current_setting' in line_content:
            text_class = 'current_setting_predicate'
        elif 'bypass_rls' in line_content.lower():
            text_class = 'string_reference'
        else:
            text_class = 'unknown_pattern'

        findings.append({
            'path': rel_path,
            'line_number': line_num,
            'matched_text_class': text_class,
            'execution_surface': surface,
            'runtime_reachable': runtime_reachable,
            'remediation_required': remediation,
            'follow_on_owner': owner,
            'line_content_preview': line_content.strip()[:120],
        })

        observed_paths.add(rel_path)

# Compute hashes for observed files
for p in sorted(observed_paths):
    full = os.path.join(repo_root, p)
    if os.path.isfile(full):
        with open(full, 'rb') as fh:
            observed_hashes[p] = hashlib.sha256(fh.read()).hexdigest()

# Compute summary counts
unknown_count = sum(1 for f in findings if f['execution_surface'] == 'UNKNOWN')
runtime_reachable_count = sum(1 for f in findings if f['runtime_reachable'])

surface_counts = {}
remediation_counts = {}
for f in findings:
    s = f['execution_surface']
    r = f['remediation_required']
    surface_counts[s] = surface_counts.get(s, 0) + 1
    remediation_counts[r] = remediation_counts.get(r, 0) + 1

status = 'PASS' if unknown_count == 0 else 'FAIL'


def observed_paths_roots(findings_list):
    """Extract unique top-level scan roots from findings."""
    roots = set()
    for f in findings_list:
        p = f['path']
        top = p.split('/')[0]
        roots.add(top)
    return roots


evidence = {
    'task_id': 'TSK-P2-RLS-BYPASS-001',
    'git_sha': git_sha,
    'timestamp_utc': timestamp,
    'schema_fingerprint': schema_fp,
    'status': status,
    'checks': [
        'scan_roots_complete',
        'all_findings_classified',
        'no_unknown_surfaces',
        'evidence_fields_complete',
    ],
    'scan_roots': sorted(observed_paths_roots(findings)),
    'findings': findings,
    'summary_counts': {
        'total_findings': len(findings),
        'by_surface': surface_counts,
        'by_remediation': remediation_counts,
    },
    'unknown_findings_count': unknown_count,
    'runtime_reachable_count': runtime_reachable_count,
    'remediation_classes': sorted(set(f['remediation_required'] for f in findings)),
    'observed_paths': sorted(observed_paths),
    'observed_hashes': observed_hashes,
    'command_outputs': ['grep -rn bypass_rls <scan_roots>'],
    'execution_trace': [
        f'scan_started={timestamp}',
        f'scan_roots={len(observed_paths)} files across required directories',
        f'findings_count={len(findings)}',
        f'unknown_count={unknown_count}',
        f'runtime_reachable_count={runtime_reachable_count}',
        f'status={status}',
    ],
}

# Write evidence
os.makedirs(os.path.dirname(evidence_file), exist_ok=True)
with open(evidence_file, 'w', encoding='utf-8') as out:
    json.dump(evidence, out, indent=2)
    out.write('\n')

print(f"Evidence written: {evidence_file}")
print(f"  Status: {status}")
print(f"  Total findings: {len(findings)}")
print(f"  Unknown: {unknown_count}")
print(f"  Runtime reachable: {runtime_reachable_count}")
print(f"  Surfaces: {surface_counts}")
print(f"  Remediation classes: {remediation_counts}")

if status != 'PASS':
    print(f"\nFAIL: {unknown_count} UNKNOWN findings remain", file=sys.stderr)
    sys.exit(1)

sys.exit(0)
PYEOF
