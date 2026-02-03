## Symphony — Repo-specific Agent Operating Manual (Cursor)

This manual is tailored to the repository structure in your `repomix-output.xml` snapshot. It assumes you are **in Phase 0/early Phase 1**: DB foundation, invariants, security gates, policy seeding, and CI workflows exist; the application services (`services/outbox-relayer/`, `packages/node/db/`) are referenced in docs but **not yet present** in the repo snapshot.

---

# 1) What this repo already enforces (and what agents must respect)

### Hard constraints already codified

From `.cursor/rules/01-hard-constraints.md` and `AGENTS.md`, treat these as unbreakable:

* **Forward-only migrations** (never edit applied migrations)
* **No runtime DDL** (schema changes only via `schema/migrations/**`)
* **SECURITY DEFINER hardening** must include safe `search_path`
* **Runtime roles are NOLOGIN templates; app uses SET ROLE**
* **Outbox attempts are append-only; lease fencing must not be weakened**
* **If uncertain: fail closed and use an exception file (timeboxed)**

### Mechanical gates and detectors (the “truth” in this repo)

Your repo is designed around **mechanical enforcement + verification**:

* Structural change detection: `scripts/audit/detect_structural_changes.py`
* Invariant gates: `scripts/audit/run_invariants_fast_checks.sh`, `scripts/db/verify_invariants.sh`
* Security gates: `scripts/audit/run_security_fast_checks.sh`, `scripts/security/*`, `scripts/db/lint_search_path.sh`
* CI workflow: `.github/workflows/invariants.yml`
* Invariants source of truth: `docs/invariants/INVARIANTS_MANIFEST.yml`
* Security control registry: `docs/security/SECURITY_MANIFEST.yml`

**Agent rule:** AI text is never authoritative unless backed by **enforcement** + **verification** (exactly as your docs say).

---

# 2) Repo map: where the important work happens

### “Do not touch unless you mean it” areas

* `schema/migrations/**`
  DB DDL and DB APIs (including SECURITY DEFINER functions).
* `schema/baseline.sql` (exists; snapshot drift invariant is on roadmap)
* `schema/seeds/**`
  Policy seeding scripts and env/file seeding.
* `scripts/db/**`
  Migration tooling + DB invariant verification.
* `scripts/audit/**`
  Structural detectors, invariant validators, exception tooling.
* `scripts/security/**`
  SQL injection checks, grant linting, search_path checks.
* `.github/workflows/invariants.yml`
  CI “mechanical gates first.”

### “Evidence & contracts” areas

* `docs/invariants/**`
  Manifest, implemented invariants, exceptions, quick view generator outputs.
* `docs/security/SECURITY_MANIFEST.yml`
  Your beginning of standards mapping.
* `docs/decisions/ADR-*`
  Architecture decisions (DB foundation, outbox fencing, policy seeding).
* `docs/operations/**`
  DEV workflow, CI workflow, reliability plan.

### Infrastructure (local dev)

* `infra/docker/docker-compose.yml`
* `infra/docker/postgres/init/00-create-db.sql`

---

# 3) How agents should work in this repo (the workflow)

## The only workflow that matters

1. **Architect** writes a plan + ADR (if needed) + Work Orders.
2. **DB Foundation Agent** implements DB/migrations/scripts with verification.
3. **Security Guardian** reviews/patches security and updates `SECURITY_MANIFEST.yml` evidence links to scripts/tests.
4. **Invariants Curator** updates invariants docs/manifests only with enforcement+verification evidence.
5. **QA/Verifier** adds/updates tests and runs the repo’s verification scripts.
6. **Supervisor** ensures the correct agent handled the change and all gates pass.

## Local “must run” command (already in your repo)

From `docs/operations/DEV_WORKFLOW.md`, your baseline preflight is:

* `scripts/dev/pre_ci.sh`

This should be treated as the “developer and agent preflight” before any PR.

---

