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

## Phase-1 Restricted Path Proof

The currently implemented restricted/offline proof path is the KYC hash bridge
guarded endpoint and self-test.

* Restricted-mode proof is file-backed and does not require a live DB connection.
* Restricted-mode proof does not require an external network call; the self-test
  runs entirely against local file-backed stores and in-process validation.
* Off-domain artifacts are limited to verification material such as provider
  hash, provider reference, and retention metadata; raw regulated payload fields
  must not be emitted into the proof artifact.
* Guarded-path rejection is implemented for forbidden regulated fields.
  The current enforced example is raw PII field rejection via
  `KycHashBridgeValidation.TryRejectPiiFields`, with evidence proving
  `full_name` is rejected on the implemented path.
* This restricted posture claim is limited to implemented guarded paths.
  It must not be generalized to unimplemented endpoints or global
  network-deny behavior.

## Evidence Archival Boundary

Cross-boundary evidence handling must preserve the declared retention class and archival state.

* Active evidence remains in the primary governed surface until verifier, approval, and audit obligations are closed.
* Archived evidence may move to lower-cost storage only after archival eligibility is met and manifest/hash references are recorded.
* Historical evidence must remain discoverable by manifest reference inside the governed programme boundary even when not retained in the active surface.
* DR bundle selection must follow the declared retention policy; bundle composition cannot silently omit evidence that is still active or audit-required.


## Language Scope
This policy applies to all backend implementation languages in Symphony, including:
- C# (.NET)
- Python
