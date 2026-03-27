#!/usr/bin/env bash
# scripts/audit/verify_gf_phase2_entry_gate.sh
#
# PURPOSE
# -------
# Mechanical enforcement of the Phase 2 green finance entry gate.
# Checks all seven entry conditions defined in GF_PHASE2_ENTRY_GATE.md.
# Exits non-zero with the blocking condition named if any check fails.
#
# USAGE
# -----
# bash scripts/audit/verify_gf_phase2_entry_gate.sh
#
# Run by agents at the start of any task claiming Phase 2 green finance scope.
# Wired into .github/workflows/green_finance_contract_gate.yml for PRs
# where task meta declares phase: '2' and domain: green_finance.

set -euo pipefail

GATE_PASS=true
FAILED_CONDITIONS=()

echo "==> Green Finance Phase 2 Entry Gate Verification"
echo ""

# ---------------------------------------------------------------------------
# Helper: check evidence file exists and contains status: PASS
# ---------------------------------------------------------------------------
check_evidence() {
    local label="$1"
    local path="$2"

    if [[ ! -f "$path" ]]; then
        echo "❌ FAIL: $label — evidence file not found: $path"
        GATE_PASS=false
        FAILED_CONDITIONS+=("$label: evidence file missing ($path)")
        return 1
    fi

    if grep -q '"status":\s*"PASS"' "$path" 2>/dev/null || grep -q '"status": "PASS"' "$path" 2>/dev/null; then
        echo "✅ PASS: $label — evidence exists and status is PASS"
        return 0
    else
        echo "❌ FAIL: $label — evidence exists but status is not PASS"
        GATE_PASS=false
        FAILED_CONDITIONS+=("$label: evidence status is not PASS ($path)")
        return 1
    fi
}

# ---------------------------------------------------------------------------
# Condition 1: Adapter Registrations (SCH-001)
# ---------------------------------------------------------------------------
echo "=== Condition 1: Adapter Registrations (SCH-001) ==="
check_evidence "SCH-001 adapter_registrations" "evidence/phase0/gf_sch_001.json" || true
echo ""

# ---------------------------------------------------------------------------
# Condition 2: Interpretation Packs (SCH-002)
# ---------------------------------------------------------------------------
echo "=== Condition 2: Interpretation Packs (SCH-002) ==="
check_evidence "SCH-002 interpretation_packs" "evidence/phase0/gf_sch_002.json" || true
echo ""

# ---------------------------------------------------------------------------
# Condition 3: Verifier Registry (SCH-008)
# ---------------------------------------------------------------------------
echo "=== Condition 3: Verifier Registry (SCH-008) ==="
check_evidence "SCH-008 verifier_registry" "evidence/phase0/gf_sch_008.json" || true
echo ""

# ---------------------------------------------------------------------------
# Condition 4: Issue Verifier Read Token (FNC-006)
# ---------------------------------------------------------------------------
echo "=== Condition 4: Issue Verifier Read Token (FNC-006) ==="
check_evidence "FNC-006 issue_verifier_read_token" "evidence/phase1/gf_fnc_006.json" || true
echo ""

# ---------------------------------------------------------------------------
# Condition 5: Core Contract Gate
# ---------------------------------------------------------------------------
echo "=== Condition 5: Core Contract Gate ==="
if [[ -x scripts/audit/verify_core_contract_gate.sh ]]; then
    if scripts/audit/verify_core_contract_gate.sh > /dev/null 2>&1; then
        echo "✅ PASS: Core Contract Gate passes with zero violations"
    else
        echo "❌ FAIL: Core Contract Gate has violations"
        GATE_PASS=false
        FAILED_CONDITIONS+=("Core Contract Gate: violations detected")
    fi
else
    echo "❌ FAIL: Core Contract Gate script not found or not executable"
    GATE_PASS=false
    FAILED_CONDITIONS+=("Core Contract Gate: script missing")
fi
echo ""

# ---------------------------------------------------------------------------
# Condition 6: Phase 0 Closeout (SCH-009)
# ---------------------------------------------------------------------------
echo "=== Condition 6: Phase 0 Closeout (SCH-009) ==="
check_evidence "SCH-009 phase0_closeout" "evidence/phase0/gf_sch_009.json" || true
echo ""

# ---------------------------------------------------------------------------
# Condition 7: Formal Phase 2 Opening Approval
# ---------------------------------------------------------------------------
echo "=== Condition 7: Formal Phase 2 Opening Approval ==="
APPROVAL_FOUND=false
if ls approvals/*/PHASE2-GF-OPENING.md 1>/dev/null 2>&1; then
    APPROVAL_FOUND=true
    echo "✅ PASS: Phase 2 opening approval artifact found"
else
    echo "❌ FAIL: Phase 2 opening approval artifact not found (expected approvals/YYYY-MM-DD/PHASE2-GF-OPENING.md)"
    GATE_PASS=false
    FAILED_CONDITIONS+=("Phase 2 Opening Approval: artifact missing")
fi
echo ""

# ---------------------------------------------------------------------------
# Supplementary: Deferred items document must exist
# ---------------------------------------------------------------------------
echo "=== Supplementary: Deferred Items Register ==="
if [[ -f docs/operations/GF_PHASE2_DEFERRED_ITEMS.md ]]; then
    echo "✅ PASS: GF_PHASE2_DEFERRED_ITEMS.md exists"
else
    echo "❌ FAIL: GF_PHASE2_DEFERRED_ITEMS.md not found"
    GATE_PASS=false
    FAILED_CONDITIONS+=("Deferred Items Register: document missing")
fi
echo ""

# ---------------------------------------------------------------------------
# Final verdict
# ---------------------------------------------------------------------------
echo "============================================================"
if [[ "$GATE_PASS" == "true" ]]; then
    echo "✅ Phase 2 Entry Gate: ALL CONDITIONS MET"
    echo "Phase 2 green finance work may proceed."
    echo "============================================================"
    exit 0
else
    echo "❌ Phase 2 Entry Gate: BLOCKED"
    echo ""
    echo "Failing conditions:"
    for cond in "${FAILED_CONDITIONS[@]}"; do
        echo "  - $cond"
    done
    echo ""
    echo "No Phase 2 green finance work may begin until all conditions pass."
    echo "============================================================"
    exit 1
fi