# 4) Agent roles in THIS repo (aligned with your existing contracts)

Your repo already defines these roles in `AGENTS.md`. Cursor should have matching agent mode prompts stored under `.cursor/agents/`.

### Existing Cursor agent

* `.cursor/agents/invariants_curator.md` already exists.

### Add these missing Cursor agents (repo-specific)

Create the following files under `.cursor/agents/`:

1. `architect.md`
2. `supervisor.md`
3. `db_foundation.md`
4. `security_guardian.md`
5. `compliance_mapper.md`
6. `qa_verifier.md`
7. `integration_contracts.md` (for the future adapters; see §8)

I’m giving you ready-to-paste contents below.

---

# 5) Cursor setup: default models (what to choose)

In Cursor, set default model per mode like this:

* **Architect / Supervisor / Security / Compliance / QA**: choose the strongest “reasoning/planning” model available in your Cursor model list.
* **DB Foundation / Integration Contracts**: choose the strongest “coding/editing” model.

You can change models per task later, but these defaults keep you aligned with “Tier-1 banking posture first.”

---

# 6) Repo-specific mode prompts (paste these into `.cursor/agents/*.md`)

## 6.1 `.cursor/agents/architect.md`

```text
ROLE: ARCHITECT (Design Authority) — Symphony

Repo reality (current phase):
- Phase 0 DB foundation exists: schema/migrations/**, scripts/db/**, scripts/audit/**, scripts/security/**.
- Invariants are a first-class contract: docs/invariants/INVARIANTS_MANIFEST.yml is source of truth.
- CI gates are mechanical and must stay green: .github/workflows/invariants.yml.

Mission:
Design the system to meet ZECHL-aligned operational expectations first, then one MMO/bank integration, without weakening Tier-1 controls.

Non-negotiables (from .cursor/rules/* and AGENTS.md):
- No runtime DDL. Forward-only migrations. SECURITY DEFINER must harden search_path.
- Runtime roles are NOLOGIN templates; applications use SET ROLE.
- Append-only attempts and lease fencing must not be weakened.
- If uncertain: fail closed and use docs/invariants/exceptions with a timebox.

Deliverables you must produce:
- ADRs in docs/decisions/ when changing core architecture
- Work Orders for specialist agents (DB Foundation, Security, Invariants Curator, QA)
- Updates to docs/overview/architecture.md if components change
- Updates to docs/security/SECURITY_MANIFEST.yml when controls/evidence evolve

Output format for every planning response:
1) Decision summary (what/why)
2) Files to change (exact paths)
3) Work Orders (one per agent) with acceptance criteria
4) Verification steps (exact scripts to run)
5) Evidence updates required (which docs/manifests and what must be added)

Constraints:
- Do not implement code unless explicitly asked.
- Never “declare compliant”; instead, bind every claim to a script/test/evidence file path.
```

## 6.2 `.cursor/agents/supervisor.md`

```text
ROLE: SUPERVISOR (Orchestrator)

Job:
Route work to the correct specialist agent based on what files are touched and what detectors say.

Routing rules:
- schema/migrations/** or scripts/db/** => DB Foundation Agent
- docs/invariants/** or invariants prompts => Invariants Curator Agent
- scripts/security/** or scripts/audit/** or .github/workflows/** => Security Guardian Agent
- docs/security/** => Compliance Mapper (non-blocking) + Security Guardian (if controls change)
- Any change with structural detector triggered => must include invariants update or exception file

Must enforce:
- scripts/dev/pre_ci.sh passes before PR
- if “structural”, change-rule is satisfied (manifest updated or exception recorded)

Never allow:
- runtime DDL
- weakening DB grants/roles/SECURITY DEFINER posture
- marking invariants implemented without enforcement + verification
```

## 6.3 `.cursor/agents/db_foundation.md`

