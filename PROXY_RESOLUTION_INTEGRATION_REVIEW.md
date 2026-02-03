# Review: Proxy ID Resolution Integration
## Analysis of Invariant vs. PRD vs. Technical Roadmap

**Document Version:** 1.0  
**Review Date:** 2026-01-31  
**Reviewer:** Technical Architecture Review  
**Scope:** Proxy ID Resolution Feature Integration

---


## Executive Summary

**Overall Assessment:** ✅ **APPROVED with MINOR REFINEMENTS**

The Proxy ID resolution invariant is **well-aligned** with Symphony's evidence-grade exception containment mission and the Zambian market context. However, there are **three critical integration points** that need explicit treatment in Phase 0-1 to avoid retrofitting pain later.

**Key Findings:**
1. ✅ **Strategic Fit:** Proxy resolution directly supports PRD Story A ("ghost beneficiary avoidance") and Zambian regulatory expectations
2. ✅ **Architecture Alignment:** Append-only resolution records match Symphony's evidence-first posture
3. ⚠️ **Schema Gap:** Current roadmap doesn't include proxy resolution tables in Phase 1 DB migration
4. ⚠️ **Evidence Bundle Gap:** PRD Feature 4 doesn't explicitly cover proxy resolution evidence
5. ⚠️ **ISO 20022 Mapping:** Need explicit status codes for proxy resolution failures

---

## Part 1: Strategic Alignment Review

### 1.1 PRD Mission Alignment

**PRD Core Mission:**
> "Evidence-grade exception containment for NFS transactions... Fails closed at ingress unless a durable attestation record is written."

**Proxy ID Invariant Alignment:**
```
✅ STRONG ALIGNMENT

Proxy resolution prevents "ghost beneficiary" dispatch — a critical 
exception containment scenario where:
- Client provides alias (mobile number, TPIN)
- System dispatches to wrong/non-existent account
- Reversal window missed
- Audit trail incomplete

This is EXACTLY the failure mode Symphony is designed to prevent.
```

### 1.2 Zambian Market Context

**PRD Reference:**
> "ZECHL rules historically require electronic clearing artifacts to be encrypted and digitally signed, plus defined exception/reversal handling"

**Proxy Resolution Relevance:**

✅ **Direct Benefit:**
- **Beneficiary Traceability:** Proxy resolution creates immutable record tying alias → canonical identity → instruction
- **Reversal Support:** If a proxy was resolved incorrectly, the resolution record provides evidence for reversal initiation
- **Compliance:** BoZ sandbox participants will need to prove beneficiary identity provenance

⚠️ **Missing PRD Story:**

The PRD should add:

**Story F — "Proxy Resolution Evidence for Beneficiary Disputes"**
> As a bank operations analyst investigating a misdirected payment claim, I need a non-repudiable resolution record proving which beneficiary identity the proxy alias resolved to at the time of ingress, including the registry version and timestamp, so I can determine if the resolution was correct or if a reversal is warranted.

---

## Part 2: Technical Roadmap Integration

### 2.1 Current Roadmap Coverage

**What's Already There:**

✅ Phase 1 includes:
- Durable-recorded ingress with attestation
- Append-only evidence tables
- Idempotency enforcement

✅ Phase 2 includes:
- Batched claim pattern
- Append-only attempts
- Evidence bundle generation

**What's Missing:**

❌ No `proxy_resolutions` table in Phase 1 DB migration (TSK-P1-002)
❌ No proxy resolver component in Phase 1 scaffold (TSK-P1-001)
❌ No proxy resolution verification in Phase 2 executor (TSK-P2-002)

### 2.2 Recommended Roadmap Additions

#### Add to Phase 0 (Governance)

**New Task: TSK-P0-005 — Proxy Resolution Invariant Declaration**

```yaml
Task ID: TSK-P0-005
Owner Agent: Architecture + Security
Goal: Declare proxy resolution invariant and design schema hooks
Dependencies: TSK-P0-003 (Batching Invariants Manifest)
Files: 
  - docs/invariants/INVARIANTS_MANIFEST.yml
  - docs/architecture/adrs/ADR-0008-proxy-resolution-strategy.md
  - migrations/schema_hooks/proxy_resolution_tables.sql (not applied yet)

Implementation Notes:
- Add INV-PROXY-001 to manifest (status: roadmap)
- Design append-only proxy_resolutions table schema
- Design proxy_resolution_current hot cache table (optional)
- Document fail-closed vs. fail-open policy decision
- Define resolver interface contract (mock-ready)

Acceptance Criteria:
- [ ] INV-PROXY-001 in manifest with verification hooks
- [ ] Schema design reviewed and committed (not applied)
- [ ] ADR-0008 documents resolver boundary and evidence requirements
- [ ] Policy decision documented: resolve-before-enqueue vs. resolve-before-dispatch

Verification Commands:
- scripts/invariants/validate_manifest.sh
- Peer review of ADR-0008

Evidence Updates:
- Updated invariants manifest
- ADR committed
- Schema design reviewed
```

**Invariant Declaration (for manifest):**

