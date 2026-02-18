# ADR-0003: Zero Trust, secrets, and key management boundaries

## Status
Proposed

## Context
The platform must operate in hostile networks and assume no implicit trust.
Services require strong identity, strict authorization, and secure secrets usage.
Custodial mode increases the need for deterministic, auditable key handling.

## Decision
Adopt a Zero Trust model:
- All service-to-service traffic uses mTLS with workload identities.
- Least privilege roles in PostgreSQL; services use stored procedures only.
- Secrets are stored in an external KMS/HSM and retrieved via short-lived tokens.
- Policy bundles are signed and verified before activation.
- Audit logs capture all privileged actions and key access attempts.

## Consequences
- Adds operational complexity but reduces attack surface and compliance risk.
- Requires CI validation for privilege posture and policy checksum integrity.
- Ensures deterministic evidence trails for audits.
