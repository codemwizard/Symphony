# Symphony Key Rotation Policy
## Document ID: SYM-POL-SEC-002

### 1. OVERVIEW
This policy defines the lifecycle and rotation requirements for all cryptographic keys managed within the Symphony platform, specifically focusing on KMS/HSM integrated keys used for financial execution and identity verification.

### 2. CORE PRINCIPLES
- **Automatic Rotation:** Where supported by the KMS provider (e.g., AWS KMS), automatic yearly rotation must be enabled.
- **On-Demand Rotation:** Keys must be rotated immediately upon detection or suspicion of compromise.
- **Decommissioning:** Old key versions must be retained (in a disabled state) as long as data encrypted with them exists and is legally required.

### 3. ROTATION SCHEDULE
| Key Type | Rotation Period | Mechanism |
| :--- | :--- | :--- |
| **Root Master Key (KMS)** | 1 Year | Automated KMS Rotation |
| **Identity Keys (Data Keys)** | 90 Days | Application-level derivation update |
| **Audit Ledger Keys** | 180 Days | Application-level derivation update |
| **mTLS Certificates** | 365 Days | Deployment-level rotation |

### 4. AUDIT & VERIFICATION
- All derivation events are logged via `SymphonyKeyManager` (SYM-37).
- Key rotation events must be recorded in the immutable audit trail.
- Periodic manual review of KMS logs to verify rotation occurrences.

### 5. FAILURE HANDLING
- If a key rotation fails, the system must **fail-closed** (block new operations requiring key derivation).
- Manual intervention by the Security Lead is required to restore operation.

---
**Approved by:** Security Lead  
**Date:** January 6, 2026
