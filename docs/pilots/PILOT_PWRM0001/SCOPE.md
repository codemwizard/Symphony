# Pilot Scope Declaration — PWRM0001

Status: Active
Date: 2026-03-31
Owner: Architecture / Platform
References:
  - docs/operations/AGENTIC_SDLC_PILOT_POLICY.md (Section 7)
  - docs/operations/AI_AGENT_OPERATION_MANUAL.md (apex authority)

---

## 1) Methodology Adapter

**Adapter Code:** PWRM0001
**Methodology:** PLASTIC_WASTE_V1
**Methodology Authority:** GLOBAL_PLASTIC_REGISTRY
**Version:** 1.0

This pilot exercises the Plastic Waste Recovery Methodology (PWRM) for
collection-based plastic credits in the Global South.

---

## 2) Neutral Host Tables Populated

This pilot populates the following neutral host tables via DML only:

- `adapter_registrations` — adapter configuration row
- `jurisdiction_profiles` — Global South jurisdiction profile
- `methodology_versions` — PWRM v1.0 methodology version record

**No new tables are created.** All data lives in existing Phase 0/1 tables.

---

## 3) Phase 2 Adapter Components

This pilot depends on the following adapter components (Phase 2):

- PWRM0001 payload schema definition (`pwrm0001_collection_schema_v1.json`)
- PWRM0001 verification checklist (`pwrm0001_verification_checklist_v1.json`)
- PWRM0001 calculation engine (`pwrm0001_calculation_engine_v1.py`)

These are registered as references in the `adapter_registrations` row and are
NOT stored in the database schema.

---

## 4) Confirmation: No New Neutral-Layer Tables Required

> **Confirmed:** This pilot requires ZERO new neutral-layer tables.
> All data is stored in existing Phase 0/1 tables using neutral host functions.

---

## 5) Confirmation: No Neutral-Layer Tables Will Be Altered

> **Confirmed:** This pilot does NOT alter any neutral-layer table structure.
> No ALTER TABLE, no new columns, no new constraints, no new indexes.
> Only DML INSERT operations against existing tables.

---

## 6) Jurisdiction Profile

**Jurisdiction Code:** GLOBAL_SOUTH
**Confidence Threshold:** 0.95 (95%)
**Verification Requirements:**
- field_verification
- digital_traceability
- mass_balance

---

## 7) Interpretation Pack Version

**Active Pack:** To be registered during pilot execution.
The interpretation pack will be anchored to the GLOBAL_SOUTH jurisdiction
per INV-165 requirements.

---

## 8) Second Pilot Test

> **Question:** Would this design work unchanged for a second pilot in a
> completely different sector?

**Answer:** YES.

**Sector 1:** PWRM0001 — Plastic waste collection credits (Global South)
**Sector 2:** VM0044 — Solar energy generation credits (Southeast Asia)

The neutral host architecture supports both sectors identically:
- Both register an adapter via `adapter_registrations` with DML INSERT
- Both use `methodology_versions` for version tracking
- Both use `jurisdiction_profiles` for regional regulatory rules
- Both use identical `issue_asset_batch()` and `retire_asset_batch()` functions
- Both go through the same confidence enforcement gate
- Neither requires any modification to Phase 0/1 schema, functions, or lifecycle states

The only differences between the two pilots are:
- Adapter payload schemas (different JSON structures in `record_payload_json`)
- Verification checklists (different methodology-specific checks)
- Calculation engines (different methodology-specific calculations)
- Jurisdiction profiles (different confidence thresholds and requirements)

All of these differences are expressed as adapter-level data, not as core schema.
