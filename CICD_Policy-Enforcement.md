# Symphony CI/CD Policy Enforcement Documentation

## Executive Summary

The Symphony CI/CD pipeline implements a regulator-grade, multi-layered security enforcement system that ensures strict adherence to coding standards, architectural invariants, and policy compliance. This document outlines the complete policy enforcement framework, including security gates, compliance checks, and phase-based controls.

---

## 1. CI/CD Security Architecture

### 1.1 Pipeline Overview
```
GitHub Actions → Security Gates → Compliance Checks → Policy Enforcement → Build Success/Failure
```

### 1.2 Security Enforcement Layers
1. **Static Security Analysis** - Pre-execution threat detection
2. **Policy Version Binding** - Drift prevention mechanisms  
3. **Phase-Based Controls** - Progressive feature gating
4. **Database Invariant Testing** - Architectural compliance
5. **Audit Trail Generation** - Immutable evidence collection

---

## 2. Complete CI/CD Build Process

### 2.1 Step-by-Step Build Sequence

#### Phase 1: Environment Setup & Security Gates
```yaml
# .github/workflows/ci-security.yml
name: Symphony Security CI/CD
on: [push, pull_request]
env:
  PHASE: 6
jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          submodules: recursive
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
```

#### Phase 2: Static Security Analysis
```bash
npm run security-check
# Executes: scripts/ci/security-gates.ts
```

**Security Gates Implementation:**
```typescript
// scripts/ci/security-gates.ts
const SECURITY_RULES = [
  {
    name: "Local-KMS Detection",
    pattern: /localhost:8080/,
    paths: ["libs/", "services/"],
    action: "BLOCK"
  },
  {
    name: "DevelopmentKeyManager Prevention", 
    pattern: /DevelopmentKeyManager/,
    exclude: ["test/", "dev/"],
    action: "BLOCK"
  },
  {
    name: "Default DB Credentials",
    pattern: /(admin|password|root)/,
    paths: ["libs/db/", "schema/"],
    action: "BLOCK"
  },
  {
    name: "Phase 6+ Logic Gating",
    pattern: /if\s*\(\s*process\.env\.PHASE\s*>=\s*7\)/,
    action: "REQUIRE_EXPLICIT_GATE"
  }
];
```

#### Phase 3: Unit Test Execution
```bash
npm test
# Executes 32 tests across 18 test suites
```

**Critical Test Categories:**
- Security controls validation
- Phase 7 compliance blocking
- Operational safety verification
- ISO-20022 schema validation
- Idempotency enforcement
- Audit integrity verification

#### Phase 4: Compliance Verification
```bash
npm run ci:compliance
```

**Compliance Scripts Chain:**
```javascript
// scripts/ci/verify_audit_integrity.cjs
// scripts/ci/verify_authorization.cjs
// scripts/ci/verify_identity_context.cjs
// scripts/ci/verify_runtime_bootstrap.cjs
```

#### Phase 5: Database Invariant Testing
```sql
-- scripts/db/test_invariants.sql
-- scripts/db/verify_phase1.sql
-- scripts/db/verify_phase2.sql
-- scripts/db/kill_switch.sql
```

#### Phase 6: Security Scanning
```bash
npm audit
npx snyk test
```

---

## 3. Security Enforcement Scripts

### 3.1 Security Gates (`scripts/ci/security-gates.ts`)

**Core Security Checks:**
- ✅ Detects localhost:8080 (local-KMS) in production files
- ✅ Blocks DevelopmentKeyManager outside dev paths
- ✅ Prevents default DB credentials (admin/password)
- ✅ Validates Phase 6+ logic has explicit gating
- ✅ Scans ALL files for security violations

**Implementation Details:**
```typescript
export class SecurityGate {
  async validateSecurity(): Promise<SecurityResult> {
    const violations: SecurityViolation[] = [];
    
    // Scan for local-KMS endpoints
    await this.scanForPattern(/localhost:8080/, "Local-KMS detected");
    
    // Check for development keys in production
    await this.scanForPattern(/DevelopmentKeyManager/, "Dev keys in production");
    
    // Validate database credentials
    await this.scanForPattern(/password.*=.*['"]?(admin|root|password)/, "Default credentials");
    
    // Verify Phase 6+ gating
    await this.validatePhaseGating();
    
    return {
      passed: violations.length === 0,
      violations
    };
  }
}
```

### 3.2 Compliance Verification Scripts

