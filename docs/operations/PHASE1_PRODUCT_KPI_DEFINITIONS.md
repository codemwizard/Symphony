# Phase-1 Product KPI Definitions

Phase-1 KPI readiness is computed from deterministic machine evidence.

## KPI Set
- `ack_determinism_pct`
  - Source: `evidence/phase1/ingress_api_contract_tests.json`
- `duplicate_suppression_effectiveness_pct`
  - Source: pilot harness + ingress contract evidence
- `evidence_casepack_generation_coverage_pct`
  - Source: evidence-pack contract + exception case-pack generation evidence
- `investigation_readiness_pct`
  - Source: pilot harness + pilot onboarding readiness evidence
- `retry_fail_closed_enforcement_pct`
  - Source: executor worker runtime fail-closed test cases

## Gate Semantics
- Script: `scripts/audit/verify_product_kpi_readiness.sh`
- Evidence output: `evidence/phase1/product_kpi_readiness_report.json`
- Freshness rule: all required source evidence must be present and within `KPI_MAX_AGE_MINUTES` (default `180`).
- Fail-closed rule: missing, stale, invalid, or below-threshold KPI inputs fail the gate.