```yaml
invariants:
  - id: INV-PROXY-001
    title: Proxy/Alias Resolution with Durable Evidence
    category: identity
    subcategory: beneficiary_resolution
    phase: P1-P2
    status: roadmap
    
    description: |
      For any instruction where beneficiary is expressed as an alias 
      (mobile number, TPIN, proxy identifier), the system must produce 
      a durable resolution record tying the alias to canonical beneficiary 
      identity before dispatch can occur.
      
      Resolution failures must be deterministic and map to ISO 20022 
      rejection codes.
    
    rationale: |
      Prevents "ghost beneficiary" dispatch where payment is sent to 
      wrong/non-existent account. Provides evidence trail for reversal 
      investigations and regulatory compliance.
    
    scope:
      - Applies to: instructions with beneficiary_type = 'PROXY' or 'ALIAS'
      - Does NOT apply to: instructions with direct account numbers
    
    verification:
      unit_tests:
        - tests/unit/ProxyResolver.Tests/ResolutionRecordingTest.cs
          # Proves resolution outcome is durably recorded
      
      integration_tests:
        - tests/integration/Ingest.ProxyResolution/FailClosedTest.cs
          # Proves dispatch blocked without resolution
        - tests/integration/ProxyResolver/BatchResolutionTest.cs
          # Proves batch resolution maintains evidence trail
      
      database_tests:
        - tests/db/verify_proxy_resolution_append_only.sql
          # Proves resolution records are immutable
      
      chaos_tests:
        - tests/chaos/proxy-registry-unavailable.sh
          # Proves fail-closed behavior when registry down
      
      metrics:
        - name: proxy_resolutions_total
          type: counter
          labels: [proxy_type, status]
        
        - name: proxy_resolution_latency_seconds
          type: histogram
          labels: [proxy_type, registry_source]
        
        - name: proxy_resolution_cache_hit_rate
          type: gauge
          labels: [proxy_type]
        
        - name: proxy_registry_unavailable_total
          type: counter
          labels: [registry_source]
          alert: rate > 1/min
    
    acceptance_criteria:
      - Schema exists for proxy_resolutions (append-only) and proxy_resolution_current (hot cache)
      - Resolver component exists (mock in dev, configurable for staging/prod)
      - Dispatch is blocked if resolution status != 'RESOLVED'
      - Resolution failures map to deterministic error taxonomy
      - Evidence bundles include resolution proof for alias-based instructions
      - Registry unavailability triggers fail-closed behavior (configurable per environment)
    
    related_controls:
      - ISO-20022: pain.001 beneficiary identification
      - PCI-DSS-6.5.10: Authorization controls (prevent unauthorized beneficiary substitution)
      - ISO-27001-A.9.4.5: Access control to beneficiary registry
    
    implementation_phases:
      phase_0:
        deliverable: "Schema design + ADR + invariant declaration"
        status: roadmap
      
      phase_1:
        deliverable: "Resolver stub + append-only records + ingress integration"
        status: roadmap
      
      phase_2:
        deliverable: "Dispatch gate + evidence bundles + batch resolution"
        status: roadmap
```

#### Add to Phase 1 (Foundation)

**Modified Task: TSK-P1-002 — Option 2A DB Migration + Proxy Resolution Tables**

Add to existing deliverables:

