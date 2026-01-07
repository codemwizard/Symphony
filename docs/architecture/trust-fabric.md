# Symphony Trust Fabric — Identity & Authorization Enforcement

**Phase**: Phase-6-Ad
**Key**: SYM-37
**Status**: 🔒 LOCKED

## 1. The JWT → mTLS Bridge (Identity Downgrade)
The bridge is the "Singularity Point" where external identities terminate and internal service identities begin.
- **Requirement**: No external identity (JWT) may ever traverse into the protected internal network.
- **Enforcement**: 
  - The Gateway/Control-Plane terminates the JWT.
  - It creates a **Verified Context** envelope.
  - Sub-requests are made using the service's own mTLS certificate.
- **Non-Propagation**: Internal services see the **originating service** (e.g., `ingest-api`), but never the raw JWT claims. This prevents "trust leakage" or "spoofing" via header manipulation.

## 2. Capability-Tier Gates
Symphony uses a tiered trust model to protect financial primitives.
- **Trust Tier: `external`**: Assigned to any request originating from an external JWT.
- **Trust Tier: `internal`**: Assigned to service-to-service requests within the mTLS fabric.
- **The Gate**: 
  - **Hard Deny**: Any request with an `external` trust tier is strictly prohibited from invoking financial mutation capabilities (e.g., `financial.ledger.post`, `financial.instruction.initiate`).
  - **Mutation Flow**: Financial mutations can ONLY be triggered by an internal service that has "taken ownership" of the instruction after initial validation.

## 3. Directional Flow Verification (INV-FLOW-01/02)
- **Runtime Guard**: Every incoming request to an internal service MUST be verified against the **Directional Interaction Graph**.
- **Fatal Exit**: If an internal service (e.g., `executor-worker`) receives a request from a service further downstream, or attempts to call a service further upstream (Backward Call), the request must be terminated IMMEDIATELY.

## 4. Execution Traceability
- **Correlation ID Linkage**: Every request handled by the bridge MUST maintain an immutable link between the **Trace ID**, the **Audit Log ID**, and the **Identity Context**.
- **Trace Cleaning**: Traces must never contain raw JWT claims or sensitive identity metadata.

---
**Enforcement**: Handled at the library level via `libs/bridge/jwtToMtlsBridge.ts` and `libs/auth/authorize.ts`.
