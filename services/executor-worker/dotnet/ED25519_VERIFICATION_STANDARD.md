# Ed25519 Verification Standard for Wave 8

**Canonical-Reference:** services/executor-worker/dotnet/ED25519_VERIFICATION_STANDARD.md
**Environment Provenance:** TSK-P2-W8-SEC-000
**Related:**
- docs/contracts/ED25519_SIGNING_CONTRACT.md
- docs/contracts/CANONICAL_ATTESTATION_PAYLOAD_v1.md

## 1. Purpose

This document defines the authoritative Ed25519 verification implementation standard for Wave 8, consuming the environment/provider honesty proven by TSK-P2-W8-SEC-000.

## 2. Environment Provenance

The verification primitive executes inside the environment proven honest by TSK-P2-W8-SEC-000:
- Frozen SDK digest: microsoft/dotnet/sdk:10.0.100-preview.2.24130.4
- Frozen runtime digest: microsoft/dotnet/aspnet:10.0.0-preview.2.24130.4
- .NET 10 family: 10.0.100-preview.2.24130.4
- Linux/OpenSSL path: /lib/x86_64-linux-gnu/libcrypto.so.3
- First-party Ed25519 surface: System.Security.Cryptography.Ed25519

## 3. Verification Contract

The verification primitive MUST:
- Verify signatures over contract-defined canonical bytes (RFC 8785)
- Reject non-canonical byte interpretations
- Reject differently canonicalized byte streams
- Use the first-party System.Security.Cryptography.Ed25519 surface
- Execute fail-closed behavior for all error conditions

## 4. Input Requirements

The verification primitive accepts:
- Canonical payload bytes (UTF-8 encoded RFC 8785 canonical JSON)
- Signature bytes (base64url without padding)
- Public key bytes
- Key identifier and version for scope validation

## 5. Verification Steps

1. Validate input formats (non-null, correct encoding)
2. Canonicalize payload using RFC 8785
3. Encode canonical JSON as UTF-8 bytes
4. Verify Ed25519 signature over canonical bytes using System.Security.Cryptography.Ed25519
5. Validate key scope (project_id, entity_type if applicable)
6. Return success only if all steps succeed

## 6. Failure Conditions

The primitive MUST fail closed for:
- Malformed signatures
- Wrong keys
- Non-canonical byte streams
- Missing or invalid input
- Key scope violations
- Runtime errors

## 7. Test Requirements

Primitive-level tests MUST prove:
- Malformed signature failure
- Wrong key failure
- Valid signature success over contract-defined bytes
- Fail-closed runtime behavior inside the proven environment
