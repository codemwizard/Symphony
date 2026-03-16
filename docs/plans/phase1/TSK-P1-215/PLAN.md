# TSK-P1-215 Plan

Task ID: TSK-P1-215

## dependencies
- TSK-P1-212
- TSK-P1-INF-005 (OpenBao and ESO manifests)
- TSK-P1-INF-006 (Signing key management)

## objective
Integrate runtime secret resolution with OpenBao so hardened deployments stop trusting process env as the security source of truth.

## implementation_boundaries
- Do not recreate or replace previously landed OpenBao/ESO manifests unless a defect is found.
- Consume the existing OpenBao foundation and finish runtime app integration.
- Replace env-based secret trust for the in-scope keys.
- Do not introduce a fallback that keeps env as an acceptable hardened path.
- In-scope keys (reuse is explicitly banned):
  - `INGRESS_API_KEY`
  - `ADMIN_API_KEY`
  - `DEMO_INSTRUCTION_SIGNING_KEY`
  - `EVIDENCE_SIGNING_KEY`
  - operator session/cookie signing material

## hardening_rules
1. No interim workaround may remain in the supported deployment or onboarding path after this task closes.
2. Hardened GreenTech4CE flows must prefer durable system design over operator memory, shell sequencing, or manual reseeding.
3. Runtime security decisions must not depend on browser-held admin credentials or unaudited environment-variable shortcuts when this task is in scope to remove them.
4. Documentation, gates, and runtime behavior must converge on one supported hardened path; fallback modes may exist only when explicitly marked as developer-only and out of scope.

## acceptance_focus
- Remove the provisional workaround described in task notes, if any.
- Update docs, verifiers, and bootstrap expectations so the permanent design is the only supported design.
- Prove the final state with evidence and fail-closed verification.

## remediation_trace
failure_signature: PHASE1.P1.215.RUNTIME_SECRET_PROVIDER
repro_command: see task verifier commands in meta.yml
verification_commands_run: []
final_status: planned
origin_task_id: TSK-P1-215
origin_gate_id: PHASE1.P1.215.RUNTIME_SECRET_PROVIDER
