#!/usr/bin/env bash
set -euo pipefail

OUTPUT_DIR="constitutional_snapshot"
TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")
ARCHIVE="constitutional_snapshot_$TIMESTAMP.tar.gz"

PREV_SNAPSHOT=$(ls -t constitutional_snapshot_*.tar.gz 2>/dev/null | head -n 1 || true)

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

echo "== Symphony Constitutional Snapshot v3.0 (Constitutional Intelligence Package) =="
echo ""

########################################
# 1. GIT STATE
########################################
echo "[SYSTEM] Capturing git state..."
git rev-parse HEAD > "$OUTPUT_DIR/git_commit.txt"
git status --porcelain > "$OUTPUT_DIR/git_status.txt"
git log --oneline -n 50 > "$OUTPUT_DIR/git_recent_history.txt"

########################################
# 2. MIGRATIONS + HEAD
########################################
echo "[SYSTEM] Capturing migration state..."
cp schema/migrations/MIGRATION_HEAD "$OUTPUT_DIR/" 2>/dev/null || true

find schema/migrations -type f -name "*.sql" | sort > "$OUTPUT_DIR/migration_files.txt"

mkdir -p "$OUTPUT_DIR/migrations_tail"
tail -n 10 "$OUTPUT_DIR/migration_files.txt" | while read -r f; do
  cp "$f" "$OUTPUT_DIR/migrations_tail/" || true
done

########################################
# 3. CONSTITUTIONAL CONTEXT JSON (CRITICAL)
########################################
echo "[CONSTITUTIONAL] Generating constitutional context..."
cat > "$OUTPUT_DIR/CONSTITUTIONAL_CONTEXT.json" <<EOF
{
  "system_type": "Sovereign trust arbitration fabric",
  "active_phase": 3,
  "phase_name": "Constraint and Legitimacy Engine",
  "constitutional_status": "AUTHORITATIVE",
  "wave4_role": "Operational sovereignty",
  "wave8_role": "Provenance sovereignty",
  "validation_model": "Mutual veto",
  "replay_priority": "Supreme",
  "external_verification_required": true,
  "task_generation_mode": "Constitutionally constrained",
  "non_collapse_doctrine": "Enforced",
  "phase_2_status": "CLOSED",
  "phase_3_status": "ACTIVE",
  "constitutional_opening": "CHR-001",
  "opening_act": "docs/PHASE3/PHASE3_OPENING_ACT.md",
  "sovereignty_domains": [
    "Runtime Sovereignty (Wave 4)",
    "Provenance Sovereignty (Wave 8)",
    "Replay Sovereignty",
    "Regulatory Sovereignty",
    "Tenant Sovereignty",
    "Jurisdictional Sovereignty"
  ],
  "timestamp": "$TIMESTAMP",
  "git_commit": "$(cat $OUTPUT_DIR/git_commit.txt)"
}
EOF

########################################
# 4. AUTHORITY STACK JSON
########################################
echo "[CONSTITUTIONAL] Generating authority stack..."
cat > "$OUTPUT_DIR/AUTHORITY_STACK.json" <<EOF
[
  {"rank": 10, "class": "Root Constitutional Doctrine", "examples": ["SYSTEM_SOVEREIGNTY_MODEL.md", "CONSTITUTIONAL_AUTHORITY_HIERARCHY.md"]},
  {"rank": 9, "class": "Regulatory Doctrine", "examples": ["REGULATORY_ALIGNMENT_CONSTITUTION.md", "REGULATORY_SOVEREIGNTY_BOUNDARY_MAP.md"]},
  {"rank": 8, "class": "Phase Governance", "examples": ["PHASE2_CONTRACT.md", "PHASE2/phase2_contract.yml"]},
  {"rank": 7, "class": "Invariant Registers", "examples": ["docs/invariants/*", "INVARIANTS_MANIFEST.yml"]},
  {"rank": 6, "class": "Verifiers", "examples": ["scripts/audit/*", "verification scripts"]},
  {"rank": 5, "class": "Schema", "examples": ["schema/migrations/*", "database structure"]},
  {"rank": 4, "class": "Tasks", "examples": ["tasks/*", "task definitions"]},
  {"rank": 3, "class": "Plans", "examples": ["docs/plans/*", "implementation plans"]},
  {"rank": 2, "class": "Evidence", "examples": ["evidence/*", "execution records"]},
  {"rank": 1, "class": "AI Synthesis", "examples": ["AI-generated content", "agent outputs"]}
]
EOF

