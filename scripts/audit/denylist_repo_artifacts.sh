#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/scripts/lib/evidence.sh"

deny_name=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --deny)
      deny_name="${2:-}"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -z "$deny_name" ]]; then
  echo "Usage: $0 --deny <artifact-name>" >&2
  exit 2
fi

EVIDENCE_FILE="$REPO_ROOT/evidence/security_remediation/r_011_repo_hygiene.json"
mkdir -p "$(dirname "$EVIDENCE_FILE")"

mapfile -t matches < <(cd "$REPO_ROOT" && git ls-files | rg -n "(^|/)${deny_name}$" | sed 's/^[0-9]*://')

status="PASS"
denylist_enforced=true
if [[ "${#matches[@]}" -gt 0 ]]; then
  status="FAIL"
  denylist_enforced=false
fi

matches_json="[]"
if [[ "${#matches[@]}" -gt 0 ]]; then
  matches_json="$(printf '%s\n' "${matches[@]}" | jq -R . | jq -s .)"
fi

cat > "$EVIDENCE_FILE" <<JSON
{
  "task_id": "R-011",
  "git_sha": "$(get_git_sha)",
  "timestamp_utc": "$(get_timestamp_utc)",
  "status": "$status",
  "checks": [
    {
      "id": "R-011-A1",
      "description": "denylisted artifact is absent from git-tracked files",
      "status": "$status",
      "details": {
        "deny_name": "$deny_name",
        "matches": $matches_json
      }
    }
  ],
  "denylist_enforced": $denylist_enforced
}
JSON

echo "Evidence: $EVIDENCE_FILE"
if [[ "$status" != "PASS" ]]; then
  echo "❌ Denylisted artifact found: $deny_name"
  exit 1
fi

echo "✅ Denylisted artifact absent: $deny_name"
