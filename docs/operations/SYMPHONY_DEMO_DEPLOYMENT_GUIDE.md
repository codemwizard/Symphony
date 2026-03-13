# Symphony Demo Deployment Guide

## 1. Deployment Model

Symphony demo deployment in this repo is not a separate backend plus bundled frontend product.

The runtime model is:

- Backend: ASP.NET Core minimal API in `services/ledger-api/dotnet/src/LedgerApi/Program.cs`
- Web server: Kestrel inside the .NET application
- Frontend: static HTML/JS under `src/supervisory-dashboard/`, served by the backend at:
  - `/pilot-demo/supervisory`
  - `/pilot-demo/supervisory-legacy` when explicitly enabled

This means the supported demo deployment path is:

- host-based `.NET publish`
- Kestrel serving both API and UI
- same-origin browser access to the API and demo routes

Separate frontend hosting on a Dell Windows laptop is non-native and requires explicit reverse proxying.

## 2. Required Runtime Dependencies

For the supported host-based deployment path, install:

1. .NET SDK / runtime compatible with the repo projects
2. PostgreSQL server
3. PostgreSQL client tools, including `psql`
4. Docker, if you are using the local demo PostgreSQL baseline from `infra/docker/`

`psql` is mandatory for host-based deployment because `scripts/db/migrate.sh` shells out to it directly.

## 3. Required Environment Variables

Minimum required demo environment:

- `SYMPHONY_RUNTIME_PROFILE=pilot-demo`
- `ASPNETCORE_URLS=http://0.0.0.0:8080`
- `DATABASE_URL=postgres://...`
- `INGRESS_STORAGE_MODE=db_psql`
- `SYMPHONY_UI_TENANT_ID=<demo tenant id>`
- `SYMPHONY_UI_API_KEY=<browser read key>`
- `INGRESS_API_KEY=<backend read key>`
- `ADMIN_API_KEY=<server-side privileged key>`
- `SYMPHONY_KNOWN_TENANTS=<allowlisted tenant ids>`

Optional:

- `SYMPHONY_ENABLE_LEGACY_SUPERVISORY_UI=1`

Critical relationship:

- `SYMPHONY_UI_API_KEY` must be populated with a value the backend accepts as `INGRESS_API_KEY`.
- If `SYMPHONY_UI_API_KEY` and `INGRESS_API_KEY` do not match in effective value, browser reads fail even if the UI loads.
- `ADMIN_API_KEY` is server-side only. It must not be exposed to browser bootstrap context, page source, or client-side JavaScript.

## 4. Ports and Exposure

Ports actually used by the demo path:

1. `8080/tcp`
- Ledger API
- supervisory UI
- pilot-demo routes

2. `5432/tcp`
- PostgreSQL

3. `8200/tcp`
- OpenBao, only if you are explicitly using the secrets stack

Recommended exposure for a demo server:

- open `8080/tcp` to the operator laptop/browser
- open `5432/tcp` only if the database is remote and the app server needs it
- do not expose `8200/tcp` publicly unless you have a specific secrets-management reason

## 5. Health and Probe Endpoints

The app serves:

- `/health`
- `/healthz`
- `/readyz`

For the current Kubernetes deployment path, the `ledger-api` deployment probes must match those app routes exactly.

Scope note:

- this guide documents the `ledger-api` probe contract
- it does not claim that the `executor-worker` deployment is HTTP-ready unless that worker surface is explicitly implemented as an HTTP app

## 6. Build Artifacts

The supported demo deployment path is host-based publish:

```bash
dotnet publish services/ledger-api/dotnet/src/LedgerApi/LedgerApi.csproj -c Release -o /opt/symphony/ledger-api
dotnet publish services/ledger-api/dotnet/src/LedgerApi.DemoHost/LedgerApi.DemoHost.csproj -c Release -o /opt/symphony/demo-host
```

Image build flow may exist for reproducibility and cluster use, but it is not the primary operator demo path.

If reproducible image builds are required for cluster use, use:

```bash
scripts/dev/build_demo_images.sh
```

## 7. Database Bring-Up

For local/demo PostgreSQL:

```bash
cd infra/docker
docker compose up -d
```

Default local baseline values from `infra/docker/.env`:

- user: `symphony_admin`
- password: `symphony_pass`
- db: `symphony`

Then export:

```bash
export DATABASE_URL=postgres://symphony_admin:symphony_pass@localhost:5432/symphony
```