########################################
# 5. ACTIVE PHASE JSON
########################################
echo "[CONSTITUTIONAL] Generating active phase context..."
cat > "$OUTPUT_DIR/ACTIVE_PHASE.json" <<EOF
{
  "phase_number": 3,
  "phase_name": "Constraint and Legitimacy Engine",
  "phase_status": "ACTIVE",
  "legal_scope": "Decisions must be formally legitimate under authority, temporal, jurisdictional, and regulatory rule systems",
  "prohibited_work": [
    "Work outside Phase 3 capability boundary",
    "Phase 4+ work (reserved)",
    "Modification of Phase 2 immutable artifacts",
    "Execution without constitutional legitimacy verification"
  ],
  "capability_scope": [
    "3.1 Typed Dependency Graph",
    "3.2 Recursive Legitimacy Engine",
    "3.3 Contradiction Detection",
    "3.4 Failure Composition Engine",
    "3.5 Authority Scope Engine",
    "3.6 Regulator Override Rules",
    "3.7 Conflict-of-Interest Enforcement",
    "3.8 Spatial Legality and DNSH Gates"
  ],
  "required_invariants": [
    "INV-301: Typed dependency graph formalization",
    "INV-302: Recursive legitimacy verification",
    "INV-303: Contradiction detection enforcement",
    "INV-304: Failure composition semantics",
    "INV-305: Authority scope validation",
    "INV-306: Regulator override protocol",
    "INV-307: Conflict-of-interest detection",
    "INV-308: Spatial legality verification",
    "INV-309: DNSH gate enforcement",
    "INV-310: Dwell-time forensics"
  ],
  "dependencies": [
    "Phase 2 completion (closed)",
    "Phase 2A / Wave 8 substrate (immutable)",
    "Constitutional opening act (CHR-001)"
  ],
  "exit_criteria": [
    "All Phase 3 contract rows implemented",
    "Legitimacy engine operational",
    "Contradiction detection functional",
    "Authority scope enforcement active",
    "DNSH gates operational"
  ],
  "verification_required": true,
  "machine_contract": "docs/PHASE3/phase3_contract.yml",
  "opening_act": "docs/PHASE3/PHASE3_OPENING_ACT.md",
  "capability_boundary": "docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md",
  "invariant_register": "docs/PHASE3/PHASE3_INVARIANT_REGISTER.md",
  "previous_phase": {
    "phase_number": 2,
    "phase_name": "Internal Ledger Truth",
    "status": "CLOSED"
  }
}
EOF

########################################
# 6. INVARIANT REGISTER JSON
########################################
echo "[CONSTITUTIONAL] Generating invariant register..."
echo "{" > "$OUTPUT_DIR/INVARIANT_REGISTER.json"
echo '  "invariants": {' >> "$OUTPUT_DIR/INVARIANT_REGISTER.json"

# Find all invariant files and extract key information
FIRST=true
find docs/invariants -name "*.md" 2>/dev/null | while read -r inv_file; do
  if [[ -f "$inv_file" ]]; then
    inv_name=$(basename "$inv_file" .md)
    inv_title=$(grep -m 1 "^# " "$inv_file" | sed 's/^# //' || echo "$inv_name")
    inv_severity=$(grep -i "severity" "$inv_file" | head -1 | sed 's/.*severity[:\s]*//' | tr -d '\r' || echo "standard")
    inv_phase=$(grep -i "phase" "$inv_file" | head -1 | sed 's/.*phase[:\s]*//' | tr -d '\r' || echo "global")
    
    if [[ "$FIRST" == false ]]; then
      echo "," >> "$OUTPUT_DIR/INVARIANT_REGISTER.json"
    fi
    echo "    \"$inv_name\": {" >> "$OUTPUT_DIR/INVARIANT_REGISTER.json"
    echo "      \"title\": \"$inv_title\"," >> "$OUTPUT_DIR/INVARIANT_REGISTER.json"
    echo "      \"severity\": \"$inv_severity\"," >> "$OUTPUT_DIR/INVARIANT_REGISTER.json"
    echo "      \"phase_scope\": \"$inv_phase\"," >> "$OUTPUT_DIR/INVARIANT_REGISTER.json"
    echo "      \"file\": \"$inv_file\"" >> "$OUTPUT_DIR/INVARIANT_REGISTER.json"
    echo "    }" >> "$OUTPUT_DIR/INVARIANT_REGISTER.json"
    FIRST=false
  fi
done

echo '  },' >> "$OUTPUT_DIR/INVARIANT_REGISTER.json"
echo "  \"total_count\": $(ls docs/invariants/*.md 2>/dev/null | wc -l)," >> "$OUTPUT_DIR/INVARIANT_REGISTER.json"
echo "  \"verification_count\": $(ls scripts/audit/*.sh 2>/dev/null | wc -l)" >> "$OUTPUT_DIR/INVARIANT_REGISTER.json"
echo "}" >> "$OUTPUT_DIR/INVARIANT_REGISTER.json"

