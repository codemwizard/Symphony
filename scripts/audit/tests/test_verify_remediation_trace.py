import json
from pathlib import Path

from scripts.audit.remediation_trace_lib import RemediationTracePolicy


def test_policy_trigger_files_schema_and_scripts() -> None:
    p = RemediationTracePolicy()
    assert p.is_trigger_file("schema/migrations/0001_init.sql")
    assert p.is_trigger_file("scripts/audit/run_invariants_fast_checks.sh")
    assert p.is_trigger_file(".github/workflows/invariants.yml")
    assert p.is_trigger_file("docs/invariants/INVARIANTS_MANIFEST.yml")


def test_policy_docs_security_is_low_noise() -> None:
    p = RemediationTracePolicy()
    assert p.is_trigger_file("docs/security/KEY_MANAGEMENT_POLICY.md")
    assert not p.is_trigger_file("docs/security/notes.md")


def test_remediation_docs_matchers() -> None:
    p = RemediationTracePolicy()
    changed = [
        "src/app.cs",
        "docs/plans/phase0/REM-2026-02-07_ci_gate/PLAN.md",
        "docs/plans/phase0/TSK-P0-105_remediation_trace_gate/EXEC_LOG.md",
        "docs/random.md",
    ]
    docs = p.remediation_docs_in_diff(changed)
    assert "docs/plans/phase0/REM-2026-02-07_ci_gate/PLAN.md" in docs
    assert "docs/plans/phase0/TSK-P0-105_remediation_trace_gate/EXEC_LOG.md" in docs


def test_missing_markers_detection() -> None:
    p = RemediationTracePolicy()
    txt = "failure_signature: X\norigin_task_id: Y\nrepro_command: Z\nverification_commands_run: A\nfinal_status: PASS\n"
    assert p.missing_markers(txt) == []
    missing = p.missing_markers("failure_signature: X\n")
    assert "final_status" in missing
    assert "origin_task_id|origin_gate_id" in missing


def test_verify_script_expected_evidence_schema_fields_exist() -> None:
    # This is a cheap guard: if the verifier runs, it must always write JSON with required keys.
    # We validate the repo file shape, not execution, to keep tests deterministic.
    script = Path("scripts/audit/verify_remediation_trace.sh").read_text(encoding="utf-8")
    assert "remediation_trace.json" in script
    assert "\"check_id\"" in script or "check_id" in script
    assert "\"status\"" in script or "status" in script
