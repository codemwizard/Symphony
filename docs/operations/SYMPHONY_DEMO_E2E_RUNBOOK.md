# Symphony Demo E2E Runbook

Status: Implemented operator runbook for host-based Phase-1 demo execution
Primary path: host-based `dotnet publish` + Kestrel + PostgreSQL on the local server
Audience: operator running the GreenTech4CE demo from a clean deployment checkout

## 1. Purpose
This runbook is the primary operator document for the local-server Symphony demo path.

It defines one canonical path:
- execute on the Linux server
- use PostgreSQL directly
- publish and run the .NET host on Kestrel
- use the Dell laptop as a browser-only client

It does not define development workflow.
Development remains on feature branches with PR-based integration.

## 2. Deployment Source Contract
This runbook is executed from a **clean deployment checkout**, not from an active development checkout.

Rules:
- Development work is not done on `main`.
- No direct push to `main`.
- No direct pull from `main` into working branches.
- Demo deployment uses a separate clean checkout that tracks `origin/main`.
- The runner must fetch `origin` before evaluating source posture.
- The run must fail closed unless all of these are true:
  - working tree is clean
  - checkout tracks `origin/main`
  - `HEAD` is reachable from fetched `origin/main`
  - `HEAD` is descendant of the required floor commit

Pass condition:
- source gate passes and the runner records branch/ref/SHA in the run bundle

Fail condition:
- dirty tree, stale remote-tracking state, wrong upstream, or commit not on merged mainline

Operator action:
- stop; refresh the deployment checkout instead of improvising from a feature branch

Evidence emitted:
- `evidence/phase1/demo_run/<run_id>/server_snapshot.json`
- `evidence/phase1/demo_run/<run_id>/git_context.txt`

## 3. Canonical Topology
Server responsibilities:
- run database migrations
- publish and start the host process
- execute server-side API smoke checks
- run pilot harness, rehearsal, and proof-pack verification
- capture logs and evidence

Dell laptop responsibilities:
- open the supervisory UI in a browser
- execute browser-visible smoke checks only
- no admin secret handling
- no command-line verification

Unsupported in the canonical flow:
- separate frontend hosting on the Dell
- Kubernetes as the primary local deployment path
- using `pre_ci_demo.sh` as the demo operator runner

## 4. Demo Posture Modes
Two modes are recognized.

### 4.1 Rehearsal-Only / Non-Signoff
Allowed for local rehearsal when the host cannot prove the full OpenBao-backed signing posture.

Pass condition:
- host run completes and required non-signoff evidence is collected

Fail condition:
- operator represents the run as full-demo readiness

Operator action:
- label the run `rehearsal-only` in the run summary and any handoff notes

Evidence emitted:
- `evidence/phase1/demo_run/<run_id>/run_summary.json`
- browser smoke checklist artifact marked accordingly

### 4.2 Full Demo / Signoff
Allowed only when the host can prove OpenBao-backed signing posture and required rotation/TLS checks.

Pass condition:
- INF-006 verification passes and OpenBao posture passes per `docs/security/SYMPHONY_DEMO_KEY_AND_ROTATION_POLICY.md`

Fail condition:
- OpenBao posture unresolved, TLS posture unresolved, or signing verification fails

Operator action:
- stop; do not represent the host as full-demo ready

Evidence emitted:
- `evidence/phase1/tsk_p1_inf_006__evidence_signing_key_management_openbao_rotation.json`
- `evidence/phase1/demo_run/<run_id>/openbao_snapshot.txt`
- `evidence/phase1/demo_run/<run_id>/run_summary.json`

## 5. End-to-End Sequence
This section defines the canonical order.

### Step 0 — Capture pre-run snapshot
Command:
```bash
bash scripts/dev/capture_demo_server_snapshot.sh --run-id <run_id>
```

Pass condition:
- snapshot bundle is created under `evidence/phase1/demo_run/<run_id>/`

Fail condition:
- snapshot script fails or writes outside the run-bundle root

Operator action:
- stop and fix the snapshot/preflight issue before any mutation step

Evidence emitted:
- `server_snapshot.json`
- `listeners.txt`
- `env_contract_snapshot.json`
- `postgres_snapshot.txt`
- `openbao_snapshot.txt` when reachable

### Step 1 — Validate deployment source
Command:
```bash
bash scripts/dev/run_demo_e2e.sh --run-id <run_id> --dry-run
```
The dry-run source gate is part of the runner.

Pass condition:
- source gate passes against fetched `origin/main`

Fail condition:
- checkout is dirty, stale, off-mainline, or below the floor commit

Operator action:
- stop and refresh the deployment checkout

Evidence emitted:
- source-gate results in `run_summary.json`

### Step 2 — Validate binaries and env
Required binaries:
- `dotnet`
- `docker`
- `psql`
- `curl`
- `jq`

Required env:
- `SYMPHONY_RUNTIME_PROFILE=pilot-demo`
- `ASPNETCORE_URLS=http://0.0.0.0:8080`
- `DATABASE_URL`
- `INGRESS_STORAGE_MODE=db_psql`
- `SYMPHONY_UI_TENANT_ID`
- `SYMPHONY_UI_API_KEY`
- `INGRESS_API_KEY`
- `ADMIN_API_KEY`
- `SYMPHONY_KNOWN_TENANTS`

