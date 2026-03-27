# RLS Anti-Hallucination Canonical Execution Order

This document defines the dependency-safe execution order for the anti-hallucination remediation chain and the outstanding downstream work that remains blocked on that chain.

## Agent pickup rule

This document is the repository handoff artifact for this remediation line.
An agent starting from repository state alone must use this file to determine:
- the next task that is eligible to start
- which tasks are not yet eligible to start
- what completion state must exist before the next task may begin

Unless this file is superseded by a later canonical repo artifact, do not infer a different order from chat history.

## Purpose

This is the canonical ordered execution view for the RLS anti-hallucination remediation line.
It exists to distinguish:
- the failure point where hallucination became possible
- the minimum corrective sequence
- the Wave 2 anti-drift enforcement sequence
- the downstream implementation work that should not begin before this chain is complete

## Reference failure point

The hallucination failure point is the state before `TSK-P1-222`.
At that point the repo had task packs that were schema-valid, but did not yet enforce:
- task contract truthfulness
- canonical runner authority
- proof integrity
- YAML-to-doc parity
- a real stop mechanism when proof was impossible

That state allowed scope invention, assumed completion, and fabricated proof.

## Canonical ordered execution chain

The following order is canonical because it is the minimum dependency-safe sequence from the failure point to an authoritative anti-hallucination baseline.

### Phase 1 — Minimum anti-hallucination spine

1. `TSK-P1-222` — Task contract repair
2. `TSK-P1-223` — Task loader primitive
3. `TSK-P1-224` — Runner skeleton and shared gate contract
4. `TSK-P1-225` — Contract gate (report-only)
5. `TSK-P1-226` — Proof-blocker hard stop

### Phase 2A — Authoring contract layer

6. `TSK-P1-227` — Global template hardening
7. `TSK-P1-228` — Task creation process hardening
8. `TSK-P1-229` — YAML-to-doc parity verifier

### Phase 2B — Structural and proof enforcement

9. `TSK-P1-230` — Authoring gate with escalation model
10. `TSK-P1-231` — Scope ceiling and objective-work-touches alignment gate
11. `TSK-P1-232` — Proof-integrity gate

### Phase 2C — Execution authority layer

12. `TSK-P1-233` — Dependency truth validator
13. `TSK-P1-234` — Canonical `verify-task` entrypoint
14. `TSK-P1-235` — Non-canonical verification execution detection

## Pickup queue for `TSK-P1-222` through `TSK-P1-235`

Use this queue when selecting the next implementation task.
Only the first not-yet-completed task whose prerequisites are satisfied is eligible to start.

| Order | Task ID | Start only when | Unblocks |
| --- | --- | --- | --- |
| 1 | `TSK-P1-222` | nothing earlier in this chain exists | `TSK-P1-223`, `TSK-P1-224`, `TSK-P1-225`, `TSK-P1-226` |
| 2 | `TSK-P1-223` | `TSK-P1-222` is completed | `TSK-P1-224`, `TSK-P1-225`, `TSK-P1-226` |
| 3 | `TSK-P1-224` | `TSK-P1-222` and `TSK-P1-223` are completed | `TSK-P1-225`, `TSK-P1-229`, `TSK-P1-230`, `TSK-P1-231`, `TSK-P1-232`, `TSK-P1-234` |
| 4 | `TSK-P1-225` | `TSK-P1-222`, `TSK-P1-223`, and `TSK-P1-224` are completed | `TSK-P1-226`, `TSK-P1-232` |
| 5 | `TSK-P1-226` | `TSK-P1-222`, `TSK-P1-223`, and `TSK-P1-224` are completed | later waves may proceed without proof-impossible improvisation |
| 6 | `TSK-P1-227` | `TSK-P1-226` is completed | `TSK-P1-228` |
| 7 | `TSK-P1-228` | `TSK-P1-227` is completed | `TSK-P1-229`, `TSK-P1-230` |
| 8 | `TSK-P1-229` | `TSK-P1-227`, `TSK-P1-228`, and `TSK-P1-224` are completed | `TSK-P1-230`, `TSK-P1-231`, `TSK-P1-232` |
| 9 | `TSK-P1-230` | `TSK-P1-227`, `TSK-P1-228`, `TSK-P1-229`, and `TSK-P1-224` are completed | `TSK-P1-231`, `TSK-P1-232` |
| 10 | `TSK-P1-231` | `TSK-P1-227`, `TSK-P1-229`, `TSK-P1-230`, and `TSK-P1-224` are completed | `TSK-P1-232` |
| 11 | `TSK-P1-232` | `TSK-P1-224`, `TSK-P1-225`, `TSK-P1-227`, `TSK-P1-230`, and `TSK-P1-231` are completed | `TSK-P1-233` |
| 12 | `TSK-P1-233` | `TSK-P1-232` is completed | downstream tasks can stop relying on socially assumed dependencies |
| 13 | `TSK-P1-234` | `TSK-P1-233` is completed | `TSK-P1-235` |
| 14 | `TSK-P1-235` | `TSK-P1-234` is completed | execution bypass becomes non-authoritative |