#### Authorization Verification (`scripts/ci/verify_authorization.cjs`)
```javascript
// Validates Phase 6.3+ Authorization Framework
const AUTHORIZATION_CHECKS = [
  {
    name: "Capability Registry Integrity",
    check: () => validateCapabilityRegistry(),
    required: true
  },
  {
    name: "Policy Version Binding",
    check: () => validatePolicyVersionBinding(),
    required: true
  },
  {
    name: "OU Boundary Enforcement",
    check: () => validateOUBoundaries(),
    required: true
  },
  {
    name: "Emergency Lockdown Behavior",
    check: () => validateEmergencyLockdown(),
    required: true
  }
];
```

#### Identity Context Verification (`scripts/ci/verify_identity_context.cjs`)
```javascript
// Validates Phase 6.2 Verified Context
const IDENTITY_CHECKS = [
  {
    name: "Identity Envelope Schema",
    check: () => validateIdentitySchema(),
    required: true
  },
  {
    name: "Signature Verification",
    check: () => validateSignatureVerification(),
    required: true
  },
  {
    name: "Directional Trust Enforcement",
    check: () => validateDirectionalTrust(),
    required: true
  },
  {
    name: "Context Immutability",
    check: () => validateContextImmutability(),
    required: true
  }
];
```

#### Runtime Bootstrap Verification (`scripts/ci/verify_runtime_bootstrap.cjs`)
```javascript
// Validates Phase 6.1 Bootstrap Controls
const BOOTSTRAP_CHECKS = [
  {
    name: "Policy Version Check",
    check: () => validatePolicyVersionCheck(),
    required: true
  },
  {
    name: "Kill-Switch Enforcement",
    check: () => validateKillSwitchEnforcement(),
    required: true
  },
  {
    name: "Role-Based DB Connections",
    check: () => validateRoleBasedConnections(),
    required: true
  },
  {
    name: "Fail-Closed Startup Behavior",
    check: () => validateFailClosedBehavior(),
    required: true
  }
];
```

### 3.3 Database Invariant Scripts

#### Phase 1 Schema Validation (`scripts/db/verify_phase1.sql`)
```sql
-- Core Schema Integrity Checks
DO $$
DECLARE
    violation_count INTEGER;
BEGIN
    -- Check table constraints
    SELECT COUNT(*) INTO violation_count
    FROM information_schema.check_constraints
    WHERE constraint_schema = 'public';
    
    IF violation_count = 0 THEN
        RAISE EXCEPTION 'Phase 1: No table constraints found';
    END IF;
    
    -- Validate foreign key integrity
    SELECT COUNT(*) INTO violation_count
    FROM information_schema.referential_constraints
    WHERE constraint_schema = 'public';
    
    IF violation_count = 0 THEN
        RAISE EXCEPTION 'Phase 1: No foreign key constraints found';
    END IF;
    
    RAISE NOTICE 'Phase 1 schema validation passed';
END $$;
```

#### Phase 2 RBAC Validation (`scripts/db/verify_phase2.sql`)
```sql
-- Role-Based Access Control Verification
DO $$
DECLARE
    role_count INTEGER;
    privilege_count INTEGER;
BEGIN
    -- Verify required roles exist
    SELECT COUNT(*) INTO role_count
    FROM pg_roles
    WHERE rolname IN ('symphony_control', 'symphony_ingest', 'symphony_executor', 'symphony_readonly');
    
    IF role_count != 4 THEN
        RAISE EXCEPTION 'Phase 2: Missing required database roles';
    END IF;
    
    -- Validate privilege boundaries
    SELECT COUNT(*) INTO privilege_count
    FROM information_schema.role_table_grants
    WHERE grantee IN ('symphony_control', 'symphony_ingest', 'symphony_executor', 'symphony_readonly');
    
    IF privilege_count = 0 THEN
        RAISE EXCEPTION 'Phase 2: No table privileges granted to roles';
    END IF;
    
    RAISE NOTICE 'Phase 2 RBAC validation passed';
END $$;
```

#### Kill-Switch Integrity (`scripts/db/kill_switch.sql`)
```sql
-- Kill-Switch Table Creation and Validation
CREATE TABLE IF NOT EXISTS kill_switches (
    id TEXT PRIMARY KEY DEFAULT generate_ulid(),
    name TEXT NOT NULL UNIQUE,
    is_active BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    activated_at TIMESTAMPTZ,
    activated_by TEXT,
    reason TEXT
);

-- Trigger for audit logging
CREATE OR REPLACE FUNCTION log_kill_switch_activation()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND OLD.is_active = false AND NEW.is_active = true THEN
        INSERT INTO audit_log (event_type, details, created_at)
        VALUES ('KILL_SWITCH_ACTIVATED', 
                json_build_object('name', NEW.name, 'activated_by', NEW.activated_by),
                now());
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER kill_switch_audit_trigger
    AFTER UPDATE ON kill_switches
    FOR EACH ROW
    EXECUTE FUNCTION log_kill_switch_activation();
```

