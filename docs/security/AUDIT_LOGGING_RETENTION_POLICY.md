# Audit Logging Retention and Review Policy (Phase-0 Stub)

Status: Phase-0 policy stub (auditor-legible; enforcement hooks Phase-0, runtime integrations Phase-1+).

## Purpose
Define minimum expectations for audit logging integrity, retention, review cadence, and time synchronization for Tier-1 posture.

## In-Scope Logs (Minimum)
- OpenBao audit logs (authentication, secret access, policy changes).
- CI gate and evidence artifacts (Phase-0 evidence JSON under `evidence/phase0/` in CI artifacts).
- Database migration application record (schema migrations ledger) and schema fingerprint evidence outputs.

## Integrity and Access
- Audit logs must be append-only or WORM-anchored where feasible.
- Access to audit logs is restricted to security/compliance operations.
- Changes to retention settings must be reviewed and recorded.

## Retention Targets
Phase-0 declares targets; Phase-1+ implements production retention in the operational logging stack.

- Default target for regulated environments: 7 years.
- Minimum Phase-0 target: 90 days in dev/test environments (unless a stricter program requirement exists).

## Review Cadence
- OpenBao audit log review cadence: weekly (minimum).
- CI and gate evidence review cadence: per-release and on any FAIL evidence.
- Incident-driven review: immediate upon detection of compromise or anomaly.

## Time Synchronization
- All environments must use time synchronization (NTP/chrony or equivalent).
- Time drift must be monitored and investigated when outside operational thresholds (Phase-1+ enforcement).

