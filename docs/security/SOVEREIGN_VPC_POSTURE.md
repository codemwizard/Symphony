# Sovereign VPC Posture (Phase-0)

This document declares Symphony's Phase-0 posture for deployments that require a **customer-controlled VPC boundary** and **data residency constraints**.
Phase-0 is documentation and mechanical presence only. Runtime enforcement and attestation transport are Phase-1+.

## Data Residency Boundary

* Control plane and data plane separation: the customer VPC hosts data-plane services that touch regulated payloads.
* Storage residency: regulated data stores must remain inside the customer VPC boundary (or an explicitly governed sovereign region).
* Cross-boundary egress is deny-by-default. Any exceptions require an ADR reference and an explicit allowlist.

## Off-Domain Attestation Constraints

* Off-domain attestation (e.g., external proof-of-processing, remote anchoring) must not transmit raw regulated payloads.
* Evidence bundles must be structured so that cross-boundary artifacts can be validated without requiring raw PII.
* Any off-domain artifact formats and endpoints must be documented and versioned (contract registry) before Phase-1 activation.

## Deployment Model

* Phase-0 supports "deploy in customer VPC" as a target posture by providing mechanical governance and schema readiness proofs.
* Phase-1+ adds runtime adapters and attestation channels; Phase-0 does not include production traffic or external rail integration.