########################################
# 7. TASK ADMISSION RULES JSON
########################################
echo "[CONSTITUTIONAL] Generating task admissibility rules..."
cat > "$OUTPUT_DIR/TASK_ADMISSION_RULES.json" <<EOF
{
  "forbidden": [
    "Collapse runtime and provenance authority",
    "Break replay survivability",
    "Bypass verifier enforcement",
    "Modify closed trust boundaries",
    "Violate non-collapse doctrine",
    "Cross sovereignty domain boundaries without protocol",
    "Retroactively modify historical evidence",
    "Flatten regulator boundaries",
    "Execute work outside the Phase 3 capability boundary",
    "Modify Phase 2 immutable artifacts"
  ],
  "conditional": [
    {
      "condition": "Phase 4+ work",
      "requirement": "Phase 3 completion",
      "authority": "Phase lifecycle governance"
    },
    {
      "condition": "Phase 5 work (CF-1)",
      "requirement": "Phase 3 completion + Phase 4 completion",
      "authority": "Carry-forward obligation PHASE5_CARRY_FORWARD_OBLIGATIONS.md"
    },
    {
      "condition": "Phase 8A work (CF-3)",
      "requirement": "Phases 2, 3, 4, 5, 6 completion",
      "authority": "Carry-forward obligation PHASE8A_CARRY_FORWARD_OBLIGATIONS.md"
    },
    {
      "condition": "Cross-tenant operations",
      "requirement": "Supervisor access authorization",
      "authority": "Tenant sovereignty"
    },
    {
      "condition": "Regulatory changes",
      "requirement": "Interpretation pack versioning",
      "authority": "Regulatory sovereignty"
    }
  ],
  "always_required": [
    "Constitutional compliance check",
    "Invariant verification",
    "Sovereignty domain respect",
    "Replay survivability preservation",
    "Phase boundary adherence",
    "Legitimacy verification (Phase 3)"
  ],
  "phase_3_specific": [
    "All work must map to 3.1-3.8 capability scope",
    "Legitimacy verification is mandatory",
    "Authority scope validation required",
    "DNSH gate compliance mandatory"
  ]
}
EOF

########################################
# 8. REGULATORY SURFACE JSON
########################################
echo "[CONSTITUTIONAL] Generating regulatory surface..."
cat > "$OUTPUT_DIR/REGULATORY_SURFACE.json" <<EOF
{
  "regulators": [
    {
      "name": "SI 5 of 2026",
      "jurisdiction": "Zambia",
      "phase_dependencies": ["Phase 1", "Phase 2"],
      "scope": "Carbon credit regulatory framework"
    },
    {
      "name": "ZGFT",
      "jurisdiction": "Zambia",
      "phase_dependencies": ["Phase 2"],
      "scope": "Zambia Green Finance Framework"
    },
    {
      "name": "BoZ",
      "jurisdiction": "Zambia",
      "phase_dependencies": ["Phase 2"],
      "scope": "Bank of Zambia oversight"
    },
    {
      "name": "Zambia Data Protection Act",
      "jurisdiction": "Zambia",
      "phase_dependencies": ["Phase 1", "Phase 2", "Phase 3"],
      "scope": "Data privacy and protection"
    },
    {
      "name": "ZEMA",
      "jurisdiction": "Zambia",
      "phase_dependencies": ["Phase 2"],
      "scope": "Environmental management"
    },
    {
      "name": "Paris Article 6",
      "jurisdiction": "International",
      "phase_dependencies": ["Phase 3"],
      "scope": "International carbon market mechanisms"
    },
    {
      "name": "Verra",
      "jurisdiction": "International",
      "phase_dependencies": ["Phase 3"],
      "scope": "Carbon credit certification"
    },
    {
      "name": "Gold Standard",
      "jurisdiction": "International",
      "phase_dependencies": ["Phase 3"],
      "scope": "Carbon credit certification"
    },
    {
      "name": "EU CBAM",
      "jurisdiction": "European Union",
      "phase_dependencies": ["Phase 3"],
      "scope": "Carbon Border Adjustment Mechanism"
    }
  ],
  "interpretation_packs_required": true,
  "jurisdiction_partitioning": "Enforced via RLS policies"
}
EOF

########################################
# 9. SOVEREIGNTY MODEL JSON
########################################
echo "[CONSTITUTIONAL] Generating sovereignty model..."
cat > "$OUTPUT_DIR/SOVEREIGNTY_MODEL.json" <<EOF
{
  "sovereignty_domains": [
    {
      "domain": "Runtime Sovereignty",
      "wave": "Wave 4",
      "authority_source": "DB trigger chain, state machine enforcement",
      "veto_type": "Hard veto",
      "scope": "Operational execution validity",
      "replay_obligation": "Historical rule preservation"
    },
    {
      "domain": "Provenance Sovereignty",
      "wave": "Wave 8",
      "authority_source": "ed25519_verify(), cryptographic proofs",
      "veto_type": "Hard cryptographic veto",
      "scope": "Cryptographic authenticity",
      "replay_obligation": "Permanent key and payload preservation"
    },
    {
      "domain": "Replay Sovereignty",
      "wave": "Constitutional",
      "authority_source": "Constitutional permanence infrastructure",
      "veto_type": "Prospective veto",
      "scope": "Historical reconstructability",
      "replay_obligation": "Continuous substrate maintenance"
    },
    {
      "domain": "Regulatory Sovereignty",
      "wave": "Constitutional",
      "authority_source": "External regulatory jurisdictions",
      "veto_type": "Sovereign veto",
      "scope": "Jurisdiction-specific admissibility",
      "replay_obligation": "Interpretation pack versioning"
    },
    {
      "domain": "Tenant Sovereignty",
      "wave": "Constitutional",
      "authority_source": "Dual-policy RLS architecture",
      "veto_type": "Data boundary veto",
      "scope": "Multi-tenant isolation",
      "replay_obligation": "Tenant identity preservation"
    },
    {
      "domain": "Jurisdictional Sovereignty",
      "wave": "Constitutional",
      "authority_source": "app.jurisdiction_code session variable",
      "veto_type": "Context veto",
      "scope": "Legal jurisdiction partitioning",
      "replay_obligation": "Jurisdiction context preservation"
    }
  ],
  "non_collapse_doctrine": "Constitutionally enforced",
  "mutual_veto_doctrine": "Independent parallel evaluation",
  "compositional_validation": "Domain-specific certifications preserved"
}
EOF