```sql
-- Add to migrations/YYYYMMDD_option_2a_outbox.sql

-- Proxy resolution append-only ledger
CREATE TABLE proxy_resolutions (
    resolution_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    instruction_id TEXT NOT NULL,
    proxy_type TEXT NOT NULL,  -- 'MOBILE', 'TPIN', 'EMAIL', etc.
    proxy_value_hash TEXT NOT NULL,  -- SHA-256 of proxy value (never store raw)
    
    -- Resolution outcome
    resolved_beneficiary_ref TEXT,  -- Canonical beneficiary ID from registry
    resolution_status TEXT NOT NULL,  -- 'RESOLVED', 'NOT_FOUND', 'TEMP_UNAVAILABLE', 'INVALID'
    
    -- Provenance
    resolver_source TEXT NOT NULL,  -- 'mock', 'sandbox_registry', 'prod_registry'
    resolver_version TEXT NOT NULL,  -- Registry API version
    registry_response_hash TEXT,  -- SHA-256 of raw registry response
    
    -- Evidence
    observed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ttl_seconds INT,  -- How long resolution is considered valid
    expires_at TIMESTAMPTZ,  -- Computed: observed_at + ttl_seconds
    
    CONSTRAINT chk_resolution_status CHECK (resolution_status IN (
        'RESOLVED', 'NOT_FOUND', 'TEMP_UNAVAILABLE', 'INVALID', 'REVOKED'
    ))
) PARTITION BY RANGE (observed_at);

-- Indexes
CREATE INDEX ix_proxy_resolutions_instruction 
    ON proxy_resolutions (instruction_id, observed_at DESC);

CREATE INDEX ix_proxy_resolutions_hash 
    ON proxy_resolutions (proxy_value_hash, observed_at DESC)
    WHERE resolution_status = 'RESOLVED';

-- Initial partition
CREATE TABLE proxy_resolutions_2026_02 PARTITION OF proxy_resolutions
    FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');

-- Privilege enforcement (append-only)
GRANT INSERT ON proxy_resolutions TO ingest_writer;
REVOKE UPDATE, DELETE ON proxy_resolutions FROM ingest_writer;

-- Optional: Hot cache for fast lookups
CREATE TABLE proxy_resolution_current (
    proxy_value_hash TEXT PRIMARY KEY,
    proxy_type TEXT NOT NULL,
    resolved_beneficiary_ref TEXT,
    resolution_status TEXT NOT NULL,
    observed_at TIMESTAMPTZ NOT NULL,
    expires_at TIMESTAMPTZ,
    
    -- Track source resolution_id for audit trail
    source_resolution_id UUID NOT NULL REFERENCES proxy_resolutions(resolution_id)
);

CREATE INDEX ix_proxy_current_expiry 
    ON proxy_resolution_current (expires_at)
    WHERE expires_at IS NOT NULL;

-- Function: Record resolution (append-only + update cache)
CREATE FUNCTION record_proxy_resolution(
    p_instruction_id TEXT,
    p_proxy_type TEXT,
    p_proxy_value_hash TEXT,
    p_resolved_beneficiary_ref TEXT,
    p_resolution_status TEXT,
    p_resolver_source TEXT,
    p_resolver_version TEXT,
    p_registry_response_hash TEXT,
    p_ttl_seconds INT
) RETURNS UUID AS $$
DECLARE
    v_resolution_id UUID;
    v_expires_at TIMESTAMPTZ;
BEGIN
    -- Compute expiry
    IF p_ttl_seconds IS NOT NULL THEN
        v_expires_at := NOW() + (p_ttl_seconds || ' seconds')::INTERVAL;
    END IF;
    
    -- Insert append-only record
    INSERT INTO proxy_resolutions (
        instruction_id, proxy_type, proxy_value_hash,
        resolved_beneficiary_ref, resolution_status,
        resolver_source, resolver_version, registry_response_hash,
        ttl_seconds, expires_at
    ) VALUES (
        p_instruction_id, p_proxy_type, p_proxy_value_hash,
        p_resolved_beneficiary_ref, p_resolution_status,
        p_resolver_source, p_resolver_version, p_registry_response_hash,
        p_ttl_seconds, v_expires_at
    )
    RETURNING resolution_id INTO v_resolution_id;
    
    -- Update hot cache (if successful resolution)
    IF p_resolution_status = 'RESOLVED' THEN
        INSERT INTO proxy_resolution_current (
            proxy_value_hash, proxy_type, resolved_beneficiary_ref,
            resolution_status, observed_at, expires_at, source_resolution_id
        ) VALUES (
            p_proxy_value_hash, p_proxy_type, p_resolved_beneficiary_ref,
            p_resolution_status, NOW(), v_expires_at, v_resolution_id
        )
        ON CONFLICT (proxy_value_hash) DO UPDATE
        SET resolved_beneficiary_ref = EXCLUDED.resolved_beneficiary_ref,
            resolution_status = EXCLUDED.resolution_status,
            observed_at = EXCLUDED.observed_at,
            expires_at = EXCLUDED.expires_at,
            source_resolution_id = EXCLUDED.source_resolution_id;
    END IF;
    
    RETURN v_resolution_id;
END;
$$ LANGUAGE plpgsql;
```

**New Task: TSK-P1-005 — Proxy Resolver Component (Stub)**

```yaml
Task ID: TSK-P1-005
Owner Agent: .NET Core + Security
Goal: Implement proxy resolver boundary with mock registry and evidence recording
Dependencies: TSK-P1-002 (DB migration includes proxy tables)
Files:
  - src/critical/Ingest.ProxyResolver/
  - src/critical/Ingest.ProxyResolver/IProxyRegistry.cs
  - src/critical/Ingest.ProxyResolver/MockProxyRegistry.cs
  - src/critical/Ingest.ProxyResolver/ProxyResolutionService.cs
  - tests/unit/ProxyResolver.Tests/
  - tests/integration/Ingest.ProxyResolution/

Implementation Notes:
- Define IProxyRegistry interface (resolve, batch_resolve methods)
- Implement MockProxyRegistry for dev/testing
- Implement ProxyResolutionService with durable evidence recording
- Support batch resolution for ingress batching
- Fail-closed by default; configurable fail-open for dev only

Acceptance Criteria:
- [ ] IProxyRegistry interface supports single + batch resolution
- [ ] MockProxyRegistry returns deterministic test data
- [ ] ProxyResolutionService calls record_proxy_resolution DB function
- [ ] Batch resolution maintains evidence trail for each item
- [ ] Registry unavailability returns TEMP_UNAVAILABLE status
- [ ] Evidence includes registry_version + response_hash

Verification Commands:
- dotnet test tests/unit/ProxyResolver.Tests/
- dotnet test tests/integration/Ingest.ProxyResolution/

Evidence Updates:
- Test reports proving evidence recording
- Mock registry configuration documented
```

**Resolver Interface Design:**

```csharp
// src/critical/Ingest.ProxyResolver/IProxyRegistry.cs
public interface IProxyRegistry
{
    /// <summary>
    /// Resolve single proxy identifier to canonical beneficiary reference
    /// </summary>
    Task<ProxyResolutionResult> ResolveAsync(
        string proxyType,
        string proxyValue,
        CancellationToken ct = default
    );
    
    /// <summary>
    /// Batch resolve multiple proxy identifiers (for ingress batching)
    /// </summary>
    Task<IReadOnlyList<ProxyResolutionResult>> ResolveBatchAsync(
        IReadOnlyList<ProxyResolutionRequest> requests,
        CancellationToken ct = default
    );
    
    /// <summary>
    /// Check if proxy resolution is cached and valid
    /// </summary>
    Task<ProxyResolutionResult?> GetCachedAsync(
        string proxyType,
        string proxyValue,
        CancellationToken ct = default
    );
}

public record ProxyResolutionRequest(
    string InstructionId,
    string ProxyType,
    string ProxyValue
);

public record ProxyResolutionResult(
    string ProxyType,
    string ProxyValueHash,  // Never return raw value
    ProxyResolutionStatus Status,
    string? ResolvedBeneficiaryRef,
    string ResolverSource,
    string ResolverVersion,
    string? RegistryResponseHash,
    int? TtlSeconds,
    DateTime ObservedAt,
    string? ErrorCode,
    string? ErrorMessage
);

public enum ProxyResolutionStatus
{
    RESOLVED,           // Successfully resolved to beneficiary
    NOT_FOUND,          // Proxy doesn't exist in registry
    TEMP_UNAVAILABLE,   // Registry temporarily down
    INVALID,            // Proxy format invalid
    REVOKED            // Proxy was revoked/deactivated
}
```

