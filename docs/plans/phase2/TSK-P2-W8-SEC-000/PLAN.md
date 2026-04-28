# TSK-P2-W8-SEC-000 PLAN - Frozen .NET 10 Ed25519 Environment Fidelity Gate

Task: TSK-P2-W8-SEC-000
Owner: SECURITY_GUARDIAN
failure_signature: P2.W8.TSK_P2_W8_SEC_000.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Prove Wave 8 evidence is generated on the declared production-parity `.NET 10`
runtime path and that the declared first-party Ed25519 surface is the one
actually executing.

## Control Position

- Authoritative Wave 8 boundary: `asset_batches`
- Primary enforcement domain: `runtime/provider/evidence honesty`
- `.NET 10` first-party Ed25519 is accepted as part of the framework contract.
- This task does not question framework availability in the abstract.
- This task proves only digest fidelity, runtime fidelity, surface fidelity,
  and semantic fidelity for the declared proof-cycle environment.

## Scope

`SEC-000` proves:
- the frozen SDK digest was used
- the frozen runtime digest was used
- the runtime is the declared `.NET 10` family
- the runtime follows the declared Linux/OpenSSL path
- the executing code resolves and invokes the declared first-party Ed25519 surface
- sign/verify semantics work for Wave 8-shaped contract bytes
- provider drift or runtime drift fails the gate

`SEC-000` does not:
- prove Ed25519 exists as a framework feature in the abstract
- choose the algorithm
- choose the provider family
- compare crypto libraries
- validate PostgreSQL enforcement
- validate scope, replay, timestamp, or context rules
- satisfy authoritative boundary enforcement

## Method

- Use a tracked probe program under source control.
- Build the probe inside the pinned SDK image.
- Execute the probe inside the pinned ASP.NET runtime image.
- Emit evidence with the exact environment tuple and execution trace.

Forbidden:
- inline C# in bash
- host-local execution
- verifier-only shims
- a runtime image that differs from production parity

## Explicit bans

- Reflection-only surface proof is inadmissible.
- Toy-crypto proof is inadmissible.

## Work Items

### Step 1
**What:** [ID w8_sec_000_work_01] Prove the probe builds inside the pinned SDK image and executes inside the pinned ASP.NET runtime image with the exact expected digests.
**Done when:** [ID w8_sec_000_work_01] Evidence records expected and observed SDK/runtime digests and fails if the probe runs outside the pinned images.

### Step 2
**What:** [ID w8_sec_000_work_02] Prove the executing runtime reports the declared `.NET 10` family and Linux/OpenSSL path for the Wave 8 proof cycle.
**Done when:** [ID w8_sec_000_work_02] Evidence records runtime-family and OpenSSL-path details for the declared proof-cycle environment.

### Step 3
**What:** [ID w8_sec_000_work_03] Prove the declared first-party Ed25519 surface is actually invoked through the production-parity runtime path and not satisfied by reflection-only or wrapper-only evidence.
**Done when:** [ID w8_sec_000_work_03] Surface fidelity is proven by actual invocation through the first-party execution path; reflection-only surface proof is inadmissible.

### Step 4
**What:** [ID w8_sec_000_work_04] Prove sign/verify behavior on Wave 8-shaped contract bytes, including altered-byte, wrong-key, malformed-signature, and runtime/provider-drift failure cases.
**Done when:** [ID w8_sec_000_work_04] Semantic fidelity is proven on Wave 8-shaped contract bytes and toy-crypto proof is inadmissible.

## Verification

```bash
bash scripts/security/verify_tsk_p2_w8_sec_000.sh > evidence/phase2/tsk_p2_w8_sec_000.json
python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase2/TSK-P2-W8-SEC-000/PLAN.md --meta tasks/TSK-P2-W8-SEC-000/meta.yml
```
