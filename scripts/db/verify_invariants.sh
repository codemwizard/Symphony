#!/usr/bin/env bash
# ============================================================
# verify_invariants.sh — Single entrypoint verification (CI/local)
# ============================================================
# Requires: DATABASE_URL
#
# Env knobs:
#   REQUIRE_POLICY_SEED=1        -> FAIL if no seed source found
#   SKIP_POLICY_SEED=1           -> skip seeding
#   SEED_POLICY_FILE=/path/file  -> seed from JSON file (dev)
#   SEED_POLICY_VERSION=...      -> seed from env (CI)
# ============================================================
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# --- 1. Pre-flight existence checks (Requirement #2 & Hardening) ---

# Verify binary dependencies (New Requirement)
command -v psql >/dev/null 2>&1 || { echo "❌ Error: psql not found in PATH"; exit 2; }
[[ -x "$SCRIPT_DIR/lint_migrations.sh" ]] || { echo "❌ Error: missing lint_migrations.sh"; exit 2; }
[[ -x "$SCRIPT_DIR/lint_search_path.sh" ]] || { echo "❌ Error: missing lint_search_path.sh"; exit 2; }
[[ -x "$SCRIPT_DIR/migrate.sh" ]] || { echo "❌ Error: missing migrate.sh"; exit 2; }
[[ -f "$SCRIPT_DIR/ci_invariant_gate.sql" ]] || { echo "❌ Error: missing ci_invariant_gate.sql"; exit 2; }
[[ -x "$SCRIPT_DIR/verify_outbox_pending_indexes.sh" ]] || { echo "❌ Error: missing verify_outbox_pending_indexes.sh"; exit 2; }
[[ -x "$SCRIPT_DIR/verify_outbox_mvcc_posture.sh" ]] || { echo "❌ Error: missing verify_outbox_mvcc_posture.sh"; exit 2; }
[[ -x "$REPO_ROOT/schema/seeds/dev/seed_policy_from_file.sh" ]] || { echo "❌ Error: missing seed_policy_from_file.sh"; exit 2; }

# --- 2. Execution ---
echo "🔎 Linting migrations..."
"$SCRIPT_DIR/lint_migrations.sh"

echo "🔒 Linting SECURITY DEFINER search_path..."
"$SCRIPT_DIR/lint_search_path.sh"

echo "🧱 Applying migrations (idempotent)..."
echo "🔎 Using migrate.sh from: $SCRIPT_DIR/migrate.sh"
"$SCRIPT_DIR/migrate.sh"

echo "🧭 Verifying outbox pending indexes..."
"$SCRIPT_DIR/verify_outbox_pending_indexes.sh"

echo "🧭 Verifying outbox MVCC posture..."
"$SCRIPT_DIR/verify_outbox_mvcc_posture.sh"

# --- 3. Policy Seeding with REQUIRE_POLICY_SEED logic (Requirement #1) ---
if [[ "${SKIP_POLICY_SEED:-0}" != "1" ]]; then
  POLICY_FILE="${SEED_POLICY_FILE:-}"
  SEED_SUCCESS=0

  # Fail Fast: If a specific file was requested but is missing (Requirement #5)
  if [[ -n "${POLICY_FILE}" && ! -f "${POLICY_FILE}" ]]; then
    echo "❌ Error: SEED_POLICY_FILE was set but does not exist: $POLICY_FILE"
    exit 2
  fi

  # Fallback logic to find default files if no specific file was provided
  if [[ -z "${POLICY_FILE}" ]]; then
    if [[ -f "$REPO_ROOT/.policy/active-policy.json" ]]; then
      POLICY_FILE="$REPO_ROOT/.policy/active-policy.json"
    elif [[ -f "$REPO_ROOT/.symphony/policies/active-policy.json" ]]; then
      POLICY_FILE="$REPO_ROOT/.symphony/policies/active-policy.json"
    fi
  fi

  if [[ -n "${POLICY_FILE}" ]]; then
    echo "🌱 Seeding policy from file: $POLICY_FILE"
    "$REPO_ROOT/schema/seeds/dev/seed_policy_from_file.sh" "$POLICY_FILE"
    SEED_SUCCESS=1
  elif [[ -n "${SEED_POLICY_VERSION:-}" ]]; then
    # Explicit check for CI seed script existence (Requirement #1 part 2)
    if [[ -x "$REPO_ROOT/schema/seeds/ci/seed_policy_from_env.sh" ]]; then
      echo "🌱 Seeding policy from env: SEED_POLICY_VERSION"
      "$REPO_ROOT/schema/seeds/ci/seed_policy_from_env.sh"
      SEED_SUCCESS=1
    else
      echo "⚠️  SEED_POLICY_VERSION set but schema/seeds/ci/seed_policy_from_env.sh not found."
    fi
  fi

  # Final check for Requirement #1: Failure logic
  if [[ "$SEED_SUCCESS" -eq 0 ]]; then
    if [[ "${REQUIRE_POLICY_SEED:-0}" == "1" ]]; then
      echo "::error::Policy seed required but no source found (REQUIRE_POLICY_SEED=1)."
      exit 1
    else
      echo "ℹ️  No policy seed source found; skipping seeding (Optional mode)."
    fi
  fi
else
  echo "⏭️  SKIP_POLICY_SEED=1 set; skipping policy seed."
fi