**Resolver Service Implementation:**

```csharp
// src/critical/Ingest.ProxyResolver/ProxyResolutionService.cs
public class ProxyResolutionService
{
    private readonly IProxyRegistry _registry;
    private readonly IDbConnection _db;
    private readonly ILogger<ProxyResolutionService> _logger;
    private readonly bool _failClosed;
    
    public ProxyResolutionService(
        IProxyRegistry registry,
        IDbConnection db,
        IConfiguration config,
        ILogger<ProxyResolutionService> logger)
    {
        _registry = registry;
        _db = db;
        _logger = logger;
        
        var env = config["Environment"];
        _failClosed = env == "Production" || env == "Staging";
    }
    
    public async Task<ProxyResolutionResult> ResolveAndRecordAsync(
        string instructionId,
        string proxyType,
        string proxyValue,
        CancellationToken ct = default)
    {
        // Hash proxy value (never store raw)
        var proxyValueHash = ComputeSHA256(proxyValue);
        
        // Check cache first
        var cached = await GetCachedResolution(proxyValueHash, ct);
        if (cached != null && !IsExpired(cached))
        {
            MetricsRegistry.ProxyResolutionCacheHits.Add(1, 
                new KeyValuePair<string, object>("proxy_type", proxyType));
            return cached;
        }
        
        // Resolve via registry
        ProxyResolutionResult result;
        try
        {
            result = await _registry.ResolveAsync(proxyType, proxyValue, ct);
            
            MetricsRegistry.ProxyResolutionsTotal.Add(1,
                new KeyValuePair<string, object>("proxy_type", proxyType),
                new KeyValuePair<string, object>("status", result.Status.ToString()));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Registry resolution failed for {ProxyType}", proxyType);
            
            if (_failClosed)
            {
                // Production/Staging: fail-closed
                result = new ProxyResolutionResult(
                    ProxyType: proxyType,
                    ProxyValueHash: proxyValueHash,
                    Status: ProxyResolutionStatus.TEMP_UNAVAILABLE,
                    ResolvedBeneficiaryRef: null,
                    ResolverSource: "unavailable",
                    ResolverVersion: "unknown",
                    RegistryResponseHash: null,
                    TtlSeconds: null,
                    ObservedAt: DateTime.UtcNow,
                    ErrorCode: "REGISTRY_UNAVAILABLE",
                    ErrorMessage: ex.Message
                );
            }
            else
            {
                // Dev: explicit fallback (logged warning)
                _logger.LogWarning("Dev mode: allowing failed resolution as fallback");
                throw;
            }
        }
        
        // Record resolution (append-only + cache update)
        await RecordResolution(instructionId, result, ct);
        
        return result;
    }
    
    private async Task RecordResolution(
        string instructionId,
        ProxyResolutionResult result,
        CancellationToken ct)
    {
        await _db.ExecuteAsync(
            "SELECT record_proxy_resolution(@InstructionId, @ProxyType, @ProxyValueHash, " +
            "@ResolvedBeneficiaryRef, @ResolutionStatus, @ResolverSource, @ResolverVersion, " +
            "@RegistryResponseHash, @TtlSeconds)",
            new
            {
                InstructionId = instructionId,
                ProxyType = result.ProxyType,
                ProxyValueHash = result.ProxyValueHash,
                ResolvedBeneficiaryRef = result.ResolvedBeneficiaryRef,
                ResolutionStatus = result.Status.ToString(),
                ResolverSource = result.ResolverSource,
                ResolverVersion = result.ResolverVersion,
                RegistryResponseHash = result.RegistryResponseHash,
                TtlSeconds = result.TtlSeconds
            }
        );
    }
}
```

#### Add to Phase 2 (Execution Core)

**Modified Task: TSK-P2-002 — Batched Claim Pattern + Proxy Resolution Gate**

Add to acceptance criteria:

```
Acceptance Criteria (additions):
- [ ] Claim function only returns items where:
      - No proxy resolution required, OR
      - Proxy resolution exists AND status = 'RESOLVED' AND not expired
- [ ] Items with TEMP_UNAVAILABLE proxy status remain in pending (retry)
- [ ] Items with NOT_FOUND/INVALID/REVOKED proxy status moved to DLQ
- [ ] Evidence bundle includes proxy resolution proof for alias-based instructions
```

**Modified Claim Function:**