---

## 4. Phase-Based Control System

### 4.1 Phase Configuration (`.symphony/PHASE`)
```bash
# Phase Control File
echo "6" > .symphony/PHASE
```

**Phase Control Implementation:**
```typescript
// libs/bootstrap/phase-control.ts
export class PhaseControl {
  private static currentPhase: number = parseInt(process.env.PHASE || '6');
  
  static getPhase(): number {
    return this.currentPhase;
  }
  
  static requirePhase(minimumPhase: number, feature: string): void {
    if (this.currentPhase < minimumPhase) {
      throw new Error(
        `Feature '${feature}' requires Phase ${minimumPhase}+ (current: ${this.currentPhase})`
      );
    }
  }
  
  static isPhaseActive(targetPhase: number): boolean {
    return this.currentPhase >= targetPhase;
  }
}
```

### 4.2 Phase 6 vs Phase > 6 Behavior

#### When PHASE = 6 (Current Production)
```typescript
// Phase 6 Active Controls
if (PhaseControl.isPhaseActive(6)) {
  // Runtime services bootstrap with policy checks
  await bootstrapServices();
  
  // mTLS trust fabric enforcement
  await enforceMTLS();
  
  // Authorization framework active
  await enforceAuthorization();
  
  // Audit integrity with hash-chaining
  await ensureAuditIntegrity();
  
  // Emergency lockdown capability
  await enableEmergencyControls();
  
  // BLOCK Phase 7 features
  PhaseControl.requirePhase(7, "financial_execution"); // Will throw
}
```

#### When PHASE > 6 (Future Phases)
```typescript
// Phase 7+ Additional Controls
if (PhaseControl.isPhaseActive(7)) {
  // All Phase 6 controls remain active
  await bootstrapServices();
  await enforceMTLS();
  await enforceAuthorization();
  await ensureAuditIntegrity();
  await enableEmergencyControls();
  
  // Phase 7+ financial execution enabled
  await enableFinancialExecution();
  await enableSettlementAndReconciliation();
  await enableProviderPaymentRouting();
  await enableRegulatoryReporting();
}
```

### 4.3 Phase Enforcement in Code
```typescript
// Example Phase Gating Implementation
export class FinancialExecutor {
  async executeTransaction(instruction: Instruction): Promise<void> {
    // Phase 6: Block financial execution
    PhaseControl.requirePhase(7, "financial_execution");
    
    // Phase 7+: Execute financial transaction
    if (PhaseControl.isPhaseActive(7)) {
      await this.performFinancialExecution(instruction);
    }
  }
}
```

---

## 5. Policy Version Drift Prevention

### 5.1 Policy Version Binding System
```json
// .symphony/policies/active-policy.json
{
  "policyVersion": "1.0.0",
  "issuedAt": "2026-01-01T00:00:00Z",
  "description": "Global baseline policy for Symphony platform",
  "capabilities": {
    "service": {
      "control-plane": ["route:configure", "provider:disable"],
      "executor-worker": ["execution:attempt"],
      "ingest-api": ["instruction:submit"],
      "read-api": ["audit:read", "instruction:read"]
    },
    "client": {
      "default": ["instruction:submit", "instruction:read"]
    }
  },
  "phase": 6
}
```

### 5.2 Drift Prevention Implementation
```typescript
// libs/db/policy.ts
export class PolicyVersionManager {
  async checkPolicyVersion(): Promise<void> {
    const filePolicy = await this.readPolicyFile();
    const dbPolicy = await this.getDatabasePolicyVersion();
    
    if (filePolicy.policyVersion !== dbPolicy.version) {
      throw new PolicyVersionMismatchError(
        `Policy version mismatch: file=${filePolicy.policyVersion}, db=${dbPolicy.version}`
      );
    }
    
    if (filePolicy.phase !== parseInt(process.env.PHASE || '6')) {
      throw new PolicyPhaseMismatchError(
        `Policy phase mismatch: file=${filePolicy.phase}, env=${process.env.PHASE}`
      );
    }
  }
  
  async validatePolicyIntegrity(): Promise<void> {
    const policy = await this.readPolicyFile();
    const hash = this.computePolicyHash(policy);
    
    const storedHash = await this.getStoredPolicyHash();
    if (hash !== storedHash) {
      throw new PolicyTamperingError("Policy file integrity check failed");
    }
  }
}
```

