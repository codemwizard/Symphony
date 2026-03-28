#!/usr/bin/env bash
set -euo pipefail

# validate_failure_registry.sh
# TARGET: scripts/audit/validate_failure_registry.sh
#
# PURPOSE:
#   Validates docs/operations/failure_signatures.yml against required schema.
#   Run this after editing the registry to catch typos before they silently
#   drop playbook links from the failure index or lockout guidance.
#
#   Required fields per signature:
#     description, remediation_playbook, drd_level, owner
#
#   Valid drd_level values: L0, L1, L2, L3
#
# USAGE:
#   bash scripts/audit/validate_failure_registry.sh
#   bash scripts/audit/validate_failure_registry.sh --registry path/to/custom.yml

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

REGISTRY="${1:-docs/operations/failure_signatures.yml}"
if [[ "$1" == "--registry" ]]; then
  REGISTRY="${2:-}"
fi

if [[ ! -f "$REGISTRY" ]]; then
  echo "ERROR: Registry not found: $REGISTRY" >&2
  exit 1
fi

if ! python3 -c "import yaml" 2>/dev/null; then
  echo "ERROR: PyYAML is required. Install with: pip install pyyaml" >&2
  exit 1
fi

python3 - "$REGISTRY" <<'PY'
import sys, yaml

REQUIRED_FIELDS = ["description", "remediation_playbook", "drd_level", "owner"]
VALID_DRD_LEVELS = {"L0", "L1", "L2", "L3"}

registry_path = sys.argv[1]
try:
    data = yaml.safe_load(open(registry_path, encoding="utf-8")) or {}
except yaml.YAMLError as e:
    print(f"ERROR: YAML parse error in {registry_path}:", file=sys.stderr)
    print(f"  {e}", file=sys.stderr)
    sys.exit(1)

errors = []
for sig, entry in data.items():
    if not isinstance(entry, dict):
        errors.append(f"  {sig}: entry is not a mapping (got {type(entry).__name__})")
        continue
    for field in REQUIRED_FIELDS:
        if not entry.get(field):
            errors.append(f"  {sig}: missing or empty required field '{field}'")
    drd = entry.get("drd_level", "")
    if drd and drd not in VALID_DRD_LEVELS:
        errors.append(f"  {sig}: invalid drd_level '{drd}' (must be one of {sorted(VALID_DRD_LEVELS)})")

if errors:
    print(f"Registry validation FAILED: {registry_path}", file=sys.stderr)
    for e in errors:
        print(e, file=sys.stderr)
    sys.exit(1)
else:
    print(f"Registry OK: {registry_path} ({len(data)} signatures, all required fields present)")
PY