```sql
CREATE FUNCTION claim_outbox_batch(
    p_worker_id TEXT,
    p_batch_size INT,
    p_rail_type TEXT DEFAULT NULL
) RETURNS TABLE (
    outbox_id UUID,
    instruction_id TEXT,
    participant_id TEXT,
    sequence_id BIGINT,
    payload JSONB,
    resolved_beneficiary_ref TEXT  -- Added for proxy support
) AS $$
BEGIN
    RETURN QUERY
    WITH claimable AS (
        SELECT p.*
        FROM payment_outbox_pending p
        
        -- Left join to check proxy resolution if needed
        LEFT JOIN LATERAL (
            SELECT resolved_beneficiary_ref, resolution_status, expires_at
            FROM proxy_resolution_current prc
            WHERE prc.proxy_value_hash = SHA256(p.payload->>'beneficiary_proxy')
              AND p.payload->>'beneficiary_type' = 'PROXY'
        ) pr ON true
        
        WHERE (p_rail_type IS NULL OR p.rail_type = p_rail_type)
          AND p.next_attempt_at <= NOW()
          
          -- Proxy resolution gate
          AND (
              -- No proxy required (direct account number)
              p.payload->>'beneficiary_type' != 'PROXY'
              
              -- OR proxy successfully resolved and not expired
              OR (pr.resolution_status = 'RESOLVED' 
                  AND (pr.expires_at IS NULL OR pr.expires_at > NOW()))
          )
        
        ORDER BY p.next_attempt_at, p.created_at
        LIMIT p_batch_size
        FOR UPDATE SKIP LOCKED
    )
    , claimed AS (
        DELETE FROM payment_outbox_pending
        WHERE outbox_id IN (SELECT outbox_id FROM claimable)
        RETURNING *
    )
    , inserted_attempts AS (
        INSERT INTO payment_outbox_attempts (
            outbox_id, instruction_id, participant_id, sequence_id,
            attempt_no, state, claimed_at
        )
        SELECT
            c.outbox_id, c.instruction_id, c.participant_id, c.sequence_id,
            c.attempt_count + 1, 'DISPATCHING', NOW()
        FROM claimed c
        RETURNING outbox_id
    )
    SELECT
        c.outbox_id,
        c.instruction_id,
        c.participant_id,
        c.sequence_id,
        c.payload,
        COALESCE(
            (SELECT resolved_beneficiary_ref 
             FROM proxy_resolution_current 
             WHERE proxy_value_hash = SHA256(c.payload->>'beneficiary_proxy')),
            c.payload->>'beneficiary_account'  -- Fallback to direct account
        ) AS resolved_beneficiary_ref
    FROM claimed c;
END;
$$ LANGUAGE plpgsql;
```

---

## Part 3: PRD Feature Integration

### 3.1 Evidence Bundle Enhancement (Feature 4)

**Current PRD Feature 4:**
> "Produces a non-repudiable evidence artifact for any important event"

**Enhancement Needed:**

Add explicit proxy resolution coverage:

```
Evidence Bundle Contents (Enhanced):

1. Ingress Evidence:
   - Attestation hash
   - Request hash
   - Cert fingerprint
   - Token JTI hash
   + Proxy resolution proof (if applicable):
     - Proxy value hash
     - Resolution ID
     - Resolved beneficiary ref
     - Registry version
     - Registry response hash
     - Observed timestamp

2. Dispatch Evidence:
   - Attempt state transitions
   - Rail response hash
   + Beneficiary identity chain:
     - IF proxy: resolution_id → resolved_beneficiary_ref
     - IF direct: account_number (hashed)

3. Evidence Signature:
   - Detached signature over canonical JSON
   - Includes code anchor (git SHA) + schema anchor (fingerprint)
   + Proxy registry version anchor (for resolution reproducibility)
```

**Evidence Schema Update:**

```json
{
  "evidence_type": "INSTRUCTION_ACCEPTED",
  "evidence_id": "uuid-here",
  "timestamp": "2026-01-31T12:00:00Z",
  
  "anchors": {
    "code_sha": "abc123...",
    "schema_fingerprint": "def456...",
    "proxy_registry_version": "v2.1.0"  // Added
  },
  
  "attestation": {
    "instruction_id": "inst-789",
    "participant_id": "participant-456",
    "cert_fingerprint": "sha256:...",
    "token_jti_hash": "sha256:...",
    "request_hash": "sha256:..."
  },
  
  "proxy_resolution": {  // Added section
    "required": true,
    "resolution_id": "uuid-resolution",
    "proxy_type": "MOBILE",
    "proxy_value_hash": "sha256:...",
    "resolved_beneficiary_ref": "account-12345",
    "resolution_status": "RESOLVED",
    "resolver_source": "prod_registry",
    "resolver_version": "v2.1.0",
    "registry_response_hash": "sha256:...",
    "observed_at": "2026-01-31T12:00:00Z",
    "ttl_seconds": 3600,
    "expires_at": "2026-01-31T13:00:00Z"
  },
  
  "signature": {
    "algorithm": "RS256",
    "key_id": "symphony-evidence-2026-01",
    "value": "base64-signature-here"
  }
}
```

### 3.2 Exception Taxonomy Enhancement (Feature 2)

**Current PRD Feature 2:**
> "Deterministic Exception Taxonomy + ISO 20022 Status Semantics"

**Enhancement Needed:**

Add proxy resolution failure codes:

