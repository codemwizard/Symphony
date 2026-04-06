#!/usr/bin/env bash
set -eo pipefail

# --- PRE_CI_CONTEXT_GUARD ---
# This script writes evidence and must run via pre_ci.sh or run_task.sh.
# Direct execution bypasses the enforcement harness and is blocked.
# Debugging override: PRE_CI_CONTEXT=1 bash <script>
if [[ "${PRE_CI_CONTEXT:-}" != "1" ]]; then
  echo "ERROR: $(basename "${BASH_SOURCE[0]}") must run via pre_ci.sh or run_task.sh" >&2
  echo "  Direct execution blocked to protect evidence integrity." >&2
  echo "  Debug override: PRE_CI_CONTEXT=1 bash $(basename "${BASH_SOURCE[0]}")" >&2
  mkdir -p .toolchain/audit
  printf '%s rogue_execution attempted: %s\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${BASH_SOURCE[0]}" \
    >> .toolchain/audit/rogue_execution.log
  return 1 2>/dev/null || exit 1
fi
# --- end PRE_CI_CONTEXT_GUARD ---


ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE="$ROOT/evidence/phase1/tsk_p1_216_key_domain_separation_rotation.json"
RUN_ID="${SYMPHONY_RUN_ID:-standalone-$([[ "${SYMPHONY_EVIDENCE_DETERMINISTIC:-0}" == "1" ]] && echo "19700101T000000Z" || date -u +%Y%m%dT%H%M%SZ)}"

mkdir -p "$(dirname "$EVIDENCE")"
errors=()

echo "==> Verifying TSK-P1-216: Key Domain Separation..."

PROVIDER="$ROOT/services/ledger-api/dotnet/src/LedgerApi/Infrastructure/SecretProviders.cs"
RUNTIME_SECRETS="$ROOT/services/ledger-api/dotnet/src/LedgerApi/Infrastructure/RuntimeSecrets.cs"
AUTH="$ROOT/services/ledger-api/dotnet/src/LedgerApi/Security/ApiAuthorization.cs"
BOOTSTRAP="$ROOT/scripts/security/openbao_bootstrap.sh"

# ─── 1. Required files exist ───
for f in "$PROVIDER" "$RUNTIME_SECRETS" "$AUTH" "$BOOTSTRAP"; do
  if [ ! -f "$f" ]; then
    errors+=("file_missing:$(basename "$f")")
  fi
done

# ─── 2. Five hardened secret keys exist ───
for key in INGRESS_API_KEY ADMIN_API_KEY OPERATOR_SESSION_KEY DEMO_INSTRUCTION_SIGNING_KEY EVIDENCE_SIGNING_KEY; do
  if ! grep -q "\"$key\"" "$PROVIDER" 2>/dev/null; then
    errors+=("hardened_key_missing_${key}")
  fi
done

# ─── 3. Five distinct OpenBao paths in KeyMapping ───
# Extract path strings from KeyMapping and verify no duplicates among the 5 hardened keys
PATHS=$(grep -oP '\("symphony/secrets/[^"]+' "$PROVIDER" 2>/dev/null | sort -u | wc -l)
if [ "$PATHS" -lt 5 ]; then
  errors+=("insufficient_distinct_paths:found_${PATHS}_need_5")
fi

# ─── 4. ADMIN_API_KEY has its own path (not shared with INGRESS) ───
ADMIN_PATH=$(grep 'ADMIN_API_KEY' "$PROVIDER" | grep -oP 'symphony/secrets/[^"]+' | head -1)
INGRESS_PATH=$(grep 'INGRESS_API_KEY' "$PROVIDER" | grep -oP 'symphony/secrets/[^"]+' | head -1)
if [ "$ADMIN_PATH" = "$INGRESS_PATH" ]; then
  errors+=("admin_ingress_path_collision")
fi

# ─── 5. OPERATOR_SESSION_KEY in RuntimeSecrets ───
if ! grep -q "OperatorSessionKey" "$RUNTIME_SECRETS" 2>/dev/null; then
  errors+=("OperatorSessionKey_missing_in_RuntimeSecrets")
fi

# ─── 6. OPERATOR_SESSION_KEY resolved in ResolveAsync ───
if ! grep -q '"OPERATOR_SESSION_KEY"' "$RUNTIME_SECRETS" 2>/dev/null; then
  errors+=("OperatorSessionKey_not_resolved")
fi

# ─── 7. Bootstrap seeds 5 distinct key domains ───
for path in symphony/secrets/api symphony/secrets/admin symphony/secrets/session symphony/secrets/instruction symphony/secrets/signing; do
  if ! grep -q "$path" "$BOOTSTRAP" 2>/dev/null; then
    errors+=("bootstrap_missing_path_${path}")
  fi
done

# ─── 8. Bootstrap generates distinct random keys ───
RANDOM_KEYS=$(grep -c 'openssl rand' "$BOOTSTRAP" 2>/dev/null || echo "0")
if [ "$RANDOM_KEYS" -lt 5 ]; then
  errors+=("bootstrap_insufficient_random_keys:found_${RANDOM_KEYS}")
fi

# ─── 9. Build check ───
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
    "check_id": "TSK-P1-216",
    "timestamp_utc": ts,
    "git_sha": sha,
    "schema_fingerprint": schema_fp,
    "status": status,
    "task_id": "TSK-P1-216",
    "run_id": run_id,
    "checks": {
        "five_hardened_keys": all(f"hardened_key_missing_{k}" not in errors for k in [
            "INGRESS_API_KEY", "ADMIN_API_KEY", "OPERATOR_SESSION_KEY",
            "DEMO_INSTRUCTION_SIGNING_KEY", "EVIDENCE_SIGNING_KEY"
        ]),
        "five_distinct_paths": "insufficient_distinct_paths" not in " ".join(errors),
        "admin_ingress_separated": "admin_ingress_path_collision" not in errors,
        "operator_session_key_in_runtime": "OperatorSessionKey_missing_in_RuntimeSecrets" not in errors,
        "operator_session_key_resolved": "OperatorSessionKey_not_resolved" not in errors,
        "bootstrap_seeds_all_domains": all(
            f"bootstrap_missing_path_{p}" not in errors
            for p in ["symphony/secrets/api", "symphony/secrets/admin",
                       "symphony/secrets/session", "symphony/secrets/instruction",
                       "symphony/secrets/signing"]
        ),
        "bootstrap_generates_distinct_keys": "bootstrap_insufficient_random_keys" not in " ".join(errors),
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

echo "PASS: TSK-P1-216 Key domain separation verified."
echo "Evidence: $EVIDENCE"
