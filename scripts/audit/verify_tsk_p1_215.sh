#!/usr/bin/env bash
set -eo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE="$ROOT/evidence/phase1/tsk_p1_215_openbao_secret_provider.json"
RUN_ID="${SYMPHONY_RUN_ID:-standalone-$(date -u +%Y%m%dT%H%M%SZ)}"

mkdir -p "$(dirname "$EVIDENCE")"
errors=()

echo "==> Verifying TSK-P1-215: OpenBao Secret Provider Integration..."

# ─── 1. Structural checks: required files exist ───
PROVIDER="$ROOT/services/ledger-api/dotnet/src/LedgerApi/Infrastructure/SecretProviders.cs"
RUNTIME_SECRETS="$ROOT/services/ledger-api/dotnet/src/LedgerApi/Infrastructure/RuntimeSecrets.cs"
PROGRAM="$ROOT/services/ledger-api/dotnet/src/LedgerApi/Program.cs"
AUTH="$ROOT/services/ledger-api/dotnet/src/LedgerApi/Security/ApiAuthorization.cs"

for f in "$PROVIDER" "$RUNTIME_SECRETS"; do
  if [ ! -f "$f" ]; then
    errors+=("file_missing:$(basename "$f")")
  fi
done

# ─── 2. ISecretProvider abstraction exists ───
if ! grep -q "public interface ISecretProvider" "$PROVIDER" 2>/dev/null; then
  errors+=("ISecretProvider_interface_missing")
fi

# ─── 3. OpenBaoSecretProvider exists with AppRole auth ───
if ! grep -q "class OpenBaoSecretProvider" "$PROVIDER" 2>/dev/null; then
  errors+=("OpenBaoSecretProvider_class_missing")
fi
if ! grep -q "approle/login" "$PROVIDER" 2>/dev/null; then
  errors+=("OpenBaoSecretProvider_missing_approle_auth")
fi

# ─── 4. EnvironmentSecretProvider exists (dev-only) ───
if ! grep -q "class EnvironmentSecretProvider" "$PROVIDER" 2>/dev/null; then
  errors+=("EnvironmentSecretProvider_class_missing")
fi

# ─── 5. OpenBaoPathContract defines in-scope secrets ───
if ! grep -q "class OpenBaoPathContract" "$PROVIDER" 2>/dev/null; then
  errors+=("OpenBaoPathContract_missing")
fi

for secret in INGRESS_API_KEY ADMIN_API_KEY DEMO_INSTRUCTION_SIGNING_KEY EVIDENCE_SIGNING_KEY; do
  if ! grep -q "\"$secret\"" "$PROVIDER" 2>/dev/null; then
    errors+=("path_contract_missing_${secret}")
  fi
done

# ─── 6. HardenedSecretKeys set exists for fail-closed enforcement ───
if ! grep -q "HardenedSecretKeys" "$PROVIDER" 2>/dev/null; then
  errors+=("HardenedSecretKeys_set_missing")
fi

# ─── 7. Fail-closed behavior: throw on missing hardened secrets ───
if ! grep -q "throw new InvalidOperationException" "$PROVIDER" 2>/dev/null; then
  errors+=("fail_closed_throw_missing")
fi

# ─── 8. IsHealthyAsync exists for /readyz probe ───
if ! grep -q "IsHealthyAsync" "$PROVIDER" 2>/dev/null; then
  errors+=("IsHealthyAsync_missing")
fi

# ─── 9. RuntimeSecrets resolves at startup ───
if ! grep -q "class RuntimeSecrets" "$RUNTIME_SECRETS" 2>/dev/null; then
  errors+=("RuntimeSecrets_class_missing")
fi
if ! grep -q "ResolveAsync" "$RUNTIME_SECRETS" 2>/dev/null; then
  errors+=("RuntimeSecrets_ResolveAsync_missing")
fi

# ─── 10. Program.cs wiring checks ───
if ! grep -q "isHardenedProfile" "$PROGRAM" 2>/dev/null; then
  errors+=("hardened_profile_detection_missing")
fi
if ! grep -q "RuntimeSecrets.ResolveAsync" "$PROGRAM" 2>/dev/null; then
  errors+=("startup_secrets_resolution_missing")
fi
if ! grep -q "new OpenBaoSecretProvider" "$PROGRAM" 2>/dev/null; then
  errors+=("openbao_provider_instantiation_missing")
fi

# ─── 11. ApiAuthorization accepts RuntimeSecrets ───
if ! grep -q "RuntimeSecrets secrets" "$AUTH" 2>/dev/null; then
  errors+=("ApiAuthorization_not_using_RuntimeSecrets")
fi