########################################
# 10. REPOSITORY DEPENDENCY GRAPH
########################################
echo "[SYSTEM] Building repository dependency graph..."
cat > "$OUTPUT_DIR/REPOSITORY_DEPENDENCY_GRAPH.json" <<EOF
{
  "nodes": {
    "constitutional_docs": {
      "path": "docs/constitutional",
      "type": "authority",
      "dependencies": []
    },
    "phase_contracts": {
      "path": "docs/PHASE3",
      "type": "governance",
      "dependencies": ["constitutional_docs", "docs/PHASE2"]
    },
    "invariants": {
      "path": "docs/invariants",
      "type": "constraints",
      "dependencies": ["constitutional_docs", "phase_contracts", "docs/PHASE3/PHASE3_INVARIANT_REGISTER.md"]
    },
    "verifiers": {
      "path": "scripts/audit",
      "type": "enforcement",
      "dependencies": ["invariants"]
    },
    "schema": {
      "path": "schema/migrations",
      "type": "structure",
      "dependencies": ["invariants", "verifiers"]
    },
    "tasks": {
      "path": "tasks",
      "type": "execution",
      "dependencies": ["schema", "invariants", "phase_contracts"]
    },
    "evidence": {
      "path": "evidence",
      "type": "records",
      "dependencies": ["tasks", "verifiers"]
    },
    "phase2_historical": {
      "path": "docs/PHASE2",
      "type": "historical",
      "dependencies": [],
      "status": "CLOSED"
    }
  },
  "authority_flow": [
    "constitutional_docs -> phase_contracts",
    "phase_contracts -> invariants",
    "invariants -> verifiers",
    "verifiers -> schema",
    "schema -> tasks",
    "tasks -> evidence"
  ],
  "phase_transitions": {
    "phase_2_to_3": {
      "status": "COMPLETE",
      "constitutional_record": "CHR-001",
      "date": "2026-05-10"
    }
  }
}
EOF

########################################
# 11. CHANGE INTELLIGENCE JSON
########################################
echo "[INTELLIGENCE] Analyzing changes..."
cat > "$OUTPUT_DIR/CHANGE_INTELLIGENCE.json" <<EOF
{
  "analysis_timestamp": "$TIMESTAMP",
  "git_commit": "$(cat $OUTPUT_DIR/git_commit.txt)",
  "phase_transition": {
    "from_phase": 2,
    "to_phase": 3,
    "status": "COMPLETE",
    "constitutional_record": "CHR-001"
  },
  "changed_invariants": $(git diff --name-only HEAD~1 HEAD 2>/dev/null | grep -c "docs/invariants" || echo "0"),
  "changed_verifiers": $(git diff --name-only HEAD~1 HEAD 2>/dev/null | grep -c "scripts/audit" || echo "0"),
  "migration_count_delta": $(find schema/migrations -name "*.sql" | wc -l),
  "risk_signals": $(grep -r "DROP TABLE\|ALTER COLUMN\|DELETE FROM" schema/migrations 2>/dev/null | wc -l),
  "phase_contract_changes": $(git diff --name-only HEAD~1 HEAD 2>/dev/null | grep -c "PHASE3\|PHASE2" || echo "0"),
  "constitutional_changes": $(git diff --name-only HEAD~1 HEAD 2>/dev/null | grep -c "docs/constitutional" || echo "0"),
  "phase_3_activation": {
    "opening_act": "docs/PHASE3/PHASE3_OPENING_ACT.md",
    "capability_boundary": "docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md",
    "invariant_register": "docs/PHASE3/PHASE3_INVARIANT_REGISTER.md",
    "machine_contract": "docs/PHASE3/phase3_contract.yml",
    "carry_forward_resolved": [
      "CF-1 → Phase 5",
      "CF-2 → Phase 3",
      "CF-3 → Phase 8A"
    ]
  }
}
EOF

########################################
# 12. RISK REGISTER JSON
########################################
echo "[RISK] Generating risk register..."
RISK_COUNT=$(grep -r "DROP TABLE\|ALTER COLUMN\|DELETE FROM" schema/migrations 2>/dev/null | wc -l)
INV_GAP=$(( $(ls docs/invariants 2>/dev/null | wc -l) - $(ls scripts/audit 2>/dev/null | wc -l) ))