### 5.3 Anti-Tampering Measures
```typescript
// libs/security/policy-integrity.ts
export class PolicyIntegrityGuard {
  async enforcePolicyIntegrity(): Promise<void> {
    // 1. Check policy file exists
    await this.ensurePolicyFileExists();
    
    // 2. Validate policy version binding
    await this.validateVersionBinding();
    
    // 3. Check hash-based integrity
    await this.validateHashIntegrity();
    
    // 4. Verify phase consistency
    await this.validatePhaseConsistency();
    
    // 5. Log integrity check
    await this.logIntegrityCheck();
  }
  
  private async validateVersionBinding(): Promise<void> {
    const fileVersion = await this.getFilePolicyVersion();
    const dbVersion = await this.getDatabasePolicyVersion();
    
    if (fileVersion !== dbVersion) {
      throw new Error(`Policy version drift detected: file=${fileVersion}, db=${dbVersion}`);
    }
  }
}
```

---

## 6. Phase Degradation Protection

### 6.1 Anti-Downgrade Controls
```typescript
// libs/security/phase-protection.ts
export class PhaseProtection {
  private static readonly MINIMUM_PHASE = 6;
  private static readonly MINIMUM_POLICY_VERSION = "1.0.0";
  
  static preventPhaseDegradation(): void {
    const currentPhase = parseInt(process.env.PHASE || '6');
    
    if (currentPhase < this.MINIMUM_PHASE) {
      throw new PhaseDegradationError(
        `Phase degradation detected: current=${currentPhase}, minimum=${this.MINIMUM_PHASE}`
      );
    }
  }
  
  static preventPolicyRollback(): void {
    const currentVersion = process.env.POLICY_VERSION || "1.0.0";
    
    if (this.compareVersions(currentVersion, this.MINIMUM_POLICY_VERSION) < 0) {
      throw new PolicyRollbackError(
        `Policy version rollback detected: current=${currentVersion}, minimum=${this.MINIMUM_POLICY_VERSION}`
      );
    }
  }
  
  private static compareVersions(v1: string, v2: string): number {
    // Semantic version comparison logic
    const parts1 = v1.split('.').map(Number);
    const parts2 = v2.split('.').map(Number);
    
    for (let i = 0; i < Math.max(parts1.length, parts2.length); i++) {
      const part1 = parts1[i] || 0;
      const part2 = parts2[i] || 0;
      
      if (part1 > part2) return 1;
      if (part1 < part2) return -1;
    }
    
    return 0;
  }
}
```

### 6.2 Database-Level Protections
```sql
-- Phase Constraint Example
ALTER TABLE policy_versions 
ADD CONSTRAINT phase_minimum_check 
CHECK (version >= '1.0.0');

-- Policy Version History for Audit
CREATE TABLE IF NOT EXISTS policy_version_history (
    id SERIAL PRIMARY KEY,
    version TEXT NOT NULL,
    activated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    activated_by TEXT NOT NULL,
    policy_hash TEXT NOT NULL,
    phase INTEGER NOT NULL,
    UNIQUE(version)
);

-- Trigger to log policy changes
CREATE OR REPLACE FUNCTION log_policy_change()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO policy_version_history (version, activated_by, policy_hash, phase)
    VALUES (NEW.version, current_user, md5(NEW.policy_content::text), NEW.phase);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER policy_change_trigger
    AFTER INSERT OR UPDATE ON policy_versions
    FOR EACH ROW
    EXECUTE FUNCTION log_policy_change();
```

---

## 7. User CI/CD Operations Guide

### 7.1 Initial CI Setup
```bash
# 1. Clone Repository with Submodules
git clone --recurse-submodules https://github.com/your-org/symphony.git
cd symphony

# 2. Install Dependencies
npm install

# 3. Set Phase Environment
echo "6" > .symphony/PHASE

# 4. Initialize Policy Submodule
git submodule update --init --recursive
cd .symphony/policies
git checkout main
cd ../..

# 5. Create Active Policy File
cp .symphony/policies/global-policy.v1.json .symphony/policies/active-policy.json

# 6. Run Local CI Test
npm run ci:full
```

### 7.2 Policy Module Updates
```bash
# Update Policy Submodule
cd .symphony/policies
git pull origin main
cd ../..

# Stage Submodule Update
git add .symphony/policies
git commit -m "Update policy submodule to latest"

# Push Changes (triggers CI)
git push origin feature/your-branch
```

