# PLAN — TASK-GOV-AWC6

## Mission

Inventory current evidence-vs-`touches` inconsistencies and define explicit
cleanup batches by task family.

## Scope

Audit output only. No backfill edits to existing legacy task packs.

## Verification Commands

```bash
rg -n "TASK-GOV-AWC1|TASK-GOV-AWC2|TASK-GOV|TASK-INVPROC|TASK-OI|TSK-P1|TSK-HARD|PERF-|R-" docs/operations/EVIDENCE_TOUCHES_AUDIT.md
python3 - <<'PY'
from pathlib import Path
import yaml
rows=[]
for meta in sorted(Path('tasks').glob('*/meta.yml')):
    d=yaml.safe_load(meta.read_text()) or {}
    evid=d.get('evidence') or []
    touches=d.get('touches') or []
    miss=[]
    for ev in evid:
        if not isinstance(ev,str):
            continue
        covered=False
        for t in touches:
            if not isinstance(t,str):
                continue
            if t==ev or t=='evidence/phase1/**' or t=='evidence/**' or (t.endswith('/**') and ev.startswith(t[:-2])):
                covered=True
                break
        if not covered:
            miss.append(ev)
    if miss:
        rows.append((d.get('task_id'), miss))
print(len(rows))
assert any(tid=='TASK-GOV-AWC1' for tid,_ in rows)
assert any(tid=='TASK-GOV-AWC2' for tid,_ in rows)
print('PASS')
PY
```

## Evidence

- `evidence/phase1/task_gov_awc6_evidence_touches_audit.json`

## Remediation Markers

```text
failure_signature: GOV.AWC6.EVIDENCE_TOUCHES_AUDIT
origin_task_id: TASK-GOV-AWC6
repro_command: rg -n "TASK-GOV-AWC1|TASK-GOV-AWC2" docs/operations/EVIDENCE_TOUCHES_AUDIT.md
verification_commands_run: see Verification Commands
final_status: PASS
```
