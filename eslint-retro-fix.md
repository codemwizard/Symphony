# ESLint Retro Fix List (Categorized by Rule)

Source: `eslint . --ignore-pattern "_Legacy_V1/**"`

## no-console (errors) — 13 files
- `scripts/audit/verify_persistence.ts`
- `scripts/ci/security-gates.ts`
- `scripts/ci/verify_audit_integrity.cjs`
- `scripts/ci/verify_authorization.cjs`
- `scripts/ci/verify_identity_context.cjs`
- `scripts/ci/verify_runtime_bootstrap.cjs`
- `scripts/ops/bcdr_drill.ts`
- `scripts/ops/capture_incident_evidence.ts`
- `scripts/ops/export_evidence.ts`
- `scripts/ops/generate_service_certs.ts`
- `scripts/ops/restore_from_backup.ts`
- `scripts/validation/invariant-scanner.ts`
- `test-parity.ts`

## no-undef (errors) — 4 files
- `scripts/ci/verify_audit_integrity.cjs`
- `scripts/ci/verify_authorization.cjs`
- `scripts/ci/verify_identity_context.cjs`
- `scripts/ci/verify_runtime_bootstrap.cjs`

## @typescript-eslint/no-require-imports (errors) — 3 files
- `scripts/ci/verify_audit_integrity.cjs`
- `scripts/ci/verify_identity_context.cjs`
- `scripts/ci/verify_runtime_bootstrap.cjs`

## @typescript-eslint/no-unused-vars (warnings) — 30 files
- `libs/attestation/IngressAttestationMiddleware.ts`
- `libs/audit/integrity.ts`
- `libs/auth/authorize.ts`
- `libs/bcdr/healthVerifier.ts`
- `libs/bootstrap/mtls.ts`
- `libs/context/requestContext.ts`
- `libs/context/verifyIdentity.ts`
- `libs/crypto/keyManager.ts`
- `libs/db/index.ts`
- `libs/db/policy.ts`
- `libs/errors/sanitizer.ts`
- `libs/execution/instructionStateClient.ts`
- `libs/incident/containment.ts`
- `libs/outbox/OutboxRelayer.ts`
- `libs/participant/resolver.ts`
- `libs/policy/PolicyConsistencyMiddleware.ts`
- `libs/repair/ZombieRepairWorker.ts`
- `libs/validation/zod-middleware.ts`
- `scripts/ci/verify_audit_integrity.cjs`
- `scripts/ops/restore_from_backup.ts`
- `scripts/verification/ReplayVerificationReport.ts`
- `services/control-plane/src/index.ts`
- `services/executor-worker/src/index.ts`
- `services/ingest-api/src/index.ts`
- `services/read-api/src/index.ts`
- `tests/failure-classification.test.ts`
- `tests/participant-identity.test.ts`
- `tests/repair-workflow.test.ts`
- `tests/retry-eligibility.test.ts`
- `tests/runtime-guards.test.ts`

## @typescript-eslint/no-explicit-any (warnings) — 14 files
- `libs/bootstrap/config-guard.ts`
- `libs/bridge/jwtToMtlsBridge.ts`
- `libs/crypto/keyManager.ts`
- `libs/db/index.ts`
- `libs/errors/sanitizer.ts`
- `libs/iso20022/mapping.ts`
- `libs/iso20022/validator.ts`
- `libs/ledger/invariants.ts`
- `libs/ledger/proof-of-funds.ts`
- `libs/middleware/idempotency.ts`
- `scripts/ops/capture_incident_evidence.ts`
- `scripts/validation/invariant-scanner.ts`
- `test-parity.ts`
- `tests/repair-workflow.test.ts`
