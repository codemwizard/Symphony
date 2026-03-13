# Phase-1 Demo Deployment and Test Checklist

## Purpose

Use this checklist to deploy the Phase-1 GreenTech4CE pilot/demo sandbox and
start deterministic testing.

This checklist is operator-facing. It uses the existing sandbox manifests,
pilot harness, and demo rehearsal scripts already present in the repo.

Read first:

- `docs/operations/SYMPHONY_DEMO_DEPLOYMENT_GUIDE.md`

## Preconditions

- Work is on a feature branch, not `main`.
- Required approval metadata exists for the active regulated-surface batch.
- Kubernetes access to the target cluster is configured.
- Required secrets for `symphony-pilot-secrets` are available.
- Host-based deployments must have `psql` available before running migrations.
- The operator has the tenant/programme inputs required by:
  - `docs/operations/GREENTECH4CE_TENANT_PROGRAMME_PROVISIONING_RUNBOOK.md`

## Step 1 — Pre-Deploy Validation

Run:

```bash
bash scripts/dev/pre_ci_demo.sh
bash scripts/security/verify_sandbox_deploy_manifest_posture.sh
```

Required runtime contract before you continue:

- `SYMPHONY_RUNTIME_PROFILE=pilot-demo`
- `ASPNETCORE_URLS=http://0.0.0.0:8080`
- `DATABASE_URL=...`
- `INGRESS_STORAGE_MODE=db_psql`
- `SYMPHONY_UI_TENANT_ID=<tenant-id>`
- `SYMPHONY_UI_API_KEY=<read-key>`
- `INGRESS_API_KEY=<same-read-key>`
- `ADMIN_API_KEY=<server-side-admin-key>`
- `SYMPHONY_KNOWN_TENANTS=<tenant-id>`

Pass conditions:
- `pre_ci_demo.sh` exits `0`
- sandbox deploy posture verifier exits `0`
- evidence exists at `evidence/phase1/sandbox_deploy_manifest_posture.json`

Stop conditions:
- any failure in `pre_ci_demo.sh`
- missing or invalid sandbox manifest posture evidence

## Step 2 — Deploy the Sandbox

Apply the sandbox kustomization:

```bash
kubectl apply -k infra/sandbox/k8s
```

This deploys:
- namespace
- DB migration job
- ledger API deployment/service
- executor worker deployment
- secrets bootstrap
- strict mesh policy

Source of truth:
- `infra/sandbox/k8s/kustomization.yaml`

## Step 3 — Wait for Readiness

Run:

```bash
kubectl wait --for=condition=complete --timeout=600s job/db-migration-job -n symphony-pilot
kubectl rollout status deployment/ledger-api -n symphony-pilot --timeout=600s
kubectl rollout status deployment/executor-worker -n symphony-pilot --timeout=600s
kubectl get pods -n symphony-pilot
kubectl get svc -n symphony-pilot
```

Pass conditions:
- migration job completes
- both deployments roll out successfully
- pods are healthy in `symphony-pilot`

Stop conditions:
- migration job timeout/failure
- either deployment fails rollout
- pods remain crash-looping or pending

## Step 4 — Provision Tenant and Programme

Follow exactly:

- `docs/operations/GREENTECH4CE_TENANT_PROGRAMME_PROVISIONING_RUNBOOK.md`

Execute the runbook in this order:
1. record tenant/programme/policy/operator identifiers
2. confirm supplier seed prerequisites
3. apply configuration in this order:
   - tenant context
   - programme context
   - policy binding
   - supplier allowlist data
   - evidence/report routing data
4. run pre-go-live isolation verification

Stop conditions:
- any missing identifier or supplier prerequisite
- failed isolation check
- incomplete programme configuration that cannot be cleanly rolled back

## Step 5 — Run Pilot Harness

Run:

```bash
bash scripts/dev/run_phase1_pilot_harness.sh
```

This executes:
- ingress API contract self-test
- executor worker runtime self-test
- evidence-pack API self-test
- exception case-pack self-test
- pilot harness readiness verification when present

Pass conditions:
- command exits `0`
- `evidence/phase1/pilot_harness_replay.json` has `status = PASS`
- `evidence/phase1/pilot_onboarding_readiness.json` has `status = PASS`

Stop conditions:
- any self-test failure
- either evidence file missing
- either evidence file not `PASS`

## Step 6 — Run Demo Rehearsal

Run:

```bash
bash scripts/dev/run_demo_rehearsal.sh
```

Pass conditions:
- command exits `0`
- `evidence/phase1/tsk_p1_demo_010_reveal_rehearsal.json` exists and has `status = PASS`
- fallback pack exists under `evidence/phase1/demo_reveal_fallback_pack/`

Stop conditions:
- rehearsal evidence missing
- fallback pack missing
- rehearsal output not `PASS`

## Step 7 — Validate Demo Proof Pack

Run:

```bash
bash scripts/audit/verify_phase1_demo_proof_pack.sh
```

Pass conditions:
- command exits `0`
- demo proof evidence generated successfully

Stop conditions:
- any missing demo proof artifact
- proof-pack verifier failure

## Step 8 — Manual Contract Spot Checks

Use the Phase-1 pilot contract in:

- `docs/operations/PHASE1_PILOT_INTEGRATION_CONTRACT.md`

Check these flows:
1. `POST /v1/ingress/instructions` with the deterministic sample payload
2. `POST /v1/ingress/instructions` with the malformed payload and confirm `400 INVALID_REQUEST`
3. `GET /v1/evidence-packs/{instruction_id}` with correct `x-tenant-id`
4. `GET /v1/exceptions/{instruction_id}/case-pack` with correct `x-tenant-id`

Expected:
- ingress success returns `202` with `ack=true`
- malformed ingress returns `400 INVALID_REQUEST`
- evidence pack returns `200` or `404` when tenant scope is wrong
- case pack returns `200` or `422 CASE_PACK_INCOMPLETE` when lifecycle refs are incomplete

## Required Evidence at End

The deployment/test run is ready for operator signoff only if all of these are
present and passing:

- `evidence/phase1/sandbox_deploy_manifest_posture.json`
- `evidence/phase1/pilot_harness_replay.json`
- `evidence/phase1/pilot_onboarding_readiness.json`
- `evidence/phase1/tsk_p1_demo_010_reveal_rehearsal.json`

Optional but recommended:
- demo proof-pack evidence produced by `scripts/audit/verify_phase1_demo_proof_pack.sh`

## Default Command Sequence

```bash
bash scripts/dev/pre_ci_demo.sh
bash scripts/security/verify_sandbox_deploy_manifest_posture.sh
kubectl apply -k infra/sandbox/k8s
kubectl wait --for=condition=complete --timeout=600s job/db-migration-job -n symphony-pilot
kubectl rollout status deployment/ledger-api -n symphony-pilot --timeout=600s
kubectl rollout status deployment/executor-worker -n symphony-pilot --timeout=600s
bash scripts/dev/run_phase1_pilot_harness.sh
bash scripts/dev/run_demo_rehearsal.sh
bash scripts/audit/verify_phase1_demo_proof_pack.sh
```

## Assumptions

- The cluster already has access to the images referenced by the sandbox manifests.
- Secret material for `symphony-pilot-secrets` is handled outside this checklist.
- Tenant/programme provisioning is still operator-run and not self-service.
- This checklist covers deployment and initial testing, not production go-live.
- The supported demo server is Kestrel; nginx/IIS are optional reverse proxies, not required deployment steps.
- `scripts/dev/pre_ci.sh` remains the engineering branch-quality gate; this checklist uses the narrower operator demo gate.
