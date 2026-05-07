# Key Management Policy (Phase-0 Stub, Tier-1 Ready)

## Purpose
This policy defines the minimum, auditable controls for cryptographic key management used by Symphony for:
- evidence signing and verification
- token signing and verification (where applicable)
- encryption key material used by infrastructure components (e.g., OpenBao transit keys)

This is a **Phase-0 policy stub**: it establishes governance intent and control boundaries. Phase-1/2 implement operational procedures and automation.

## Scope
In scope:
- keys used to sign **evidence artifacts** and **attestation bundles**
- keys used for service-to-service authentication (e.g., workload identity, mTLS token binding)
- keys used in OpenBao/Vault transit engines

Out of scope (Phase-0):
- HSM procurement, vendor onboarding, and FIPS certification evidence packages
- production rotation automation (documented in Phase-1)

## Key Management Principles
1. **Least privilege**: only the minimum runtime identity may request cryptographic operations.
2. **Separation of duties**: key creation/rotation approval is separate from application deployment.
3. **Auditability**: all key operations are logged and retained per the Audit Logging Policy.
4. **No hard-coded secrets**: private key material must not be committed to Git or stored in application config.
5. **Deterministic provenance**: evidence signatures must be reproducible by reference to a Git SHA + schema hash.

## Key Lifecycle Requirements
- **Create**: keys are generated inside the approved KMS boundary (OpenBao transit in Phase-0/1; HSM in Phase-2).
- **Store**: key material is non-exportable where supported; export requires explicit break-glass approval.
- **Use**: cryptographic operations use named keys; callers are workload identities (no shared users).
- **Rotate**: rotation cadence is documented (minimum annual; sooner on incident). Rotation events require evidence.
- **Revoke**: key compromise triggers immediate revocation and incident response.
- **Destroy**: destruction is controlled and produces a signed record; retention requirements apply.

## Evidence Expectations
For each environment:
- active key inventory (key names, purpose, creation date, current version)
- audit log proof that key operations are recorded
- change record for rotations and revocations, linked to an ADR or incident ID

## References
- `docs/security/THREE_PILLARS_SECURITY.md` (Governance plane responsibilities)
- `docs/control_planes/CONTROL_PLANES.yml` (Gate ownership and evidence mapping)

