#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/scripts/lib/evidence.sh"

PROJECT_DIR="$REPO_ROOT/services/ledger-api/dotnet/src/LedgerApi.DemoHost"
EVIDENCE_FILE="$REPO_ROOT/evidence/security_remediation/r_014_refactor.json"
mkdir -p "$(dirname "$EVIDENCE_FILE")"

export INGRESS_API_KEY="r014-test-ingress-key"
export ADMIN_API_KEY="r014-test-admin-key"
export SYMPHONY_KNOWN_TENANTS="known-tenant-r014"
export SYMPHONY_ENV="development"
export EVIDENCE_SIGNING_KEY="r014-test-signing-key"

modes=(
  "--self-test"
  "--self-test-evidence-pack"
  "--self-test-case-pack"
  "--self-test-authz"
  "--self-test-reg-daily-report"
  "--self-test-reg-incident-48h-report"
)

pushd "$PROJECT_DIR" >/dev/null

dotnet build >/dev/null

checks=()
status="PASS"
for mode in "${modes[@]}"; do
  if dotnet run --no-build -- "$mode" >/tmp/r014_self_test.log 2>&1; then
    checks+=("{\"id\":\"selftest-${mode#--}\",\"description\":\"dotnet self-test $mode\",\"status\":\"PASS\",\"details\":{\"mode\":\"$mode\"}}")
  else
    status="FAIL"
    log_tail=$(tail -n 40 /tmp/r014_self_test.log | jq -Rs .)
    checks+=("{\"id\":\"selftest-${mode#--}\",\"description\":\"dotnet self-test $mode\",\"status\":\"FAIL\",\"details\":{\"mode\":\"$mode\",\"log_tail\":$log_tail}}")
  fi
done

popd >/dev/null

checks_json="[$(IFS=,; echo "${checks[*]}")]"
self_tests_passed=false
if [[ "$status" == "PASS" ]]; then
  self_tests_passed=true
fi

cat > "$EVIDENCE_FILE" <<JSON
{
  "task_id": "R-014",
  "git_sha": "$(get_git_sha)",
  "timestamp_utc": "$(get_timestamp_utc)",
  "status": "$status",
  "checks": $checks_json,
  "refactor_completed": true,
  "self_tests_passed": $self_tests_passed
}
JSON

echo "Evidence: $EVIDENCE_FILE"
if [[ "$status" != "PASS" ]]; then
  echo "❌ One or more self-tests failed"
  exit 1
fi

echo "✅ Dotnet self-tests passed"
