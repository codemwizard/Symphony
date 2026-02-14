# Phase-1 Sandbox Deployability Baseline

This baseline defines the minimum deploy artifacts for customer VPC pilot readiness.

## Artifacts
- `infra/sandbox/k8s/namespace.yaml`
- `infra/sandbox/k8s/ledger-api-deployment.yaml`
- `infra/sandbox/k8s/executor-worker-deployment.yaml`
- `infra/sandbox/k8s/secrets-bootstrap.yaml`
- `infra/sandbox/k8s/kustomization.yaml`

## Baseline Requirements
- API and worker are each configured with `replicas >= 2`.
- Deployments include anti-affinity and topology spread constraints.
- Secrets bootstrap uses `symphony-pilot-secrets` and avoids inline credentials.
- OpenBao posture remains part of secrets strategy (`infra/openbao/openbao.hcl`).

## Verification
- `scripts/security/verify_sandbox_deploy_manifest_posture.sh`
- Evidence: `evidence/phase1/sandbox_deploy_manifest_posture.json`
