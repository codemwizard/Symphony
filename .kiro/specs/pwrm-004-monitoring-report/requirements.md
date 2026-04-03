# PWRM-004: PWRM0001 Monitoring Report Endpoint and Dashboard Download

## Background
Monitoring report aggregates over the submission log. Exception log is the
existing `DemoExceptionLog` from `EvidenceLinkHandlers.cs`. "Latest wins" =
highest `sequence_number` (not timestamp). Empty result returns valid report.

## US-1: Report aggregation

**Acceptance criteria:**
- `GET /pilot-demo/api/monitoring-report/{programId}` requires operator cookie.
- Empty submissions → valid report: `total_collections=0`, `proof_completeness_rate=1.0`, all numerics=0.
- `plastic_totals_kg` keys: `PET`, `HDPE`, `LDPE`, `PP`, `PS`, `OTHER`, `TOTAL`.
- `TOTAL` accumulated in same pass as per-type (single loop, no post-sum).
- `proof_completeness_rate = complete / total` as `decimal` division. Zero guard → 1.0.

## US-2: Duplicate instruction_id resolved by sequence_number (FIX F12 — preserved)

**Acceptance criteria:**
- Multiple WEIGHBRIDGE_RECORD for same `instruction_id` → `total_collections` = 1 (not 2).
- Weight data from record with HIGHEST `sequence_number`.
- No timestamp field used for tie-breaking.

## US-3: Exception log — explicitly seeded in self-test (FIX F10 — resolved)

**Acceptance criteria:**
- `exception_count` = distinct `instruction_id` values in `DemoExceptionLog.ReadAll()` filtered to `program_id`.
- Self-test runner explicitly calls `DemoExceptionLog.AppendAsync(...)` to seed at least one exception entry.
- Runner does NOT rely on other runners having seeded the exception log.

## US-4: ZGFT alignment fields (hardcoded true)

**Acceptance criteria:**
```json
"zgft_waste_sector_alignment": {
  "pollution_prevention": true,
  "circular_economy": true,
  "do_no_significant_harm_declared": true
}
```

## US-5: Report written unconditionally; artifact route returns it

**Acceptance criteria:**
- Handler writes `evidence/phase1/pwrm0001_monitoring_report.json` on EVERY call (including empty).
- `GET /pilot-demo/artifacts/pwrm0001_monitoring_report.json` returns the last generated report.
- `"pwrm0001_monitoring_report.json"` in the artifacts filename allowlist.

## US-6: Dashboard button

**Acceptance criteria:**
- "Generate PWRM0001 Monitoring Report" button in export controls.
- ON success: JSON download triggered + `total_collections` and `TOTAL` kg displayed.
- ON failure: `error_code` displayed.

## US-7: Self-test — 8 cases, fully isolated (FIX F16)

**Acceptance criteria:**
- `dotnet run --self-test-pwrm-monitoring-report` exits 0, all 8 cases PASS.
- Runner uses `tenantId = "44444444-4444-4444-4444-444444444444"` and `programId = "PGM-SELFTEST-PWRM004"`.
- Runner deletes its own NDJSON files (submissions AND exception log) at start.
- Runner seeds its own workers, submissions, and exception log entries.
- Runner does NOT depend on Program.cs seeding or other runners.