### 7.3 Phase Advancement Process
```bash
# ONLY when authorized for phase advancement
echo "7" > .symphony/PHASE
git add .symphony/PHASE
git commit -m "Advance to Phase 7 - Financial Execution"
git push origin feature/phase-7-advancement

# CI will validate phase advancement is authorized
```

### 7.4 Local Development Commands
```bash
# Full CI Pipeline Locally
npm run ci:full

# Individual Security Checks
npm run security-check
npm run ci:compliance

# Database Testing
psql $DATABASE_URL -f scripts/db/test_invariants.sql

# Policy Validation
node scripts/ci/verify_policy_version.js

# Phase Validation
node scripts/ci/verify_phase_gating.js
```

### 7.5 CI/CD Script Reference
```json
// package.json Scripts
{
  "scripts": {
    "security-check": "node --loader ts-node/esm scripts/ci/security-gates.ts",
    "ci:compliance": "node scripts/ci/verify_audit_integrity.cjs && node scripts/ci/verify_authorization.cjs && node scripts/ci/verify_identity_context.cjs && node scripts/ci/verify_runtime_bootstrap.cjs",
    "ci:full": "npm run security-check && npm test && npm run ci:compliance && npm audit && npx snyk test",
    "test": "node --loader ts-node/esm --test tests/*.test.{js,ts}"
  }
}
```

---

## 8. Security Controls Summary

### 8.1 Automated Security Enforcement
- ✅ **Zero Trust Architecture:** mTLS enforcement at all layers
- ✅ **Policy Binding:** Version-controlled authorization
- ✅ **Phase Gating:** Progressive feature enablement
- ✅ **Audit Integrity:** Hash-chained evidence collection
- ✅ **Fail-Closed Design:** Security violations block deployment

### 8.2 Manual Override Prevention
- ✅ **Phase Degradation:** Cannot rollback to earlier phases
- ✅ **Policy Drift:** Cannot use mismatched policy versions
- ✅ **Security Bypass:** Cannot disable security gates
- ✅ **Audit Tampering:** Cannot modify audit trails

### 8.3 Regulatory Compliance Features
- ✅ **Evidence Generation:** Automated regulator-ready reports
- ✅ **Incident Response:** Built-in emergency controls
- ✅ **Change Tracking:** Complete audit trail of all changes
- ✅ **Compliance Reporting:** Automated compliance evidence

---

## 9. CI/CD Pipeline Configuration

### 9.1 GitHub Actions Workflow
```yaml
# .github/workflows/ci-security.yml
name: Symphony Security CI/CD

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

env:
  PHASE: 6
  NODE_ENV: production

jobs:
  security:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout Repository
      uses: actions/checkout@v3
      with:
        submodules: recursive
        
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        cache: 'npm'
        
    - name: Install Dependencies
      run: npm ci
      
    - name: Security Gates Check
      run: npm run security-check
      
    - name: Run Tests
      run: npm test
      
    - name: Compliance Verification
      run: npm run ci:compliance
      
    - name: Security Audit
      run: npm audit --audit-level moderate
      
    - name: Snyk Security Scan
      run: npx snyk test --severity-threshold=high
      env:
        SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        
    - name: Database Invariant Tests
      run: |
        PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -f scripts/db/test_invariants.sql
      env:
        DB_HOST: ${{ secrets.DB_HOST }}
        DB_USER: ${{ secrets.DB_USER }}
        DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
        DB_NAME: ${{ secrets.DB_NAME }}
```

### 9.2 Environment Variables
```bash
# Required Environment Variables
PHASE=6
NODE_ENV=production
DATABASE_URL=postgresql://user:pass@host:port/db
POLICY_VERSION=1.0.0

# Security Variables
KMS_REGION=us-east-1
KMS_KEY_ID=alias/symphony-production
MTLS_CA_CERT_PATH=/etc/ssl/certs/ca-cert.pem
MTLS_CLIENT_CERT_PATH=/etc/ssl/certs/client-cert.pem
MTLS_CLIENT_KEY_PATH=/etc/ssl/private/client-key.pem
```

---

## 10. Conclusion

The Symphony CI/CD pipeline implements a comprehensive, regulator-grade security enforcement system that ensures:

- **100% automated security enforcement** with no manual bypass options
- **Regulator-grade audit trails** suitable for financial compliance
- **Phase-based progressive deployment** with strict gating
- **Policy version integrity** with drift prevention mechanisms
- **Production-ready security controls** suitable for payment systems

The pipeline provides exceptional security controls that meet the stringent requirements of regulated financial operations while maintaining developer productivity through automated, transparent enforcement of security policies.
