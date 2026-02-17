from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class RemediationTracePolicy:
    # Option 2: only production-affecting surfaces trigger the requirement.
    trigger_prefixes: tuple[str, ...] = (
        "schema/",
        "scripts/",
        ".github/workflows/",
        "src/",
        "packages/",
        "infra/",
        "docs/PHASE0/",
        "docs/invariants/",
        "docs/control_planes/",
    )
    remediation_required_markers: tuple[str, ...] = (
        "failure_signature",
        "repro_command",
        "verification_commands_run",
        "final_status",
    )

    origin_markers_any_of: tuple[str, ...] = (
        "origin_task_id",
        "origin_gate_id",
    )

    # Keep docs/security noise low: only treat obvious policy-like docs as triggering.
    docs_security_policy_tokens: tuple[str, ...] = (
        "policy",
        "retention",
        "key_management",
        "sdlc",
        "standard",
        "iso",
        "zero_trust",
    )

    remediation_casefile_re: re.Pattern[str] = re.compile(r"^docs/plans/.+/REM-[^/]+/(PLAN\.md|EXEC_LOG\.md)$")
    fix_task_plan_re: re.Pattern[str] = re.compile(r"^docs/plans/.+/TSK-[^/]+/(PLAN\.md|EXEC_LOG\.md)$")

    def is_trigger_file(self, path: str) -> bool:
        if path.startswith(self.trigger_prefixes):
            return True
        if path.startswith("docs/security/"):
            low = path.lower()
            return any(tok in low for tok in self.docs_security_policy_tokens)
        return False

    def remediation_docs_in_diff(self, changed_files: list[str]) -> list[str]:
        out: list[str] = []
        for p in changed_files:
            if self.remediation_casefile_re.match(p) or self.fix_task_plan_re.match(p):
                out.append(p)
        return out

    def missing_markers(self, text: str) -> list[str]:
        low = text.lower()
        missing = [m for m in self.remediation_required_markers if m not in low]
        if not any(m in low for m in self.origin_markers_any_of):
            missing.append("origin_task_id|origin_gate_id")
        return missing


def read_text_best_effort(root: Path, rel: str) -> str:
    p = root / rel
    return p.read_text(encoding="utf-8", errors="ignore")