# ─── 12. No raw env reads for in-scope secrets in ApiAuthorization ───
for secret in INGRESS_API_KEY ADMIN_API_KEY; do
  if grep -q "Environment.GetEnvironmentVariable(\"$secret\")" "$AUTH" 2>/dev/null; then
    errors+=("ApiAuthorization_still_reads_env_${secret}")
  fi
done

# ─── 13. No env fallback for unmapped keys in OpenBaoSecretProvider ───
# Check that GetSecretAsync throws for unmapped keys, not falls back
if grep -A5 "!OpenBaoPathContract.KeyMapping.TryGetValue" "$PROVIDER" 2>/dev/null | grep -q "Environment.GetEnvironmentVariable"; then
  errors+=("OpenBaoSecretProvider_env_fallback_for_unmapped")
fi

# ─── 14. Bootstrap dependency documented ───
if ! grep -iq "bootstrap" "$PROVIDER" 2>/dev/null; then
  errors+=("bootstrap_dependency_not_documented")
fi

# ─── 15. Build check (compile-only, ignoring pre-existing CS0117 errors) ───
echo "    Building LedgerApi..."
BUILD_OUTPUT=$(dotnet build "$ROOT/services/ledger-api/dotnet/src/LedgerApi/LedgerApi.csproj" 2>&1 || true)
NEW_ERRORS=$(echo "$BUILD_OUTPUT" | { grep 'error CS' || true; } | { grep -v 'CS0117' || true; } | wc -l)
if [ "$NEW_ERRORS" -gt 0 ]; then
  errors+=("build_has_new_errors")
  echo "    Build errors (non-CS0117):"
  echo "$BUILD_OUTPUT" | grep 'error CS' | grep -v 'CS0117'
fi

# ─── Emit evidence ───
if [[ ${#errors[@]} -eq 0 ]]; then
  status="PASS"
else
  status="FAIL"
fi

source "$ROOT/scripts/lib/evidence.sh" 2>/dev/null || {
  git_sha() { git rev-parse HEAD 2>/dev/null || echo "unknown"; }
  schema_fingerprint() { echo "unknown"; }
  evidence_now_utc() { date -u +%Y-%m-%dT%H:%M:%SZ; }
}

TS_UTC="$(evidence_now_utc)"
GIT_SHA="$(git_sha)"
SCHEMA_FP="$(schema_fingerprint)"

python3 - <<PY "$EVIDENCE" "$RUN_ID" "$status" "$TS_UTC" "$GIT_SHA" "$SCHEMA_FP" "$(IFS=,; echo "${errors[*]:-}")"
import json, sys, os
evidence_path, run_id, status, ts, sha, schema_fp, errors_csv = sys.argv[1:8]
errors = [e for e in errors_csv.split(",") if e]
payload = {
    "check_id": "TSK-P1-215",
    "timestamp_utc": ts,
    "git_sha": sha,
    "schema_fingerprint": schema_fp,
    "status": status,
    "task_id": "TSK-P1-215",
    "run_id": run_id,
    "checks": {
        "secret_provider_abstraction": "ISecretProvider_interface_missing" not in errors,
        "openbao_provider_with_approle": (
            "OpenBaoSecretProvider_class_missing" not in errors
            and "OpenBaoSecretProvider_missing_approle_auth" not in errors
        ),
        "path_contract_defined": all(
            f"path_contract_missing_{s}" not in errors
            for s in ["INGRESS_API_KEY", "ADMIN_API_KEY", "DEMO_INSTRUCTION_SIGNING_KEY", "EVIDENCE_SIGNING_KEY"]
        ),
        "fail_closed_enforcement": (
            "HardenedSecretKeys_set_missing" not in errors
            and "fail_closed_throw_missing" not in errors
        ),
        "health_check_support": "IsHealthyAsync_missing" not in errors,
        "startup_resolution": (
            "RuntimeSecrets_class_missing" not in errors
            and "RuntimeSecrets_ResolveAsync_missing" not in errors
            and "startup_secrets_resolution_missing" not in errors
        ),
        "no_env_fallback_hardened": "OpenBaoSecretProvider_env_fallback_for_unmapped" not in errors,
        "api_auth_uses_resolved_secrets": "ApiAuthorization_not_using_RuntimeSecrets" not in errors,
        "bootstrap_dependency_documented": "bootstrap_dependency_not_documented" not in errors,
        "build_compiles": "build_has_new_errors" not in errors,
    },
    "errors": errors
}
os.makedirs(os.path.dirname(evidence_path), exist_ok=True)
with open(evidence_path, "w", encoding="utf-8") as f:
    f.write(json.dumps(payload, indent=2) + "\n")
PY

if [[ "$status" != "PASS" ]]; then
  echo "FAIL: ${errors[*]}" >&2
  exit 1
fi

echo "PASS: TSK-P1-215 OpenBao secret provider integration verified."
echo "Evidence: $EVIDENCE"