```
Proxy Resolution Error Taxonomy:

1. PROXY_NOT_FOUND
   - ISO Code: NOAS (No Addressee Service)
   - Description: Proxy identifier not registered in beneficiary registry
   - Retry: No (terminal)
   - Next Action: Return to client, suggest beneficiary verification

2. PROXY_TEMP_UNAVAILABLE
   - ISO Code: DNOR (Downstream Not Operating Correctly)
   - Description: Beneficiary registry temporarily unavailable
   - Retry: Yes (with backoff)
   - Next Action: Retry with exponential backoff, fallback after ceiling

3. PROXY_INVALID_FORMAT
   - ISO Code: FF01 (Invalid Debtor/Creditor Account)
   - Description: Proxy identifier format validation failed
   - Retry: No (terminal)
   - Next Action: Return to client, invalid request

4. PROXY_REVOKED
   - ISO Code: AC04 (Closed Account Number)
   - Description: Proxy identifier was revoked/deactivated
   - Retry: No (terminal)
   - Next Action: Return to client, beneficiary no longer valid

5. PROXY_EXPIRED_RESOLUTION
   - ISO Code: DNOR (Downstream Not Operating Correctly)
   - Description: Cached resolution expired, re-resolution failed
   - Retry: Yes (re-resolve)
   - Next Action: Attempt re-resolution, fallback to TEMP_UNAVAILABLE
```

**Attempt State Machine Update:**

```csharp
public enum AttemptState
{
    DISPATCHING,
    DISPATCHED,
    RETRYABLE,
    FAILED,
    ZOMBIE_REQUEUE,
    AWAITING_PROXY_RESOLUTION  // Added: instruction waiting for resolution
}

public enum ProxyResolutionOutcome
{
    NOT_REQUIRED,           // Direct account number, no proxy
    RESOLVED,               // Successfully resolved
    TEMP_UNAVAILABLE,       // Registry down, retryable
    NOT_FOUND,              // Terminal: proxy doesn't exist
    INVALID_FORMAT,         // Terminal: proxy format invalid
    REVOKED,                // Terminal: proxy deactivated
    EXPIRED_RE_RESOLVING   // Cached expired, attempting re-resolution
}
```

### 3.3 Case Pack Enhancement (Feature 7)

**Current PRD Feature 7:**
> "Human-in-the-Loop Triage + Case Evidence Packs"

**Enhancement Needed:**

Add proxy resolution to case pack contents:

```
Case Pack Contents (Enhanced):

Standard Fields:
- Ingress attestation hash
- Attempt history
- Last rail response hash
- Reconciliation hints

+ Proxy Resolution Section (if applicable):
  - Was proxy resolution required? (yes/no)
  - Resolution attempts count
  - Latest resolution status
  - Resolution history (all attempts)
  - Registry version at each attempt
  - Recommended action:
    - If NOT_FOUND: "Beneficiary proxy not registered, client notification required"
    - If TEMP_UNAVAILABLE: "Registry connectivity issue, retry with manual override option"
    - If REVOKED: "Beneficiary proxy revoked, client must provide new identifier"
```

**Case Pack JSON Schema:**

```json
{
  "case_id": "case-uuid",
  "instruction_id": "inst-789",
  "created_at": "2026-01-31T15:00:00Z",
  "case_reason": "PROXY_RESOLUTION_TERMINAL_FAILURE",
  
  "proxy_resolution_context": {  // Added section
    "resolution_required": true,
    "resolution_attempts": 5,
    "latest_status": "NOT_FOUND",
    "resolution_history": [
      {
        "resolution_id": "uuid-1",
        "observed_at": "2026-01-31T12:00:00Z",
        "status": "TEMP_UNAVAILABLE",
        "resolver_version": "v2.1.0"
      },
      {
        "resolution_id": "uuid-2",
        "observed_at": "2026-01-31T12:05:00Z",
        "status": "TEMP_UNAVAILABLE",
        "resolver_version": "v2.1.0"
      },
      {
        "resolution_id": "uuid-3",
        "observed_at": "2026-01-31T12:10:00Z",
        "status": "NOT_FOUND",
        "resolver_version": "v2.1.0"
      }
    ],
    "recommended_action": "NOTIFY_CLIENT_INVALID_PROXY",
    "evidence_bundle_refs": [
      "evidence-uuid-1",
      "evidence-uuid-2",
      "evidence-uuid-3"
    ]
  }
}
```

---

## Part 4: Critical Integration Risks

### Risk 1: Batching vs. Proxy Resolution Latency

**Problem:**
```
PRD emphasizes batching as correctness invariant, but proxy resolution 
introduces external dependency with variable latency.

Scenario:
- Ingress receives batch of 50 instructions
- 30 require proxy resolution
- Registry latency: 50-200ms per lookup
- Serial resolution: 1.5-6 seconds (violates flush-by-time invariant)
```

**Mitigation:**

1. **Batch Resolution API:**
```csharp
// IProxyRegistry must support batch operations
Task<IReadOnlyList<ProxyResolutionResult>> ResolveBatchAsync(
    IReadOnlyList<ProxyResolutionRequest> requests,
    CancellationToken ct = default
);
```

2. **Parallel Resolution with Bounded Concurrency:**
```csharp
public async Task<List<ProxyResolutionResult>> ResolveBatchParallelAsync(
    List<ProxyResolutionRequest> requests)
{
    var semaphore = new SemaphoreSlim(10);  // Max 10 concurrent resolutions
    
    var tasks = requests.Select(async req =>
    {
        await semaphore.WaitAsync();
        try
        {
            return await ResolveAndRecordAsync(
                req.InstructionId, req.ProxyType, req.ProxyValue
            );
        }
        finally
        {
            semaphore.Release();
        }
    });
    
    return await Task.WhenAll(tasks);
}
```

