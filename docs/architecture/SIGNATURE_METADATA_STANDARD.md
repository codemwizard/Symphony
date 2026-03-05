# Signature Metadata Standard

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

Required metadata fields:
- key_id
- key_version
- algorithm
- canonicalization_version
- signature_timestamp
- signing_service_id
- trust_chain_ref
- assurance_tier

Batch/Merkle artifacts also require:
- merkle_root
- leaf_index
- merkle_proof