## 8. Apply Schema

Run migrations before starting the app:

```bash
bash scripts/db/migrate.sh
```

This requires:

- `DATABASE_URL`
- `psql`

## 9. Start the Demo Server

Recommended host-based launch:

```bash
export SYMPHONY_RUNTIME_PROFILE=pilot-demo
export ASPNETCORE_URLS=http://0.0.0.0:8080
export INGRESS_STORAGE_MODE=db_psql
export DATABASE_URL=postgres://symphony_admin:symphony_pass@localhost:5432/symphony
export SYMPHONY_UI_TENANT_ID=<tenant-id>
export SYMPHONY_UI_API_KEY=<read-key>
export INGRESS_API_KEY=<same-read-key>
export ADMIN_API_KEY=<server-side-admin-key>
export SYMPHONY_KNOWN_TENANTS=<tenant-id>

dotnet /opt/symphony/ledger-api/LedgerApi.dll
```

Or from source:

```bash
SYMPHONY_RUNTIME_PROFILE=pilot-demo \
ASPNETCORE_URLS=http://0.0.0.0:8080 \
INGRESS_STORAGE_MODE=db_psql \
DATABASE_URL=postgres://symphony_admin:symphony_pass@localhost:5432/symphony \
SYMPHONY_UI_TENANT_ID=<tenant-id> \
SYMPHONY_UI_API_KEY=<read-key> \
INGRESS_API_KEY=<same-read-key> \
ADMIN_API_KEY=<server-side-admin-key> \
SYMPHONY_KNOWN_TENANTS=<tenant-id> \
dotnet run --no-launch-profile --project services/ledger-api/dotnet/src/LedgerApi/LedgerApi.csproj
```

## 10. Demo URLs

Once the server is running:

- primary UI: `http://<server>:8080/pilot-demo/supervisory`
- legacy UI, only when enabled: `http://<server>:8080/pilot-demo/supervisory-legacy`
- health: `http://<server>:8080/health`

## 11. Same-Origin API Routes Used by the UI

The browser expects the backend to serve both HTML and API from the same origin.

Important routes:

- `GET /pilot-demo/supervisory`
- `POST /pilot-demo/api/evidence-links/issue`
- `POST /pilot-demo/api/instruction-files/generate`
- `GET /v1/supervisory/programmes/{programId}/reveal`
- `GET /v1/supervisory/instructions/{instructionId}/detail`
- `GET /pilot-demo/api/pilot-success`
- `POST /v1/supervisory/programmes/{programId}/export`
- `GET /pilot-demo/artifacts/{fileName}`

## 12. Dell Windows 10 Laptop Guidance

### Supported approach

Use the Dell laptop as the operator browser only.

1. Ensure the server is reachable on the network
2. Open:

```text
http://<server>:8080/pilot-demo/supervisory
```

### Non-native approach

Hosting only the frontend on the Dell laptop is not the native deployment model.

If you do it anyway, you must reverse-proxy at least:

- `/v1/*`
- `/pilot-demo/api/*`
- `/pilot-demo/artifacts/*`

That requires an explicit IIS/ARR or equivalent proxy configuration and is outside the supported default path.

nginx and IIS are optional outer layers only. They are not required deployment steps for the supported demo path.

## 13. Ordered Demo Bring-Up Sequence

1. Install runtime prerequisites
2. Start PostgreSQL
3. Export required environment variables
4. Run `bash scripts/db/migrate.sh`
5. Publish the app
6. Start the app on Kestrel
7. Provision tenant and programme per `docs/operations/GREENTECH4CE_TENANT_PROGRAMME_PROVISIONING_RUNBOOK.md`
8. Run the operator demo gate:

```bash
bash scripts/dev/pre_ci_demo.sh
```

9. If additional sandbox posture checks are required, run the checklist items in `docs/operations/PHASE1_DEMO_DEPLOY_AND_TEST_CHECKLIST.md`
10. Open the UI from the operator laptop

## 14. Honest Caveats

1. The supported demo deployment path is host-based `.NET publish`, not image-first deployment.
2. The frontend-on-laptop model is non-native and requires reverse proxying.
3. Kestrel is the default web server for the demo path.
4. Kubernetes deployment artifacts may exist, but the operator-facing demo path in this repo is Kestrel-first.
5. `scripts/dev/pre_ci.sh` remains the engineering quality gate; operator bring-up uses `scripts/dev/pre_ci_demo.sh`.