## How to pick the next task

Apply this decision rule in order:
- check completion state for `TSK-P1-222` through `TSK-P1-235`
- find the earliest task in the pickup queue that is not completed
- confirm every prerequisite in the `Start only when` column is satisfied
- if the prerequisites are not satisfied, work the missing prerequisite instead
- do not skip forward because a later task looks easier or more urgent

If repository state is ambiguous, stop and repair the missing execution evidence before starting a later task.

## Why this order is canonical

- `TSK-P1-222` must run first so later work does not inherit a false parent contract.
- `TSK-P1-223` must precede later gates so task metadata ingestion is deterministic.
- `TSK-P1-224` must precede later gates so there is one execution path and one shared result contract.
- `TSK-P1-225` must precede deeper enforcement so invalid task packs fail early.
- `TSK-P1-226` must precede later waves so proof-impossible paths stop instead of improvising.
- `TSK-P1-227` and `TSK-P1-228` must precede parity and authoring gates so the authoring contract exists before it is enforced.
- `TSK-P1-229` must precede Pack B enforcement so parity drift is visible before stronger conclusions are drawn.
- `TSK-P1-230` must precede `TSK-P1-231` and `TSK-P1-232` so structurally invalid task packs do not feed scope or proof checks.
- `TSK-P1-231` must precede `TSK-P1-232` so proof-integrity review does not operate on fake-narrowness task packs.
- `TSK-P1-234` must precede `TSK-P1-235` so bypass detection is anchored to a defined canonical execution path.

## State reached after the chain completes

After `TSK-P1-235`, the system has:
- truthful task-pack foundations
- deterministic task loading
- one runner contract
- one proof-blocking stop condition
- hardened authoring requirements
- parity visibility
- structural completeness enforcement
- scope/alignment enforcement
- proof-integrity enforcement
- dependency truth visibility
- one sanctioned verification entrypoint
- non-canonical execution classification

This is the first point at which the task-verification layer becomes authoritative rather than merely well-described.

## Ordered downstream backlog after `TSK-P1-235`

The items below remain outstanding implementation work that depends on the anti-hallucination chain being in place and stable.
They are ordered for future pickup from nearest follow-on to latest deferred hardening.

### Immediate follow-on anti-drift tasks already planned but not yet task-packed

1. `TSK-P1-236` — Enforce mandatory artifact emission for verification runs
2. `TSK-P1-237` — Enforce completion completeness before status closure

### Additional anti-drift controls explicitly retained in the Wave 2 plan

3. Promotion readiness validator
4. Local non-authoritative mirror path
5. Full fail-class ergonomics completion
6. CI downgrade protection / `B7`
7. Evidence freshness / provenance / lineage
8. Cross-task drift tracker
9. Derived-status truth
10. Verifier/runtime/toolchain closure
11. DB consistency / TOCTOU hardening

### Remaining RLS remediation implementation work from the remainder plan

12. Report-only test-validity gate
13. Report-only execution ergonomics enforcement
14. Restore honest DB-backed verification path
15. Report-only Phase 0 input/config gate
16. Canonical verifier/runner unification for `TSK-RLS-ARCH-001`
17. Formal test hardening for the RLS runtime suite
18. Documentation truthfulness repair
19. Basic canonical evidence emission
20. Local non-authoritative mirror path for operators
21. Promote `B1` to blocking
22. Promote `B2` to blocking
23. Promote `B4` to blocking
24. Promote `B5` to blocking
25. Promote `B8` to blocking
26. Promote `B7` to blocking
27. Normalization engine
28. Trust-model verifier
29. Evidence lineage hardening
30. CI attestation
31. Verifier/runtime closure hardening
32. DB consistency and TOCTOU hardening
33. Derived-status authoritative model