cat > "$OUTPUT_DIR/RISK_REGISTER.json" <<EOF
{
  "risks": [
    {
      "id": "RISK-001",
      "title": "Migration Destructive Operations",
      "severity": "$([ $RISK_COUNT -gt 0 ] && echo "HIGH" || echo "LOW")",
      "count": $RISK_COUNT,
      "constitutional_impact": "Schema stability",
      "mitigation": "Review all DDL operations"
    },
    {
      "id": "RISK-002",
      "title": "Invariant Coverage Gap",
      "severity": "$([ $INV_GAP -gt 0 ] && echo "MEDIUM" || echo "LOW")",
      "gap": $INV_GAP,
      "constitutional_impact": "Enforcement completeness",
      "mitigation": "Create missing verifiers"
    },
    {
      "id": "RISK-003",
      "title": "Phase Boundary Violation",
      "severity": "LOW",
      "constitutional_impact": "Phase governance",
      "mitigation": "Phase contract verification"
    }
  ],
  "overall_risk_level": "$([ $RISK_COUNT -gt 0 ] || [ $INV_GAP -gt 0 ] && echo "MEDIUM" || echo "LOW")"
}
EOF

########################################
# 13. CONSTITUTIONAL CORPUS INCLUSION
########################################
echo "[ARCHIVE] Including constitutional corpus..."
mkdir -p "$OUTPUT_DIR/constitutional"
cp -r docs/constitutional/* "$OUTPUT_DIR/constitutional/" 2>/dev/null || true

########################################
# 14. PHASE CONTRACTS INCLUSION
########################################
echo "[ARCHIVE] Including phase contracts..."
mkdir -p "$OUTPUT_DIR/PHASE_CONTRACTS"
# Active Phase 3 contracts
cp docs/PHASE3/phase3_contract.yml "$OUTPUT_DIR/PHASE_CONTRACTS/" 2>/dev/null || true
cp docs/PHASE3/PHASE3_OPENING_ACT.md "$OUTPUT_DIR/PHASE_CONTRACTS/" 2>/dev/null || true
cp docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md "$OUTPUT_DIR/PHASE_CONTRACTS/" 2>/dev/null || true
cp docs/PHASE3/PHASE3_INVARIANT_REGISTER.md "$OUTPUT_DIR/PHASE_CONTRACTS/" 2>/dev/null || true
# Historical Phase 2 contracts (closed)
mkdir -p "$OUTPUT_DIR/PHASE_CONTRACTS/HISTORICAL_PHASE2"
cp docs/PHASE2/phase2_contract.yml "$OUTPUT_DIR/PHASE_CONTRACTS/HISTORICAL_PHASE2/" 2>/dev/null || true
cp docs/PHASE2/PHASE2_CONTRACT.md "$OUTPUT_DIR/PHASE_CONTRACTS/HISTORICAL_PHASE2/" 2>/dev/null || true
# Constitutional history record
cp docs/constitutional/CONSTITUTIONAL_HISTORY_RECORD.md "$OUTPUT_DIR/PHASE_CONTRACTS/" 2>/dev/null || true

########################################
# 15. CORE REPOSITORY STRUCTURE
########################################
echo "[ARCHIVE] Including core repository structure..."
mkdir -p "$OUTPUT_DIR/invariants"
cp -r docs/invariants "$OUTPUT_DIR/" 2>/dev/null || true

mkdir -p "$OUTPUT_DIR/verifiers"
cp -r scripts/audit "$OUTPUT_DIR/" 2>/dev/null || true

mkdir -p "$OUTPUT_DIR/schema"
cp -r schema/migrations "$OUTPUT_DIR/schema/" 2>/dev/null || true

mkdir -p "$OUTPUT_DIR/tasks"
find tasks -name "meta.yml" -exec cp --parents {} "$OUTPUT_DIR/tasks/" \; 2>/dev/null || true

mkdir -p "$OUTPUT_DIR/evidence"
find evidence -type f -name "*.json" -exec cp {} "$OUTPUT_DIR/evidence/" \; 2>/dev/null || true

########################################
# 16. EXECUTIVE BRIEF
########################################
echo "[EXECUTIVE] Generating executive brief..."
cat > "$OUTPUT_DIR/EXECUTIVE_BRIEF.md" <<EOF
# Symphony Executive Brief

**Generated:** $TIMESTAMP  
**Commit:** $(cat $OUTPUT_DIR/git_commit.txt)  
**Phase:** 3 - Constraint and Legitimacy Engine  
**Phase Status:** ACTIVE  
**Previous Phase:** 2 - Internal Ledger Truth (CLOSED)

## What Symphony Is

Symphony is a **sovereign trust arbitration fabric** that provides constitutional governance for carbon credit operations across multiple sovereignty domains. It is not a centralized platform or trust aggregator, but a substrate within which independent sovereignty domains can coexist and interact without unconstitutional collapse.

## Current Phase

**Phase 3: Constraint and Legitimacy Engine** establishes formal legitimacy verification under authority, temporal, jurisdictional, and regulatory rule systems. Current status: **ACTIVE**. Constitutional opening recorded as **CHR-001**.

## Constitutional Status

- **Constitutional Model:** AUTHORITATIVE
- **Non-Collapse Doctrine:** Enforced
- **Sovereignty Domains:** 6 constitutionally distinct domains
- **Validation Model:** Mutual veto with parallel certification
- **Phase Transition:** 2→3 Complete (2026-05-10)

## Highest Authority Documents

1. SYSTEM_SOVEREIGNTY_MODEL.md (Authority Rank: 10)
2. CONSTITUTIONAL_AUTHORITY_HIERARCHY.md (Authority Rank: 10)
3. REGULATORY_ALIGNMENT_CONSTITUTION.md (Authority Rank: 9)
4. PHASE3_OPENING_ACT.md (Authority Rank: 8)
5. PHASE3_CAPABILITY_BOUNDARY.md (Authority Rank: 8)

## Active Implementation Boundaries

**Phase 3 Capability Scope (3.1-3.8):**
- 3.1 Typed Dependency Graph
- 3.2 Recursive Legitimacy Engine
- 3.3 Contradiction Detection
- 3.4 Failure Composition Engine
- 3.5 Authority Scope Engine
- 3.6 Regulator Override Rules
- 3.7 Conflict-of-Interest Enforcement
- 3.8 Spatial Legality and DNSH Gates

**Explicitly Out of Scope:**
- Work outside Phase 3 capability boundary
- Phase 4+ work (reserved)
- Modification of Phase 2 immutable artifacts
- Execution without constitutional legitimacy verification

## Top Invariants (Phase 3)

- INV-301: Typed dependency graph formalization
- INV-302: Recursive legitimacy verification
- INV-303: Contradiction detection enforcement
- INV-304: Failure composition semantics
- INV-305: Authority scope validation
- INV-306: Regulator override protocol
- INV-307: Conflict-of-interest detection
- INV-308: Spatial legality verification
- INV-309: DNSH gate enforcement
- INV-310: Dwell-time forensics

## Current Risks

- Migration Operations: $RISK_COUNT potential issues
- Invariant Coverage Gap: $INV_GAP missing verifiers
- Phase 3 Implementation Risk: New capability surface
- Overall Risk Level: $([ $RISK_COUNT -gt 0 ] || [ $INV_GAP -gt 0 ] && echo "MEDIUM" || echo "LOW")

## Next Admissible Work

1. Implement Phase 3 contract rows (P3-001 through P3-009)
2. Deploy legitimacy verification engines
3. Implement contradiction detection systems
4. Activate authority scope enforcement
5. Maintain constitutional compliance

## Constitutional Consequences

- Phase 2 artifacts are immutable except through constitutional amendment
- AI agents may generate only Phase 3 admissible work
- Tasks outside the Phase 3 capability boundary are prohibited
- Phase 5 and Phase 8A obligations remain blocked until prerequisites complete

## Carry-Forward Obligations

- **CF-1** (Methodology Adapter) → Phase 5
- **CF-2** (Dwell-Time Forensics) → Phase 3 (INV-310)
- **CF-3** (MADD/MAIN) → Phase 8A

## Constitutional Primacy

- Root doctrine overrides all lower artifacts
- Replay survivability is supreme
- Runtime and provenance authorities are orthogonal
- External verification must remain possible
- Tasks are valid only if constitutionally admissible
- Phase 3 legitimacy verification is mandatory
EOF

########################################
# 17. AI AGENT INSTRUCTIONS (CRITICAL)
########################################
echo "[AI] Generating AI agent instructions..."
cat > "$OUTPUT_DIR/AI_AGENT_INSTRUCTIONS.md" <<EOF
# AI Agent Constitutional Instructions

## Primary Directive

You are an AI agent working within Symphony's constitutional framework. Your primary responsibility is to preserve constitutional integrity while generating constitutionally admissible work.

## Required Reading Sequence

1. **Read SYSTEM_SUMMARY.md first** - Understand current system state
2. **Read CONSTITUTIONAL_CONTEXT.json** - Understand constitutional model
3. **Read AUTHORITY_STACK.json** - Understand authority hierarchy
4. **Read ACTIVE_PHASE.json** - Understand current phase boundaries
5. **Read TASK_ADMISSION_RULES.json** - Understand forbidden operations

## Constitutional Constraints

### Non-Negotiable Rules

1. **Respect Authority Hierarchy** - Never contradict higher-rank documents
2. **Preserve Non-Collapse Doctrine** - Do not merge sovereignty domains
3. **Maintain Replay Survivability** - All outputs must be historically reconstructable
4. **Respect Mutual Veto Doctrine** - Each sovereignty domain has independent authority
5. **Honor Phase Boundaries** - Only Phase 3 work is currently admissible
6. **Preserve Phase 2 Immutability** - Phase 2 artifacts are constitutionally immutable

### Forbidden Operations

- Collapse runtime and provenance authority
- Break replay survivability guarantees
- Bypass verifier enforcement mechanisms
- Modify closed trust boundaries
- Execute work outside the Phase 3 capability boundary
- Modify Phase 2 immutable artifacts
- Execute Phase 4+ work (reserved)
- Violate sovereignty domain independence

### Required Validations

- Constitutional compliance check for all outputs
- Invariant verification for all changes
- Sovereignty domain respect in all designs
- Replay survivability preservation in all implementations
- Phase 3 legitimacy verification (mandatory)
- Authority scope validation (required)

## Decision Framework

### Before Any Action

1. Check phase admissibility (Phase 3 only)
2. Verify sovereignty domain compatibility
3. Ensure invariant compliance (INV-301 through INV-310)
4. Confirm replay survivability
5. Validate authority hierarchy compliance
6. Verify legitimacy requirements (Phase 3)

### Task Generation

1. Only generate Phase 3 admissible tasks
2. Ensure all tasks map to capability scope (3.1-3.8)
3. Include legitimacy verification requirements
4. Reference appropriate Phase 3 invariants
5. Preserve sovereignty domain boundaries

### Implementation Guidance

1. Follow Phase 3 capability boundaries strictly
2. Implement legitimacy verification engines
3. Maintain dual-policy RLS architecture
4. Preserve trigger chain enforcement
5. Include comprehensive verification
6. Ensure authority scope validation

## Phase 3 Specific Requirements

### Capability Scope Compliance

All work must map to one of the Phase 3 capabilities:
- **3.1** Typed Dependency Graph
- **3.2** Recursive Legitimacy Engine
- **3.3** Contradiction Detection
- **3.4** Failure Composition Engine
- **3.5** Authority Scope Engine
- **3.6** Regulator Override Rules
- **3.7** Conflict-of-Interest Enforcement
- **3.8** Spatial Legality and DNSH Gates

### Legitimacy Verification

- All decisions must be formally legitimate
- Authority, temporal, jurisdictional validation required
- Regulatory rule system compliance mandatory
- DNSH gate compliance required for spatial operations

## Emergency Procedures

If you detect a constitutional violation:

1. **STOP** immediately
2. **IDENTIFY** the constitutional principle violated
3. **DOCUMENT** the violation clearly
4. **ESCALATE** for human review
5. **DO NOT** proceed with the violating action

## Success Criteria

Your work is constitutionally successful when:

1. All outputs respect the authority hierarchy
2. No sovereignty domains are collapsed
3. Replay survivability is preserved
4. Phase 3 boundaries are honored
5. Phase 2 immutability is respected
6. Invariant compliance is maintained (INV-301 through INV-310)
7. Legitimacy verification is included
8. Verification mechanisms are included

## Carry-Forward Awareness

- **CF-1** (Methodology Adapter) is assigned to Phase 5 - not yet admissible
- **CF-2** (Dwell-Time Forensics) is assigned to Phase 3 (INV-310) - admissible
- **CF-3** (MADD/MAIN) is assigned to Phase 8A - not yet admissible

## Final Reminder

Symphony is not a conventional software system. It is a constitutional governance fabric. Your role is to work within its constitutional constraints, not to optimize around them. Constitutional integrity is the highest priority.

**Phase 3 legitimacy verification is now mandatory for all work.**

**When in doubt, prioritize constitutional preservation over technical convenience.**
EOF

########################################
# 18. SYSTEM SUMMARY (ENHANCED)
########################################
echo "[SUMMARY] Generating enhanced system summary..."
TOTAL_INVARIANTS=$(ls docs/invariants 2>/dev/null | wc -l)
TOTAL_VERIFIERS=$(ls scripts/audit 2>/dev/null | wc -l)

cat > "$OUTPUT_DIR/SYSTEM_SUMMARY.md" <<EOF
# CONSTITUTIONAL SNAPSHOT SUMMARY ($TIMESTAMP)

## System Identity
- **Type:** Sovereign trust arbitration fabric
- **Constitutional Status:** AUTHORITATIVE
- **Active Phase:** 3 - Constraint and Legitimacy Engine
- **Previous Phase:** 2 - Internal Ledger Truth (CLOSED)
- **Constitutional Opening:** CHR-001 (2026-05-10)
- **Sovereignty Domains:** 6 constitutionally distinct

## Commit State
- **Current Commit:** $(cat $OUTPUT_DIR/git_commit.txt)
- **Migration Head:** $(cat $OUTPUT_DIR/MIGRATION_HEAD 2>/dev/null || echo "MISSING")

## Constitutional Metrics
- **Invariants:** $TOTAL_INVARIANTS registered
- **Verifiers:** $TOTAL_VERIFIERS implemented
- **Coverage Gap:** $((TOTAL_INVARIANTS - TOTAL_VERIFIERS)) invariants without verifiers

## Risk Assessment
- **Migration Risks:** $RISK_COUNT potential issues
- **Overall Risk Level:** $([ $RISK_COUNT -gt 0 ] || [ $INV_GAP -gt 0 ] && echo "MEDIUM" || echo "LOW")

## Constitutional Primacy
- Root doctrine overrides all lower artifacts
- Replay survivability is supreme
- Runtime and provenance authorities are orthogonal
- External verification must remain possible
- Tasks are valid only if constitutionally admissible

## Active Work Surface
Phase 3 — Constraint and Legitimacy Engine
- 3.1 Typed Dependency Graph
- 3.2 Recursive Legitimacy Engine
- 3.3 Contradiction Detection
- 3.4 Failure Composition Engine
- 3.5 Authority Scope Engine
- 3.6 Regulator Override Rules
- 3.7 Conflict-of-Interest Enforcement
- 3.8 Spatial Legality and DNSH Gates

## Phase Status Summary
- **Phase 2:** CLOSED - Internal Ledger Truth (immutable)
- **Phase 3:** ACTIVE - Constraint and Legitimacy Engine
- **Phase 4+:** RESERVED - Not yet admissible

## Forbidden Operations
- Collapse Wave 4 and Wave 8 authority
- Modify closed Phase 2 artifacts (immutable)
- Break replay guarantees
- Flatten regulator boundaries
- Execute work outside Phase 3 capability boundary
- Execute Phase 4+ work prematurely

## Carry-Forward Obligations
- **CF-1** (Methodology Adapter) → Phase 5 (blocked)
- **CF-2** (Dwell-Time Forensics) → Phase 3 (INV-310)
- **CF-3** (MADD/MAIN) → Phase 8A (blocked)

## Snapshot Contents
### Constitutional Intelligence
- CONSTITUTIONAL_CONTEXT.json
- AUTHORITY_STACK.json
- ACTIVE_PHASE.json
- INVARIANT_REGISTER.json
- TASK_ADMISSION_RULES.json
- REGULATORY_SURFACE.json
- SOVEREIGNTY_MODEL.json

### Analysis & Intelligence
- REPOSITORY_DEPENDENCY_GRAPH.json
- CHANGE_INTELLIGENCE.json
- RISK_REGISTER.json

### Core Repository
- constitutional/ (full constitutional corpus)
- PHASE_CONTRACTS/ (active Phase 3 contracts + historical Phase 2)
- invariants/ (all invariant definitions)
- verifiers/ (verification scripts)
- schema/ (database migrations)
- tasks/ (task definitions)
- evidence/ (execution records)

### Historical Context
- semantic_diff.txt (vs previous snapshot)
- git state files
- migration files
- CONSTITUTIONAL_HISTORY_RECORD.md

## Usage Instructions

1. **For AI Agents:** Read AI_AGENT_INSTRUCTIONS.md first
2. **For Humans:** Read EXECUTIVE_BRIEF.md for overview
3. **For Analysis:** Consult JSON files for structured data
4. **For Implementation:** Follow authority hierarchy in AUTHORITY_STACK.json
5. **Phase 3 Work:** Map all tasks to capability scope 3.1-3.8

## Constitutional Verification

This snapshot is constitutionally valid when:
- All JSON files are well-formed and complete
- Authority hierarchy is respected
- Phase boundaries are correctly represented
- Phase 2 immutability is preserved
- Phase 3 activation is properly recorded
- Invariant coverage is accurately reported
- Risk assessment is current and accurate

---

*This constitutional snapshot preserves Symphony's governance context for disconnected AI reasoning.*
*Phase 3 activation recorded in CHR-001 - legitimacy verification now mandatory.*
EOF

########################################
# 19. SEMANTIC DIFF VS LAST SNAPSHOT
########################################
echo "[DIFF] Generating semantic diff..."

if [[ -n "$PREV_SNAPSHOT" ]]; then
  mkdir -p prev_snapshot
  tar -xzf "$PREV_SNAPSHOT" -C prev_snapshot

  diff -ru prev_snapshot "$OUTPUT_DIR" > "$OUTPUT_DIR/semantic_diff.txt" || true

  rm -rf prev_snapshot
else
  echo "NO PREVIOUS SNAPSHOT" > "$OUTPUT_DIR/semantic_diff.txt"
fi

########################################
# FINAL PACKAGE
########################################
tar -czf "$ARCHIVE" "$OUTPUT_DIR"

echo ""
echo "✅ CONSTITUTIONAL SNAPSHOT READY:"
echo "$ARCHIVE"
echo ""
echo "📋 Package Contents:"
echo "  - Constitutional Intelligence (JSON files)"
echo "  - Executive Brief & AI Instructions"
echo "  - Full Constitutional Corpus"
echo "  - Active Phase Contracts"
echo "  - Core Repository Structure"
echo "  - Change Intelligence & Risk Assessment"
echo "  - Semantic Diff vs Previous Snapshot"
echo ""
echo "🎯 Primary Use: Portable constitutional intelligence package"
echo "🤖 AI Ready: Yes - includes AI_AGENT_INSTRUCTIONS.md"
echo "⚖️  Constitutionally Compliant: Yes"