Current demo contract:
- `SYMPHONY_UI_API_KEY == INGRESS_API_KEY`
- `SYMPHONY_UI_TENANT_ID` must be present in `SYMPHONY_KNOWN_TENANTS`

Pass condition:
- all binaries and env are present and contract checks pass

Fail condition:
- missing binary, missing env, read-key mismatch, or tenant not allowlisted

Operator action:
- stop and fix env before starting the app

Evidence emitted:
- env contract presence/fingerprint snapshot
- run-summary preflight section

### Step 3 — Validate host posture
Checks:
- PostgreSQL reachable on `127.0.0.1:5432`
- port `8080` available or occupied only by a known prior Symphony process that can be torn down deterministically
- OpenBao posture checked per active mode

Current branch truth:
- the stable host health route on this branch is `/health`
- `/healthz` and `/readyz` are not treated as canonical host-run requirements on this branch

Pass condition:
- DB reachable and Kestrel bind target is usable

Fail condition:
- DB unreachable, unknown process owns `8080`, or full-demo OpenBao posture is not satisfied in signoff mode

Operator action:
- stop; do not improvise around unknown port ownership or signing posture failures

Evidence emitted:
- `listeners.txt`
- `process_snapshot.txt`
- `postgres_snapshot.txt`
- `openbao_snapshot.txt` when applicable

### Step 4 — Run DB migration
Command:
```bash
bash scripts/db/migrate.sh
```

Pass condition:
- migration script exits `0`

Fail condition:
- migration exits non-zero

Operator action:
- stop; capture failure logs; do not start the app against a partial schema

Evidence emitted:
- migration result in `run_summary.json`
- stdout/stderr logs in the run bundle when captured by the runner

### Step 5 — Publish the host
Canonical publish target:
- `services/ledger-api/dotnet/src/LedgerApi.DemoHost/LedgerApi.DemoHost.csproj`

Command shape:
```bash
dotnet publish services/ledger-api/dotnet/src/LedgerApi.DemoHost/LedgerApi.DemoHost.csproj -c Release -o <publish_dir>
```

Pass condition:
- publish exits `0` and the published host executable exists

Fail condition:
- publish fails or expected executable is missing

Operator action:
- stop; inspect publish logs

Evidence emitted:
- publish result in `run_summary.json`
- publish stdout/stderr logs in the run bundle

### Step 6 — Start and supervise Kestrel
The host process must be started under explicit process supervision by the runner.

Required process controls:
- run directory
- PID file
- stdout log path
- stderr log path
- restrictive file permissions
- readiness timeout
- trap-based cleanup
- graceful shutdown on success/failure
- single active run on host by default

Pass condition:
- host starts and PID/log paths are recorded

Fail condition:
- startup fails, PID is not captured, or stale/unknown process handling cannot be resolved safely

Operator action:
- stop; do not use ad hoc `nohup`, shell backgrounding, or tmux as the canonical path

Evidence emitted:
- PID/log paths in `run_summary.json`
- process logs under the run bundle

### Step 7 — Wait for health
Canonical host-run health contract on this branch:
- use `GET /health`

Pass condition:
- `/health` returns `200`

Fail condition:
- timeout or non-200 response

Operator action:
- stop; capture logs and post-failure snapshot

Evidence emitted:
- endpoint used and result in `run_summary.json`

### Step 8 — Provisioning entrypoint
Repo-backed provisioning entrypoints on this branch:
- `POST /api/admin/onboarding/tenants` — create or upsert tenant
- `POST /api/admin/onboarding/programmes` — create programme
- `POST /api/admin/onboarding/programmes/{id}/policy-binding` — bind policy
- `PUT /api/admin/onboarding/programmes/{id}/activate` — activate programme
- `GET /api/admin/onboarding/status` — full readback

What is deterministic in-repo:
- tenant and programme onboarding endpoints exist
- admin authorization exists via `x-admin-api-key`
- idempotency key is derived as `tenant_onboarding:<tenant_id>`
- programme lifecycle (create/bind/activate) is server-side

What is not fully repo-backed on this branch:
- supplier allowlist application
- evidence/report routing application

Canonical operator rule:
- tenant and programme onboarding may be executed by the runner
- full supplier/routing state must either already be satisfied externally or the run remains non-signoff

Pass condition:
- tenant and programme onboarding endpoints succeed, and external provisioning inputs are recorded as satisfied

Fail condition:
- onboarding fails, or required external provisioning prerequisites are not satisfied for the intended signoff posture

Operator action:
- stop for signoff runs; rehearsal-only runs may continue only if clearly labeled non-signoff

Evidence emitted:
- onboarding responses in the run bundle
- provisioning status in `run_summary.json`
- operator checklist state for external provisioning prerequisites

### Step 9 — Server-side API smoke
These checks are server-side only. They may use secret-bearing headers and must not be delegated to the Dell browser.

