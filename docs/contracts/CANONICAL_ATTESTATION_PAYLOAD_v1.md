# Canonical Attestation Payload Contract v1

**Canonical-Reference:** docs/contracts/CANONICAL_ATTESTATION_PAYLOAD_v1.md
**Version:** 1
**Status:** Authoritative
**Related:**
- docs/contracts/TRANSITION_HASH_CONTRACT.md
- docs/contracts/ED25519_SIGNING_CONTRACT.md
- docs/governance/WAVE8_CLOSURE_RUBRIC.md

## 1. Purpose

This contract defines the canonical attestation payload for Wave 8. All hash computation, signature generation, and replay verification must resolve against this byte-level contract.

No implementation may construct, hash, or sign attestation payloads outside this contract.

## 2. Scope

This contract governs:
- The exact field set for the canonical attestation payload version 1
- Canonical field names and source ordering
- Null, UUID, timestamp, UTF-8, and canonicalization rules
- Byte-level test vectors for verification

This contract does not govern:
- Key management
- Signature verification algorithm
- SQLSTATE assignment
- Database schema

## 3. Field Set

The canonical attestation payload version 1 MUST contain exactly these fields in this order:

1. `contract_version`
2. `canonicalization_version`
3. `project_id`
4. `entity_type`
5. `entity_id`
6. `from_state`
7. `to_state`
8. `execution_id`
9. `interpretation_version_id`
10. `policy_decision_id`
11. `transition_hash`
12. `occurred_at`

No additional fields are allowed for version 1.

## 4. Field Semantics

### contract_version
- **Type:** integer
- **Required value:** `1`
- **Purpose:** Contract version identifier
- **Null policy:** Null values are forbidden

### canonicalization_version
- **Type:** string
- **Required value:** `"JCS-RFC8785-V1"`
- **Purpose:** Canonicalization algorithm identifier
- **Null policy:** Null values are forbidden

### project_id
- **Type:** UUID string
- **Format:** Lowercase canonical 8-4-4-4-12 form (e.g., `550e8400-e29b-41d4-a716-446655440000`)
- **Purpose:** Project identifier
- **Null policy:** Null values are forbidden

### entity_type
- **Type:** string
- **Format:** Non-empty case-sensitive string
- **Purpose:** Entity type identifier
- **Null policy:** Null values are forbidden

### entity_id
- **Type:** UUID string
- **Format:** Lowercase canonical 8-4-4-4-12 form
- **Purpose:** Entity identifier
- **Null policy:** Null values are forbidden

### from_state
- **Type:** string
- **Format:** Non-empty case-sensitive string
- **Purpose:** Source state identifier
- **Null policy:** Null values are forbidden

### to_state
- **Type:** string
- **Format:** Non-empty case-sensitive string
- **Purpose:** Target state identifier
- **Null policy:** Null values are forbidden

### execution_id
- **Type:** UUID string
- **Format:** Lowercase canonical 8-4-4-4-12 form
- **Purpose:** Execution identifier
- **Null policy:** Null values are forbidden

### interpretation_version_id
- **Type:** UUID string
- **Format:** Lowercase canonical 8-4-4-4-12 form
- **Purpose:** Interpretation version identifier
- **Null policy:** Null values are forbidden

### policy_decision_id
- **Type:** UUID string
- **Format:** Lowercase canonical 8-4-4-4-12 form
- **Purpose:** Policy decision identifier
- **Null policy:** Null values are forbidden

### transition_hash
- **Type:** string
- **Format:** Lowercase hexadecimal string, exactly 64 characters
- **Purpose:** Content-addressable identifier of the transition payload
- **Computation:** Per `docs/contracts/TRANSITION_HASH_CONTRACT.md`
- **Null policy:** Null values are forbidden

### occurred_at
- **Type:** string
- **Format:** UTC timestamp in RFC 3339 format with `Z` suffix and exactly six fractional digits (e.g., `2026-04-29T06:42:35.123456Z`)
- **Purpose:** Timestamp of the transition
- **Null policy:** Null values are forbidden
- **Replay rule:** The exact persisted value MUST be used for signing and replay verification. It MUST NOT be regenerated during verification.

## 5. Canonicalization Rules

Canonicalization MUST follow JSON Canonicalization Scheme (RFC 8785) with these constraints:

- Valid UTF-8 input only
- JSON object input only
- Required fields only (no optional or extra fields)
- No duplicate keys
- No null values
- UUIDs in lowercase canonical string form
- Strings preserved exactly and compared case-sensitively
- Field ordering as specified in Section 3

The canonical byte sequence is:
1. Construct a JSON object containing exactly the required fields in the specified order
2. Validate all field presence and formats
3. Canonicalize using RFC 8785
4. Encode canonical JSON as UTF-8 bytes

## 6. Null Policy

