# Supervisor Guide — Phase-7B

**Version**: 1.0
**Phase**: SYM-7B (Evidence-Collection)
**Audience**: Regulators, External Supervisors, Auditors

---

## 1. Introduction

This guide explains what supervisors can observe about Symphony's financial core without requiring system access or trusting internal assertions. Phase-7B provides **read-only visibility** into system correctness.

---

## 2. What You Can See

### 2.1 Evidence Bundles

**Location**: Exported to regulator bucket (filesystem or object store)

**Contents**:
- Build attestation (CI status, timestamps)
- Source provenance (commit, repository)
- Policy provenance (version, scope)
- Test evidence (counts, coverage)
- Security enforcement (TypeScript strict, audit results)
- Phase-7R metrics (attestation gap, DLQ, revocation bounds)

**Verification**: Each bundle includes a SHA-256 hash for integrity verification.

### 2.2 Attestation Gap

**View**: `supervisor_attestation_gap`

**Metric**: Count of requests that were attested but not executed within threshold windows (1 hour, 24 hours).

**Interpretation**:
- `gap_not_started_1h = 0` → All recent requests are processing
- `gap_in_progress_1h > 0` → Requests are actively executing
- `gap_not_started_24h > 0` → Potential stuck requests (investigate)

**Invariant**: Total `gap` should trend toward zero under normal operation.

### 2.3 Outbox Status

**View**: `supervisor_outbox_status`

**Metrics**:
- `pending_count` — Requests awaiting dispatch
- `success_count` — Successfully completed
- `failed_count` — Terminal failures (DLQ)
- `stale_1h` — Requests older than 1 hour without completion

**Interpretation**:
- High `stale_1h` indicates dispatch delays
- Growing `failed_count` may indicate external rail issues
- `retry_5_plus` shows DLQ candidates

### 2.4 Revocation Window

**View**: `supervisor_revocation_status`

**Metrics**:
- `max_ttl_hours` — Longest certificate validity (target: ≤ 4 hours)
- `active_count` / `revoked_count` — Certificate posture
- `worst_case_revocation_seconds` — Kill-switch effectiveness

**Invariant**: `max_ttl_hours <= 4` confirms rapid revocation capability.

### 2.5 Ledger Replay

**Tool**: `ledger_replay.ts`

**Purpose**: Reconstruct account balances from recorded facts (attestations + outbox + ledger entries).

**Output**:
- Reconstructed balances per account
- Execution timeline
- SHA-256 hashes of all inputs

**Verification**: Compare `reconstructedBalance` vs `actualBalance` in the verification report.

---

## 3. What You Cannot See

1. **Private Keys**: No cryptographic key material is exposed.
2. **PII**: Customer personal data is not included in evidence.
3. **Internal Logs**: Application debug logs are not exported.
4. **Real-Time State**: Views are snapshots, not live streams.
5. **Business Logic**: Execution code is not visible; only outcomes.

---

## 4. What Conclusions Are Valid

### ✅ You CAN Conclude:

1. **Execution Completeness**: If `attestation_gap.gap == 0`, all attested requests reached a terminal state.
2. **Dispatch Reliability**: If `dlq_metrics.records_terminal` is low relative to `records_entered`, dispatch is reliable.
3. **Revocation Capability**: If `cert_ttl_hours <= 4`, the system can revoke a participant within 4 hours.
4. **Build Integrity**: If `bundle_hash` matches recomputed value, the bundle is untampered.
5. **Ledger Consistency**: If replay verification shows `overallStatus == PASS`, balances are derivable from facts.

### ❌ You CANNOT Conclude:

1. **Future Reliability**: Evidence shows past behavior, not guarantees.
2. **External System Health**: Symphony does not attest to external rails.
3. **Data Loss**: Single-domain evidence cannot prove data survival across failures (Phase-8).
4. **Intent**: Evidence shows what happened, not why decisions were made.

---

## 5. Verification Procedures

### 5.1 Verify Bundle Integrity

```bash
# Compute hash and compare
cat evidence-bundle.json | jq -S 'del(.immutability.bundle_hash)' | sha256sum
# Compare with .immutability.bundle_hash
```

### 5.2 Verify Zero Attestation Gap

```sql
SELECT * FROM supervisor_attestation_gap;
-- Confirm: gap_not_started_24h = 0
```

### 5.3 Verify Ledger Consistency

```bash
# Run replay verification
npx ts-node scripts/verification/ReplayVerificationReport.ts --output ./verification
# Check: overallStatus == 'PASS'
```

---

## 6. Contact for Clarification

For questions about evidence interpretation, contact the Symphony compliance team.

---

## 7. Document Control

| Version | Date | Author |
| :--- | :--- | :--- |
| 1.0 | 2026-01-14 | Symphony Team |