Required checks:
- `GET /pilot-demo/api/pilot-success`
- `GET /v1/supervisory/programmes/{programId}/reveal` with `x-api-key` and `x-tenant-id`
- `POST /v1/supervisory/programmes/{programId}/export` with `x-api-key` and `x-tenant-id`
- `POST /api/admin/onboarding/tenants` with `x-admin-api-key` when provisioning is executed by the runner

Pass condition:
- expected HTTP success codes returned

Fail condition:
- any required API check fails

Operator action:
- stop; inspect logs and payloads on the server

Evidence emitted:
- server-side smoke results in `run_summary.json`

### Step 10 — Run harness and proof steps
Commands:
```bash
bash scripts/dev/run_phase1_pilot_harness.sh
bash scripts/dev/run_demo_rehearsal.sh
bash scripts/audit/verify_phase1_demo_proof_pack.sh
```

Pass condition:
- each command exits `0`

Fail condition:
- any command exits non-zero or required evidence is missing

Operator action:
- stop; do not proceed to signoff or browser smoke

Evidence emitted:
- `evidence/phase1/pilot_harness_replay.json`
- `evidence/phase1/pilot_onboarding_readiness.json`
- `evidence/phase1/tsk_p1_demo_010_reveal_rehearsal.json`
- `evidence/phase1/regulator_demo_pack.json`
- `evidence/phase1/tier1_pilot_demo_pack.json`

### Step 11 — Dell/browser smoke
These checks are browser-visible only. They do not require operator secrets.

Browser-visible checks:
- open `http://<server>:8080/pilot-demo/supervisory`
- confirm supervisory shell loads
- confirm pilot-success UI state is visible where applicable
- confirm the operator can navigate the reveal surface
- confirm export UX is present if the flow is in scope for the demo

Pass condition:
- required browser-visible checks are manually confirmed

Fail condition:
- page does not load, visible operator flow is broken, or the check is not completed and not waived

Operator action:
- record the outcome in the machine-readable browser checklist artifact

Evidence emitted:
- `evidence/phase1/demo_run/<run_id>/browser_smoke_checklist.json`

### Step 12 — Capture post-run snapshot
Command:
```bash
bash scripts/dev/capture_demo_server_snapshot.sh --run-id <run_id>
```

Pass condition:
- post-run snapshot updates the run bundle cleanly

Fail condition:
- post-run capture fails

Operator action:
- record snapshot failure in closeout and preserve whatever logs are available

Evidence emitted:
- updated snapshot bundle

### Step 13 — Teardown
Teardown must be explicit.

Delete:
- supervised host process
- stale PID file
- temporary runtime files under the runner’s run directory

Retain and archive:
- run bundle under `evidence/phase1/demo_run/<run_id>/`
- publish/start logs
- pilot harness, rehearsal, and proof-pack evidence

Rotate:
- demo read/admin keys per the key-rotation policy when required

Reuse vs recreate rule:
- tenant onboarding may be idempotently reused when the same tenant is intentionally retained
- a new run must not silently reuse unknown stale process state

Pass condition:
- process stopped cleanly and retained artifacts are still present

Fail condition:
- process cannot be stopped cleanly or artifacts are lost

Operator action:
- record teardown result in `run_summary.json`

Evidence emitted:
- teardown status in `run_summary.json`

### Step 14 — Key-rotation closeout
This is a mandatory closeout action for signoff runs and a strongly required action for rehearsal runs using real credentials.

Pass condition:
- required keys are rotated or an explicit waiver is recorded

Fail condition:
- rotation required but neither completed nor waived

Operator action:
- stop signoff closeout until rotation or waiver state is recorded

Evidence emitted:
- key-rotation closeout status in `run_summary.json`

## 6. Task Evidence vs Run Evidence
Task evidence proves the operator tooling exists and passes its task-level verifier.
Examples:
- `evidence/phase1/tsk_p1_demo_018_e2e_runbook.json`
- `evidence/phase1/tsk_p1_demo_019_server_snapshot.json`
- `evidence/phase1/tsk_p1_demo_020_demo_runner.json`

run evidence proves one specific demo execution.
Examples:
- `evidence/phase1/demo_run/<run_id>/server_snapshot.json`
- `evidence/phase1/demo_run/<run_id>/browser_smoke_checklist.json`
- `evidence/phase1/demo_run/<run_id>/run_summary.json`

Do not treat task evidence as proof that a specific demo run succeeded.

## 7. Kubernetes Appendix
This appendix is informational only.

It is:
- non-canonical for the current local server
- not part of local demo readiness sign-off
- not validated on this host baseline

Current host baseline limitation:
- `k3s` is inactive
- `kubectl` is unavailable

Reference-only flow:
```bash
kubectl apply -k infra/sandbox/k8s
kubectl wait --for=condition=complete --timeout=600s job/db-migration-job -n symphony-pilot
kubectl rollout status deployment/ledger-api -n symphony-pilot --timeout=600s
kubectl rollout status deployment/executor-worker -n symphony-pilot --timeout=600s
```

If this appendix path is used later, it requires its own readiness proof including:
- actual probe parity
- OpenBao/ESO posture
- strict mesh/TLS posture
- the same provisioning and demo proof checks
