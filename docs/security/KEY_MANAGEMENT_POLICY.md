# Key Management Policy (Phase-0 Stub)

Status: Phase-0 policy stub (auditor-legible; runtime integrations Phase-1+).

## Purpose
Define how Symphony manages cryptographic keys used for:
- evidence signing and verification
- service-to-service authentication material (future mTLS/workload identity)
- CI and operational secrets (through OpenBao)

## Scope
This policy covers:
- dev/stage/prod separation of keys and roles
- key generation, storage, access, rotation, and revocation
- incident response expectations for key compromise

## Principles
- Keys are never stored in source control.
- Environments are segregated. No key material is shared across environments.
- Least privilege and separation of duties apply to key access and rotation.
- Key access and key lifecycle operations must be auditable.

## System of Record (Phase-0)
- Phase-0 uses OpenBao as the system of record for secrets and key material needed for development and verification.
- Phase-1+ may move signing keys to external KMS/HSM. This must be achievable without redesigning evidence schema.

## Key Lifecycle

### Generation
- Keys are generated in OpenBao for Phase-0 dev/test.
- For Phase-1+ production posture, keys are generated in KMS/HSM where available and appropriate.

### Storage
- Private key material is stored only in OpenBao/KMS/HSM.
- Access is identity-based (workload identity / AppRole), scoped to the minimum required.

### Rotation
- Rotation cadence is defined per key class:
  - evidence signing keys: quarterly (default target)
  - operational/service credentials: at least quarterly, and on personnel changes
- Emergency rotation must be supported and documented with a runbook (Phase-1+).

### Revocation and Compromise Handling
- Compromise triggers immediate revocation and replacement.
- Evidence already produced must remain verifiable:
  - evidence should include key identifiers so verifiers can determine which key was used
  - verification material for historical evidence must be retained per retention policy

## Access Control and Separation of Duties
- Key access is restricted to the minimum set of roles required.
- Rotation and revocation actions require review and are logged.

## Auditability
- OpenBao audit logging must be enabled and reviewed per the audit logging retention policy.
- Evidence signing operations must emit durable, audit-grade artifacts (Phase-1+ runtime).

