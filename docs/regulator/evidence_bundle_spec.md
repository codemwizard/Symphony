# Evidence Bundle Specification

**Version**: 7B.1.0
**Schema**: `evidence-bundle.schema.json`
**Phase**: SYM-7B (Evidence-Collection)

---

## 1. Purpose

This document specifies the structure and semantics of the Symphony Evidence Bundle. Supervisors can use this specification to independently verify execution correctness and detect anomalies.

---

## 2. Schema Overview

The Evidence Bundle is a JSON document conforming to `evidence-bundle.schema.json`.

| Field | Type | Description |
| :--- | :--- | :--- |
| `evidence_bundle_version` | `string` | Schema version (fixed: `"1.0"`) |
| `bundle_id` | `string (UUID)` | Unique identifier for this bundle |
| `generated_at` | `string (ISO 8601)` | Timestamp of bundle generation |
| `environment` | `enum` | `sandbox`, `staging`, or `production` |
| `phase` | `string` | Current system phase (e.g., `"7R"`, `"7B"`) |
| `issuer` | `string` | System that issued the bundle |

---

## 3. Core Sections

### 3.1 Immutability

| Field | Description |
| :--- | :--- |
| `hash_algorithm` | `SHA-256` or `SHA-512` |
| `bundle_hash` | Hex-encoded hash of bundle contents (excluding this field) |

**Invariant**: Supervisors can verify integrity by recomputing the hash.

### 3.2 Build Attestation

| Field | Description |
| :--- | :--- |
| `ci_provider` | CI system name (e.g., `"GitHub Actions"`) |
| `ci_run_id` | Unique CI run identifier |
| `ci_conclusion` | `success` or `failure` |
| `build_started_at` | Build start timestamp |
| `build_finished_at` | Build completion timestamp |

### 3.3 Source Provenance

| Field | Description |
| :--- | :--- |
| `repository` | Source code repository |
| `commit_hash` | Git commit SHA |
| `signed_commit` | Boolean indicating GPG signature |

---

## 4. Phase-7R Specific Sections

These sections are **REQUIRED** when `phase` is `"7R"`.

### 4.1 Evidence Export

| Field | Description |
| :--- | :--- |
| `enabled` | Whether export is active |
| `status` | `active`, `planned`, or `disabled` |
| `export_target` | Target storage type |

### 4.2 Attestation Gap

| Field | Description |
| :--- | :--- |
| `ingress_count` | Total ingress attestations in window |
| `terminal_events` | Total terminal executions |
| `gap` | `ingress_count - terminal_events` (MUST be 0) |
| `status` | `PASS` if gap == 0, else `FAIL` |

**Invariant**: Gap > 0 indicates missing executions.

### 4.3 DLQ Metrics

| Field | Description |
| :--- | :--- |
| `records_entered` | Total records that entered outbox |
| `records_recovered` | Successfully retried records |
| `records_terminal` | Records that reached FAILED status |

### 4.4 Revocation Bounds

| Field | Description |
| :--- | :--- |
| `cert_ttl_hours` | Maximum certificate TTL (target: ≤ 4) |
| `policy_propagation_seconds` | Time for policy changes to propagate |

### 4.5 Idempotency Metrics

| Field | Description |
| :--- | :--- |
| `duplicate_requests` | Total duplicate requests received |
| `duplicates_blocked` | Duplicates correctly blocked |
| `terminal_reentry_attempts` | Attempts to modify terminal state (MUST be 0) |

---

## 5. Invariants Supervisors Can Verify

1. **Hash Integrity**: Recompute `bundle_hash` and compare.
2. **Zero Attestation Gap**: `attestation_gap.gap == 0`.
3. **No Terminal Reentry**: `idempotency_metrics.terminal_reentry_attempts == 0`.
4. **Certificate TTL Bound**: `revocation_bounds.cert_ttl_hours <= 4`.
5. **CI Success**: `build_attestation.ci_conclusion == "success"`.

---

## 6. Known Limitations

1. **Single Failure Domain**: Evidence is stored within the application's failure domain. Out-of-domain persistence is planned for Phase-8.
2. **Export Lag**: Evidence export may lag behind real-time by the batch window size.
3. **Ledger Snapshots**: Balance comparisons require ledger snapshot access.

---

## 7. Changelog

| Version | Date | Changes |
| :--- | :--- | :--- |
| 7B.1.0 | 2026-01-14 | Initial specification for Phase-7B |