# --- 4. CI Invariant Gate (Requirement #3) ---
echo "🧰 Running CI invariant gate..."
psql "$DATABASE_URL" -q -v ON_ERROR_STOP=1 -X -f "$SCRIPT_DIR/ci_invariant_gate.sql" >/dev/null

echo "🧭 Running baseline drift check..."
if [[ -x "$SCRIPT_DIR/check_baseline_drift.sh" ]]; then
  "$SCRIPT_DIR/check_baseline_drift.sh"
else
  echo "❌ Error: missing check_baseline_drift.sh" >&2
  exit 2
fi

EVIDENCE_DIR="$REPO_ROOT/evidence/phase0"
mkdir -p "$EVIDENCE_DIR"

fail=0

echo "🔎 Verifying outbox pending claim index..."
indexdef="$(
  psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X \
    -c "SELECT indexdef FROM pg_indexes WHERE schemaname='public' AND indexname='idx_payment_outbox_pending_due_claim';" \
    | tr -d '\n'
)"
idx_status="pass"
if [[ -z "$indexdef" ]]; then
  idx_status="fail"
  fail=1
elif [[ "$indexdef" != *"(next_attempt_at"* || "$indexdef" != *"created_at"* ]]; then
  idx_status="fail"
  fail=1
fi
python3 - <<PY
import json
from pathlib import Path
out = {"status": "$idx_status", "indexdef": "$indexdef"}
Path("$EVIDENCE_DIR/outbox_pending_indexes.json").write_text(json.dumps(out, indent=2))
PY

echo "🔎 Verifying outbox pending MVCC posture..."
relopts="$(
  psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X \
    -c "SELECT array_to_string(reloptions, ',') FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname='public' AND c.relname='payment_outbox_pending';" \
    | tr -d '\n'
)"
mvcc_status="pass"
if [[ "$relopts" != *"fillfactor=80"* ]]; then
  mvcc_status="fail"
  fail=1
fi
python3 - <<PY
import json
from pathlib import Path
out = {"status": "$mvcc_status", "reloptions": "$relopts"}
Path("$EVIDENCE_DIR/outbox_mvcc_posture.json").write_text(json.dumps(out, indent=2))
PY

echo "🔎 Verifying ingress_attestations append-only + indexes..."
ingress_exists="$(
  psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X \
    -c "SELECT to_regclass('public.ingress_attestations') IS NOT NULL;"
)"
ingress_idx_instruction="$(
  psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X \
    -c "SELECT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='public' AND tablename='ingress_attestations' AND indexdef LIKE '%(instruction_id)%');"
)"
ingress_idx_received="$(
  psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X \
    -c "SELECT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='public' AND tablename='ingress_attestations' AND indexdef LIKE '%(received_at)%');"
)"
ingress_trigger="$(
  psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X \
    -c "SELECT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname='trg_deny_ingress_attestations_mutation');"
)"
ingress_status="pass"
if [[ "$ingress_exists" != "t" || "$ingress_idx_instruction" != "t" || "$ingress_idx_received" != "t" || "$ingress_trigger" != "t" ]]; then
  ingress_status="fail"
  fail=1
fi
python3 - <<PY
import json
from pathlib import Path
out = {
  "status": "$ingress_status",
  "table_exists": "$ingress_exists",
  "index_instruction_id": "$ingress_idx_instruction",
  "index_received_at": "$ingress_idx_received",
  "append_only_trigger": "$ingress_trigger",
}
Path("$EVIDENCE_DIR/ingress_attestation.json").write_text(json.dumps(out, indent=2))
PY

echo "🔎 Verifying tenant/client/member hooks..."
if [[ -x "scripts/db/verify_tenant_member_hooks.sh" || -f "scripts/db/verify_tenant_member_hooks.sh" ]]; then
  bash scripts/db/verify_tenant_member_hooks.sh
else
  echo "ERROR: scripts/db/verify_tenant_member_hooks.sh not found"
  fail=1
fi

echo "🔎 Verifying revocation tables append-only..."
rev_certs="$(
  psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X \
    -c "SELECT to_regclass('public.revoked_client_certs') IS NOT NULL;"
)"
rev_tokens="$(
  psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X \
    -c "SELECT to_regclass('public.revoked_tokens') IS NOT NULL;"
)"
rev_trigger_certs="$(
  psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X \
    -c "SELECT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname='trg_deny_revoked_client_certs_mutation');"
)"
rev_trigger_tokens="$(
  psql "$DATABASE_URL" -q -t -A -v ON_ERROR_STOP=1 -X \
    -c "SELECT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname='trg_deny_revoked_tokens_mutation');"
)"
rev_status="pass"
if [[ "$rev_certs" != "t" || "$rev_tokens" != "t" || "$rev_trigger_certs" != "t" || "$rev_trigger_tokens" != "t" ]]; then
  rev_status="fail"
  fail=1
fi
python3 - <<PY
import json
from pathlib import Path
out = {
  "status": "$rev_status",
  "revoked_client_certs": "$rev_certs",
  "revoked_tokens": "$rev_tokens",
  "trigger_certs": "$rev_trigger_certs",
  "trigger_tokens": "$rev_trigger_tokens",
}
Path("$EVIDENCE_DIR/revocation_tables.json").write_text(json.dumps(out, indent=2))
PY

if [[ $fail -ne 0 ]]; then
  echo "❌ Invariant verification failed. See evidence in $EVIDENCE_DIR" >&2
  exit 1
fi

echo "✅ Invariants verified."
