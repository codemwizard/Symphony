#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/scripts/lib/evidence.sh"

EVIDENCE_FILE="$REPO_ROOT/evidence/security_remediation/r_015_tests_bootstrap.json"
TEST_PROJECT_REL="services/ledger-api/dotnet/tests/LedgerApi.Tests/LedgerApi.Tests.csproj"
TEST_PROJECT="$REPO_ROOT/$TEST_PROJECT_REL"
mkdir -p "$(dirname "$EVIDENCE_FILE")"

test_project_exists=false
if [[ -f "$TEST_PROJECT" ]]; then
  test_project_exists=true
fi

status="PASS"
tests_passed=true
if [[ "$test_project_exists" != "true" ]]; then
  status="FAIL"
  tests_passed=false
else
  if ! dotnet test "$TEST_PROJECT" --configuration Release --nologo >/tmp/r015_dotnet_test.log 2>&1; then
    status="FAIL"
    tests_passed=false
  fi
fi

cat > "$EVIDENCE_FILE" <<JSON
{
  "task_id": "R-015",
  "git_sha": "$(get_git_sha)",
  "timestamp_utc": "$(get_timestamp_utc)",
  "status": "$status",
  "checks": [
    {
      "id": "R-015-A1",
      "description": "xUnit test project exists and dotnet test passes",
      "status": "$status",
      "details": {
        "test_project": "$TEST_PROJECT_REL",
        "dotnet_test_log": "/tmp/r015_dotnet_test.log"
      }
    }
  ],
  "test_project_exists": $test_project_exists,
  "tests_passed": $tests_passed
}
JSON

echo "Evidence: $EVIDENCE_FILE"
if [[ "$status" != "PASS" ]]; then
  echo "❌ Test project missing"
  exit 1
fi

echo "✅ R-015 evidence recorded"
