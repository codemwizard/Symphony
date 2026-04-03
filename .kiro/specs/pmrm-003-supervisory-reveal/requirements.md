# PWRM-003: PWRM0001 Proof Type Mapping and Supervisory Dashboard

## Background
PT-001..PT-004 are removed entirely. Programme detection uses a hard override
for the known pilot programme. structured_payload is guaranteed non-null on any
WEIGHBRIDGE_RECORD (established by PWRM-002).

## US-1: Proof types from ProofTypeDisplayLabels — PT-001..PT-004 deleted

**Acceptance criteria:**
- `proof_type_id` in every reveal row = `artifact_type` string from the submission log.
- Display label = `ProofTypeDisplayLabels[artifact_type]` or raw value as fallback.
- The strings `PT-001`, `PT-002`, `PT-003`, `PT-004` do NOT appear in ANY response body, source file, or test assertion after this task.
- `SupervisoryReadModelsSelfTestRunner.cs` assertion updated from PT-NNN to PWRM0001 artifact type strings.

## US-2: PWRM0001 detection with hard override for PGM-ZAMBIA-GRN-001 (FIX F5 — preserved)

**Acceptance criteria:**
- `program_id == "PGM-ZAMBIA-GRN-001"` → always PWRM0001 mode (hard override, no submission check required).
- All other programme IDs: BOTH conditions required (artifact_type in PWRM0001 set AND submitter_class = "WASTE_COLLECTOR").
- Programme with only WEIGHBRIDGE_RECORD and no WASTE_COLLECTOR → NOT PWRM0001 (generic labels).

## US-3: Weighbridge detail in instruction detail read model

**Acceptance criteria:**
- WHEN proof row `artifact_type = "WEIGHBRIDGE_RECORD"` AND `structured_payload` is non-null:
  - Row includes `plastic_type`, `net_weight_kg`, `collector_id` as top-level fields.
  - `net_weight_kg` is the backend-computed value (stored by PWRM-002) — `decimal`.
  - These fields accessed directly (PWRM-002 guarantee: no null check needed beyond structured_payload itself).
- WHEN `structured_payload` is null → these fields NOT added (legacy guard).

## US-4: Demo instructions seeded

**Acceptance criteria:**
- CHG-2026-00001: worker-chunga-001, all four proof types, SETTLED status, weighbridge payload: PET, net_weight_kg=12.4, collector_id=worker-chunga-001 GUID.
- CHG-2026-00002: worker-chunga-002, WEIGHBRIDGE_RECORD only, HOLD (TRANSFER_MANIFEST absent).
- Each seeded submission includes `sequence_number`.
- Workers use their OWN GUIDs (001 for CHG-00001, 002 for CHG-00002).

## US-5: Supervisory dashboard PWRM0001 UI

**Acceptance criteria:**
- PWRM0001 mode → programme header: `"Chunga Dumpsite — PWRM0001 Plastic Collection"`.
- Summary card: `"Collection Programme (PWRM0001)"`.
- Proof type column: human-readable labels via ProofTypeDisplayLabels mirror.
- WEIGHBRIDGE_RECORD rows: plastic type badge + net_weight_kg value when structured_payload is non-null.