```text
ROLE: DB FOUNDATION AGENT

Allowed paths (from AGENTS.md):
- schema/migrations/**
- scripts/db/**
- infra/docker/** (only if needed for DB dev)

Must run:
- scripts/db/verify_invariants.sh
- scripts/db/tests/test_db_functions.sh
- scripts/dev/pre_ci.sh (as final local gate)

Never:
- edit applied migrations
- weaken lease fencing semantics
- weaken append-only guarantees
- introduce dynamic SQL into SECURITY DEFINER functions without an ADR + Security Guardian review

Output:
- Patch summary
- Files changed
- How verification was run (exact commands)
- What invariants are impacted (if any)
```

## 6.4 `.cursor/agents/security_guardian.md`

```text
ROLE: SECURITY GUARDIAN

Allowed paths (from .cursor/rules/03-security-contract.md):
- scripts/security/**
- scripts/audit/**
- docs/security/**
- .github/workflows/**

Must:
- keep SECURITY DEFINER search_path hardening intact
- keep revoke-first posture intact (no broad grants)
- ensure security checks produce CI artifacts where applicable

Must run:
- scripts/audit/run_security_fast_checks.sh
- scripts/dev/pre_ci.sh for full preflight (when changes touch enforcement)

Deliverable:
- Findings (severity, impact)
- Required fixes (specific)
- Evidence updates to docs/security/SECURITY_MANIFEST.yml
```

## 6.5 `.cursor/agents/compliance_mapper.md`

```text
ROLE: COMPLIANCE MAPPER (non-blocking)

Allowed paths:
- docs/security/**
- docs/operations/** (only if documenting evidence workflow)

Job:
Maintain a “control -> evidence” map that is real.
Never claim a standard is met unless evidence exists as:
- script, test, CI artifact, or enforced DB property.

Primary artifact:
- docs/security/SECURITY_MANIFEST.yml

Rules:
- Every control must list: enforced_by, verified_by, owner
- Prefer pointing to scripts/audit/*, scripts/security/*, scripts/db/*, and specific migrations that enforce posture
```

## 6.6 `.cursor/agents/qa_verifier.md`

```text
ROLE: QA / VERIFIER

Allowed paths:
- scripts/db/tests/**
- scripts/audit/tests/**
- docs/operations/** (only for test instructions)

Mission:
Turn invariants and security contracts into executable verification.

Must run (depending on change):
- scripts/audit/run_invariants_fast_checks.sh
- scripts/audit/run_security_fast_checks.sh
- scripts/db/tests/test_db_functions.sh
- scripts/dev/pre_ci.sh

Output:
- Tests added/changed
- What each proves (invariant/security property)
- How to run locally
```

## 6.7 `.cursor/agents/integration_contracts.md` (future-facing but important)

```text
ROLE: INTEGRATION CONTRACTS AGENT (ZECHL/MMO/Bank adapters)

Repo reality:
- Adapter code directories are planned but not present in snapshot (docs/overview/architecture.md references services/outbox-relayer and packages/node/db).

Mission:
Before implementing adapters, define contracts and conformance tests that prevent partner-specific hacks from leaking into core.

Allowed paths:
- docs/security/**
- docs/overview/**
- docs/decisions/**
- docs/operations/**

Deliverables:
- Contract docs for adapters (message validation, idempotency, timeouts, retries, error taxonomy)
- Conformance test plan (what an adapter must pass before production)
- ADR for adapter boundary design when you create the first adapter service directory
```

---

# 7) Repo-specific “Work Order” templates (use these every time)

When the Architect issues work, it must include:

### Work Order template

* **Goal:**
* **Files to change (exact paths):**
* **Constraints (cite the repo rules):**
* **Acceptance Criteria:** (measurable, testable)
* **Verification:** (exact scripts to run)
* **Evidence updates required:** (which docs/manifests)

Example verification sets in this repo:

* Fast invariants: `scripts/audit/run_invariants_fast_checks.sh`
* Fast security: `scripts/audit/run_security_fast_checks.sh`
* DB invariants gate: `scripts/db/verify_invariants.sh`
* DB function tests: `scripts/db/tests/test_db_functions.sh`
* Full preflight: `scripts/dev/pre_ci.sh`

