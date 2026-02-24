#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

checkpoint=""
evidence=""
dag_path="$ROOT_DIR/docs/tasks/phase1_dag.yml"
prompt_pack="$ROOT_DIR/docs/tasks/phase1_prompts.md"

usage() {
  cat <<'USAGE' >&2
Usage:
  scripts/audit/verify_checkpoint.sh --checkpoint <checkpoint/id> --evidence <evidence.json>

Behavior:
  - Reads docs/tasks/phase1_dag.yml to find checkpoint depends_on.
  - For each dependency, finds its evidence_path from docs/tasks/phase1_prompts.md execution metadata blocks.
  - Validates each dependency evidence via scripts/audit/validate_evidence.py.
  - Emits checkpoint evidence JSON with task_id == <checkpoint/id> and status PASS/FAIL.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --checkpoint) checkpoint="${2:-}"; shift 2 ;;
    --evidence) evidence="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

if [[ -z "$checkpoint" ]]; then
  echo "Missing --checkpoint" >&2
  usage
  exit 2
fi
if [[ -z "$evidence" ]]; then
  echo "Missing --evidence" >&2
  usage
  exit 2
fi

mkdir -p "$(dirname "$ROOT_DIR/$evidence")"

CHECKPOINT="$checkpoint" DAG_PATH="$dag_path" PROMPT_PACK="$prompt_pack" ROOT_DIR="$ROOT_DIR" EVIDENCE_OUT="$ROOT_DIR/$evidence" \
python3 - <<'PY'
import json
import os
import re
import subprocess
from pathlib import Path
from datetime import datetime, timezone

root = Path(os.environ["ROOT_DIR"])
checkpoint = os.environ["CHECKPOINT"]
dag_path = Path(os.environ["DAG_PATH"])
prompt_pack = Path(os.environ["PROMPT_PACK"])
evidence_out = Path(os.environ["EVIDENCE_OUT"])

errors: list[str] = []
details: dict = {
    "checkpoint": checkpoint,
    "dependencies": [],
    "dependency_evidence": {},
}

def git_sha() -> str:
    try:
        return subprocess.check_output(["git", "-C", str(root), "rev-parse", "HEAD"], text=True).strip()
    except Exception:
        return "UNKNOWN"

def now_utc() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")

def parse_dag_deps(dag_text: str, node_id: str) -> list[str]:
    deps: list[str] = []
    in_node = False
    in_deps = False
    for line in dag_text.splitlines():
        if line.startswith("- id: "):
            in_node = (line.split(":", 1)[1].strip() == node_id)
            in_deps = False
            continue
        if not in_node:
            continue
        if re.match(r"^\s+depends_on:\s*$", line):
            in_deps = True
            continue
        if in_deps:
            m = re.match(r"^\s+-\s+(.+)$", line)
            if m:
                deps.append(m.group(1).strip())
                continue
            # end of depends_on block
            if re.match(r"^\s+\w+:", line) or line.startswith("- id: "):
                in_deps = False
    return deps

def parse_prompt_evidence_map(prompt_text: str) -> dict[str, str]:
    # Extract (task_id -> evidence_path) from ```yaml execution metadata blocks.
    mapping: dict[str, str] = {}
    in_yaml = False
    buf: list[str] = []
    for line in prompt_text.splitlines():
        if not in_yaml and line.strip() == "```yaml":
            in_yaml = True
            buf = []
            continue
        if in_yaml and line.strip() == "```":
            in_yaml = False
            task_id = ""
            evidence_path = ""
            for b in buf:
                if b.lstrip().startswith("task_id:"):
                    task_id = b.split(":", 1)[1].strip().strip('"').strip("'")
                if b.lstrip().startswith("evidence_path:"):
                    evidence_path = b.split(":", 1)[1].strip().strip('"').strip("'")
            if task_id and evidence_path:
                mapping[task_id] = evidence_path
            continue
        if in_yaml:
            buf.append(line)
    return mapping

dag_text = dag_path.read_text(encoding="utf-8", errors="ignore")
prompt_text = prompt_pack.read_text(encoding="utf-8", errors="ignore")

deps = parse_dag_deps(dag_text, checkpoint)
details["dependencies"] = deps

evidence_map = parse_prompt_evidence_map(prompt_text)

for dep in deps:
    dep_evidence = evidence_map.get(dep, "")
    if not dep_evidence:
        errors.append(f"missing_dependency_evidence_path_in_prompt_pack:{dep}")
        continue
    details["dependency_evidence"][dep] = dep_evidence
    # Validate using repo validator (fail-closed).
    try:
        subprocess.check_call(
            ["python3", str(root / "scripts/audit/validate_evidence.py"), "--task", dep, "--evidence", str(root / dep_evidence)]
        )
    except subprocess.CalledProcessError as e:
        errors.append(f"dependency_evidence_invalid_or_not_pass:{dep}:{dep_evidence}:exit={e.returncode}")

payload = {
    "check_id": "CHECKPOINT-VERIFY",
    "task_id": checkpoint,
    "timestamp_utc": now_utc(),
    "git_sha": git_sha(),
    "status": "PASS" if not errors else "FAIL",
    "pass": True if not errors else False,
    "details": details,
    "errors": errors,
}

evidence_out.parent.mkdir(parents=True, exist_ok=True)
evidence_out.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")

if errors:
    for err in errors:
        print(f"ERROR: {err}")
    raise SystemExit(1)

print(f"checkpoint_ok:{checkpoint}:{evidence_out}")
PY

python3 "$ROOT_DIR/scripts/audit/validate_evidence.py" --task "$checkpoint" --evidence "$ROOT_DIR/$evidence"