## Downstream pickup staging

After `TSK-P1-235`, use this staging order for future planning and task-pack creation:

### Stage D1 — Immediate anti-drift closure

- `TSK-P1-236`
- `TSK-P1-237`

These should be created and executed before broader closure claims because they convert verification output and completion semantics from socially inferred state into durable contract state.

### Stage D2 — Baseline stabilization controls

- Promotion readiness validator
- Full fail-class ergonomics completion
- Evidence freshness / provenance / lineage
- Derived-status truth
- Verifier/runtime/toolchain closure

These stabilize the anti-drift baseline before blocking promotion or deep end-state claims.

### Stage D3 — Remaining report-only RLS platform work

- Report-only test-validity gate
- Report-only execution ergonomics enforcement
- Restore honest DB-backed verification path
- Report-only Phase 0 input/config gate
- Canonical verifier/runner unification for `TSK-RLS-ARCH-001`
- Formal test hardening for the RLS runtime suite
- Documentation truthfulness repair
- Basic canonical evidence emission

These remain downstream because they rely on the anti-hallucination and execution-authority baseline being truthful first.

### Stage D4 — Activation and authority promotion

- Local non-authoritative mirror path (covers both operator and development use)
- Promote `B1` to blocking
- Promote `B2` to blocking
- Promote `B4` to blocking
- Promote `B5` to blocking
- Promote `B7` to blocking
- Promote `B8` to blocking

These only begin after the report-only baseline is stable and false-positive behavior has been reviewed.

### Stage D5 — Late hardening

- CI downgrade protection
- Cross-task drift tracker
- Normalization engine
- Trust-model verifier
- Evidence lineage hardening
- CI attestation
- Verifier/runtime closure hardening
- DB consistency and TOCTOU hardening
- Derived-status authoritative model

These are intentionally later because they secure and deepen a system that must already be functioning truthfully.

## Dependency interpretation for downstream work

The downstream items above depend on this chain in one of three ways:
- they require the anti-hallucination spine to exist before truthful implementation can begin
- they require the anti-drift enforcement layer to exist before stronger closure claims can be made
- they require the execution-authority layer to exist before canonical outputs can be treated as authoritative

## Execution rule

Do not begin downstream work from this document out of order.
In particular:
- do not run scope or proof enforcement before template, process, and parity foundations exist
- do not run proof-integrity checks before authoring enforcement exists
- do not classify bypass execution before canonical execution is defined
- do not promote report-only controls to blocking until the report-only chain is implemented and stable

## Ready-now interpretation

For any future agent:
- if none of `TSK-P1-222` through `TSK-P1-235` are implemented, start with `TSK-P1-222`
- if some are implemented, resume from the earliest incomplete item in the pickup queue
- do not start `TSK-P1-236` or later work until `TSK-P1-235` is completed and verified

## Canonical short form

```text
FAILURE POINT
→ TSK-P1-222
→ TSK-P1-223
→ TSK-P1-224
→ TSK-P1-225
→ TSK-P1-226
→ TSK-P1-227
→ TSK-P1-228
→ TSK-P1-229
→ TSK-P1-230
→ TSK-P1-231
→ TSK-P1-232
→ TSK-P1-233
→ TSK-P1-234
→ TSK-P1-235
```

## Sources

- `tasks/TSK-P1-222/meta.yml`
- `tasks/TSK-P1-223/meta.yml`
- `tasks/TSK-P1-224/meta.yml`
- `tasks/TSK-P1-225/meta.yml`
- `tasks/TSK-P1-226/meta.yml`
- `tasks/TSK-P1-227/meta.yml`
- `tasks/TSK-P1-228/meta.yml`
- `tasks/TSK-P1-229/meta.yml`
- `tasks/TSK-P1-230/meta.yml`
- `tasks/TSK-P1-231/meta.yml`
- `tasks/TSK-P1-232/meta.yml`
- `tasks/TSK-P1-233/meta.yml`
- `tasks/TSK-P1-234/meta.yml`
- `tasks/TSK-P1-235/meta.yml`
- `/home/mwiza/.windsurf/plans/rls-anti-drift-wave2-task-plan-b8c1dc.md`
- `/home/mwiza/.windsurf/plans/rls-remediation-remainder-plan-b8c1dc.md`
- `/home/mwiza/.windsurf/plans/rls-remediation-final-plan-b8c1dc.md`