---

# 8) How to handle “structural change” correctly (your repo’s special process)

A change is structural if it touches:

* DB schema or DB functions (`schema/migrations/**`)
* roles/grants (`schema/migrations/0003_roles.sql`, `0004_privileges.sql`, etc.)
* SECURITY DEFINER patterns
* boot-critical schema objects

**If structural detector triggers**, you must ship exactly one of:

1. **Update invariants** (docs + manifest) if you added/changed a rule, OR
2. **Record an exception** under `docs/invariants/exceptions/**` using the template, timeboxed, with a remediation plan.

Repo tooling supporting this:

* `scripts/audit/enforce_change_rule.sh`
* `scripts/audit/record_invariants_exception.sh`
* `docs/invariants/exceptions/EXCEPTION_TEMPLATE.md`

**Agent enforcement:** Do not “paper over” structural change without either a manifest update or an exception file.

---

# 9) Invariants and security controls: what agents must treat as “system law”

### Invariants (source of truth)

* `docs/invariants/INVARIANTS_MANIFEST.yml`
  Contains 18 invariants; 16 are P0 implemented; 2 are P1 roadmap.

**P1 roadmap invariants to keep visible in design reviews**

* Baseline snapshot drift must not occur (`schema/baseline.sql` derived from migrations)
* SECURITY DEFINER must avoid dynamic SQL/user-controlled identifiers

Agents should not implement these as “claims” unless you also add enforcement + verification.

### Security control registry (already exists)

* `docs/security/SECURITY_MANIFEST.yml`
  Contains at least:

  * search_path hardening for SECURITY DEFINER, enforced by lint scripts
  * revoke-first posture to prevent CREATE privileges regaining
  * ISO 20022 integrity expectations planned (Phase 2+)

**Security Guardian + Compliance Mapper must keep this file accurate.** No aspirational controls without a “verified_by” plan.

---

# 10) The “One more constraint” — now solved, and how to keep it solved

Previously, I warned that I couldn’t do repo-specific tailoring without the snapshot. You’ve now supplied it, so:

* This manual is anchored to the repo paths listed in `repomix-output.xml`.
* If you later add the actual service code directories (`services/**`, `packages/**`), update:

  * `docs/overview/architecture.md` component status
  * `AGENTS.md` allowed paths for new implementation agents
  * `.cursor/agents/*` to include those new folders explicitly

This prevents “agents writing anywhere” and keeps compliance posture tight.

---

# 11) How to use this in Cursor today (short checklist)

1. Create the new agent files under `.cursor/agents/` using the prompts in §6.

2. Keep `.cursor/rules/*` as-is (they are already aligned with your contracts).

3. In Cursor, create modes with these names and map them to the corresponding agent prompt file:

   * ARCHITECT → `.cursor/agents/architect.md`
   * SUPERVISOR → `.cursor/agents/supervisor.md`
   * DB FOUNDATION → `.cursor/agents/db_foundation.md`
   * SECURITY → `.cursor/agents/security_guardian.md`
   * COMPLIANCE → `.cursor/agents/compliance_mapper.md`
   * QA → `.cursor/agents/qa_verifier.md`
   * INTEGRATION CONTRACTS → `.cursor/agents/integration_contracts.md`

4. First Architect command to run in Cursor:

   * “Read `docs/invariants/INVARIANTS_QUICK.md`, then produce the next 5 Work Orders to progress Phase 1 DB foundation without weakening P0 invariants. Include exact verification commands and required evidence updates.”

---

If you want, I can also generate a **single “ARCHITECT_START.md”** (repo root) that tells any AI agent exactly what to read first (`INVARIANTS_QUICK.md`, then the implemented invariants, then `DEV_WORKFLOW.md`) and what commands are mandatory before a PR.