3. **Cache-First Strategy:**
```
Check proxy_resolution_current first for all items.
Only resolve uncached/expired items via registry.
Expected cache hit rate: 60-80% in steady state.
```

4. **Flush Policy Adjustment:**
```yaml
Batching:
  Ingestion:
    MaxBatchSize: 50
    MaxFlushMs: 200  # Increased from 100ms to accommodate resolution
    ProxyResolution:
      MaxConcurrent: 10
      CacheFirst: true
      RegistryTimeout: 150  # Must fit within flush window
```

**Invariant Update:**

```yaml
# Modified INV-BATCH-001
acceptance_criteria:
  - Batch flushes when size OR time threshold met
  - Proxy resolution does NOT block flush indefinitely
  - Registry timeout < MaxFlushMs
  - Cache hit rate >= 60% (monitored)
  - Parallel resolution maintains evidence trail
```

### Risk 2: Registry Downtime During High Volume

**Problem:**
```
Registry unavailability during peak ingress could cause:
- Massive pending depth (instructions waiting for resolution)
- DLQ overflow (if fail-closed treats as terminal)
- Client retry storms (if rejected at ingress)
```

**Mitigation Strategy:**

**Option A: Defer Resolution (Recommended for Phase 1-2)**
```
Flow:
1. Ingress accepts instruction (writes attestation)
2. Returns ACK: "ACCEPTED_PENDING_RESOLUTION"
3. Instruction enqueued with state: AWAITING_PROXY_RESOLUTION
4. Background resolver worker processes queue asynchronously
5. Once resolved, instruction becomes dispatchable

Benefits:
- Registry downtime doesn't block ingress
- Client gets quick ACK
- Batching preserved

Drawbacks:
- New state to manage
- More complex status tracking
```

**Option B: Fail-Closed at Ingress (Simpler, Phase 2+)**
```
Flow:
1. Ingress attempts resolution before attestation write
2. If registry unavailable: return 503 Service Unavailable
3. Client retries with backoff

Benefits:
- Simpler state machine
- No "pending resolution" limbo

Drawbacks:
- Higher decline rate during registry outages
- Client retry burden
```

**Recommendation:**

```
Phase 1: Implement Option A (defer resolution)
- More resilient to registry issues
- Preserves ingress availability
- Evidence trail still complete

Phase 2: Add Option B as configurable policy
- Per-participant flag: require_sync_resolution
- High-priority flows can opt into sync
```

**Configuration:**

```yaml
ProxyResolution:
  FailurePolicy: DEFER  # or FAIL_CLOSED
  
  Defer:
    MaxPendingResolutionAge: 3600  # 1 hour max wait
    ResolutionWorkerConcurrency: 50
    RetryBackoff:
      BaseMs: 1000
      MaxMs: 60000
      Multiplier: 2.0
  
  FailClosed:
    ReturnCode: 503
    RetryAfterSeconds: 30
```

### Risk 3: Evidence Bundle Signature with Proxy Data

**Problem:**
```
Evidence signature must cover proxy resolution data, but:
- Resolution happens asynchronously (if deferred)
- Evidence needs code+schema anchor AT TIME OF RESOLUTION
- Registry version may change between ingress and resolution
```

**Solution: Dual Evidence Events**

```json
// Evidence Event 1: Ingress Accepted
{
  "evidence_type": "INSTRUCTION_ACCEPTED",
  "timestamp": "2026-01-31T12:00:00Z",
  "anchors": {
    "code_sha": "abc123",
    "schema_fingerprint": "def456"
  },
  "proxy_resolution": {
    "required": true,
    "status": "PENDING"  // Not yet resolved
  }
}

// Evidence Event 2: Proxy Resolved
{
  "evidence_type": "PROXY_RESOLVED",
  "timestamp": "2026-01-31T12:00:05Z",
  "anchors": {
    "code_sha": "abc123",  // Same code version
    "schema_fingerprint": "def456",
    "proxy_registry_version": "v2.1.0"  // Registry version at resolution time
  },
  "resolution": {
    "resolution_id": "uuid-resolution",
    "proxy_type": "MOBILE",
    "proxy_value_hash": "sha256:...",
    "resolved_beneficiary_ref": "account-12345",
    "resolution_status": "RESOLVED",
    "resolver_source": "prod_registry",
    "registry_response_hash": "sha256:..."
  }
}

// Evidence Event 3: Dispatch Attempted
{
  "evidence_type": "DISPATCH_ATTEMPTED",
  "timestamp": "2026-01-31T12:01:00Z",
  "beneficiary_chain": {
    "ingress_attestation_id": "uuid-att",
    "proxy_resolution_id": "uuid-resolution",
    "resolved_beneficiary_ref": "account-12345"
  }
}
```

**Chain of Custody:**

```
Ingress Attestation (t=0s)
    ↓ [instruction_id]
Proxy Resolution (t=5s)
    ↓ [resolution_id + beneficiary_ref]
Dispatch Attempt (t=60s)
    ↓ [attempt_id + rail_reference]
Terminal Outcome

Each event independently signed.
Chain provable via shared instruction_id.
```

---

## Part 5: Recommendations

### Immediate Actions (Phase 0)