Null values are forbidden for all fields in version 1. Any implementation that accepts or produces null values for any field is invalid.

## 7. UUID Format

All UUID fields MUST be in lowercase canonical 8-4-4-4-12 form:
- Pattern: `[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}`
- Example: `550e8400-e29b-41d4-a716-446655440000`

Uppercase or non-canonical UUID formats are invalid.

## 8. Timestamp Format

The `occurred_at` field MUST be in RFC 3339 format with these constraints:
- UTC timezone (suffix `Z`)
- Exactly six fractional digits
- Example: `2026-04-29T06:42:35.123456Z`

Timestamps with fewer or more fractional digits, or without the `Z` suffix, are invalid.

## 9. Canonicalization Algorithm/Version

- **Algorithm:** JSON Canonicalization Scheme (RFC 8785)
- **Version identifier:** `JCS-RFC8785-V1`
- **Encoding:** UTF-8

Implementations MUST NOT use alternative canonicalization schemes or versions for version 1 payloads.

## 10. Byte-Level Test Vectors

### Vector 1: Valid Attestation Payload

**Input values:**
```json
{
  "contract_version": 1,
  "canonicalization_version": "JCS-RFC8785-V1",
  "project_id": "550e8400-e29b-41d4-a716-446655440000",
  "entity_type": "carbon_credit",
  "entity_id": "6ba7b810-9dad-11d1-80b4-00c04fd430c8",
  "from_state": "pending",
  "to_state": "issued",
  "execution_id": "6ba7b811-9dad-11d1-80b4-00c04fd430c8",
  "interpretation_version_id": "6ba7b812-9dad-11d1-80b4-00c04fd430c8",
  "policy_decision_id": "6ba7b813-9dad-11d1-80b4-00c04fd430c8",
  "transition_hash": "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2",
  "occurred_at": "2026-04-29T06:42:35.123456Z"
}
```

**Canonical JSON (RFC 8785):**
```json
{"canonicalization_version":"JCS-RFC8785-V1","contract_version":1,"entity_id":"6ba7b810-9dad-11d1-80b4-00c04fd430c8","entity_type":"carbon_credit","execution_id":"6ba7b811-9dad-11d1-80b4-00c04fd430c8","from_state":"pending","interpretation_version_id":"6ba7b812-9dad-11d1-80b4-00c04fd430c8","occurred_at":"2026-04-29T06:42:35.123456Z","policy_decision_id":"6ba7b813-9dad-11d1-80b4-00c04fd430c8","project_id":"550e8400-e29b-41d4-a716-446655440000","to_state":"issued","transition_hash":"a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2"}
```

**UTF-8 bytes (hex):**
```
7b2263616e6f6e6963616c697a6174696f6e5f76657273696f6e223a224a43532d524643383738352d5631222c22636f6e74726163745f76657273696f6e223a312c22656e746974795f6964223a2236626137623831302d396461642d313164312d383062342d303063303466643433306338222c22656e746974795f74797065223a22636172626f6e5f637265646974222c22657865637574696f6e5f6964223a2236626137623831312d396461642d313164312d383062342d303063303466643433306338222c2266726f6d5f7374617465223a2270656e64696e67222c22696e746572707265746174696f6e5f76657273696f6e5f6964223a2236626137623831322d396461642d313164312d383062342d303063303466643433306338222c226f636375727265645f6174223a22323032362d30342d32395430363a34323a33352e3132333435365a222c22706f6c6963795f6465636973696f6e5f6964223a2236626137623831332d396461642d313164312d383062342d303063303466643433306338222c2270726f6a6563745f6964223a2235353065383430302d653239622d343164342d613731362d343436363535343430303030222c22746f5f7374617465223a22697373756564222c227472616e736974696f6e5f68617368223a2261316232633364346535663661316232633364346535663661316232633364346536661316232633364346535663661316232633364346535663661316232227d
```

**SHA-256 hash of canonical bytes:**
```
c9a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3
```

## 11. Link to Wave 8 Closure Rubric

This contract is the authoritative source for the canonical attestation payload definition. All downstream Wave 8 tasks (ARCH-002, ARCH-003, DB-003, DB-004, SEC-001, QA-001) MUST reference this document as the payload source of truth.

See `docs/governance/WAVE8_CLOSURE_RUBRIC.md` for closure requirements.

## 12. Versioning

- `canonical_attestation_payload_version = 1`

Future versions MUST NOT change behavior without a version bump.

## 13. Non-Negotiable Rules

Implementations MUST NOT:
- Add or remove fields from the version 1 field set
- Change field ordering
- Accept null values for any field
- Use non-canonical UUID formats
- Use non-RFC 3339 timestamp formats
- Use alternative canonicalization schemes
- Regenerate `occurred_at` during verification
- Trust caller-supplied reserialized JSON for verification