1. ✅ **Add TSK-P0-005** to Phase 0 task list
   - Declare INV-PROXY-001 in manifest (status: roadmap)
   - Design schema (don't apply yet)
   - Write ADR-0008 with policy decisions
   - Choose: defer vs. fail-closed strategy

2. ✅ **Add PRD Story F** ("Proxy Resolution Evidence for Beneficiary Disputes")

3. ✅ **Update PRD Feature 4** (Evidence Bundles) to include proxy resolution evidence

4. ✅ **Update PRD Feature 2** (Exception Taxonomy) with proxy resolution failure codes

### Phase 1 Additions

1. ✅ **Modify TSK-P1-002** to include proxy resolution tables in migration

2. ✅ **Add TSK-P1-005** (Proxy Resolver Component) with:
   - IProxyRegistry interface
   - MockProxyRegistry implementation
   - ProxyResolutionService with evidence recording
   - Batch resolution support

3. ✅ **Update TSK-P1-004** (Durable-Recorded Ingest) to:
   - Check if proxy resolution required
   - Call resolver service
   - Record resolution evidence
   - Support both sync and async resolution policies

### Phase 2 Additions

1. ✅ **Modify TSK-P2-002** (Batched Claim) to:
   - Gate claim on proxy resolution status
   - Include resolved_beneficiary_ref in claimed items
   - Handle expired resolutions (re-resolve or fail)

2. ✅ **Update evidence bundles** to include proxy resolution chain

3. ✅ **Update case packs** to include proxy resolution context

### Documentation Updates

1. **Metrics Catalog** (Appendix B) — Add:
```yaml
- name: proxy_resolutions_total
  type: counter
  labels: [proxy_type, status, resolver_source]

- name: proxy_resolution_latency_seconds
  type: histogram
  labels: [proxy_type]
  buckets: [0.01, 0.05, 0.1, 0.2, 0.5, 1.0]

- name: proxy_resolution_cache_hit_rate
  type: gauge

- name: proxy_registry_unavailable_total
  type: counter
  alert: rate > 1/min
```

2. **Configuration Parameters** (Appendix A) — Add:
```yaml
ProxyResolution:
  Enabled: true
  FailurePolicy: DEFER  # or FAIL_CLOSED
  CacheEnabled: true
  CacheTtlSeconds: 3600
  RegistryTimeout: 150
  BatchResolutionEnabled: true
  MaxConcurrentResolutions: 10
```

3. **Risk Register** (Appendix C) — Add:
```
RISK-009: Proxy registry unavailability causes ingress backlog
  Probability: Medium
  Impact: High
  Mitigation: Defer resolution policy + cache-first + monitoring
  Owner: Integration Team
```

---

## Part 6: Final Assessment

### Strengths

✅ **Strategic Alignment:** Proxy resolution directly addresses "ghost beneficiary" risk — core to Symphony's exception containment mission

✅ **Evidence Compatibility:** Append-only resolution records fit Symphony's audit-first architecture perfectly

✅ **Batching Preservation:** Batch resolution APIs maintain batching invariant without sacrificing proxy support

✅ **Zambian Market Fit:** Beneficiary traceability supports BoZ regulatory expectations and ZECHL-style evidence discipline

### Gaps Identified & Resolved

✅ Schema design complete (proxy_resolutions + proxy_resolution_current)
✅ Resolver interface designed (IProxyRegistry with batch support)
✅ Evidence bundle integration specified (dual-event model)
✅ Exception taxonomy extended (5 new proxy failure codes)
✅ Case pack integration defined
✅ Batching risk mitigated (parallel resolution + cache-first)
✅ Registry downtime strategy specified (defer vs. fail-closed)

### Remaining Decisions

⚠️ **Decision 1: Sync vs. Async Resolution Policy**
- Recommendation: **Async (defer)** for Phase 1-2
- Rationale: Preserves ingress availability, more resilient
- Trade-off: Slightly more complex state machine

⚠️ **Decision 2: Cache TTL Duration**
- Recommendation: **3600 seconds (1 hour)** initial
- Rationale: Balance freshness vs. registry load
- Monitoring: Adjust based on beneficiary churn rate

⚠️ **Decision 3: Production Registry Integration Timeline**
- Recommendation: **Phase 2 for sandbox, Phase 3+ for production**
- Rationale: Mock sufficient for Phase 1-2 evidence testing
- Dependency: Real registry API availability from partners

---

## Conclusion

**APPROVED FOR INTEGRATION** with the following execution plan:

### Phase 0 (This Sprint)
- Add INV-PROXY-001 to manifest (roadmap status)
- Design schema (commit but don't apply)
- Write ADR-0008 documenting policy decisions
- Update PRD with proxy-specific enhancements

### Phase 1 (Next Sprint)
- Apply proxy resolution schema migration
- Implement resolver stub + mock registry
- Integrate with durable-recorded ingest
- Prove evidence recording with tests

### Phase 2 (Future Sprint)
- Gate executor dispatch on proxy resolution
- Implement batch resolution for performance
- Update evidence bundles with proxy chain
- Add proxy context to case packs

**This integration strengthens Symphony's value proposition while maintaining mechanical enforcement discipline.**

---

**Review Status:** ✅ APPROVED
**Next Action:** Add TSK-P0-005 to Phase 0 backlog
**Owner:** Architecture + Security teams
**Follow-up:** Weekly sync on registry integration timeline with partners
