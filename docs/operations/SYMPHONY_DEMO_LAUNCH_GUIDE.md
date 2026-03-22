# Symphony Demo Launch Guide

Follow these steps to initialize the Symphony development environment and launch the Supervisory Demo.

---

## Phase 1: Environment Preparation & Port Mitigation
Before starting Docker, ensure that required ports (specifically **5432** for Postgres and **8200** for OpenBao) are not in use by local services.

### 1. Identify Port Conflicts
```bash
# Check if port 5432 (PostgreSQL) is currently bound
sudo netstat -tulpn | grep 5432
```
*   **If you see a result**: A local PostgreSQL service is running on your host. This will block Docker from starting.

### 2. Mitigate Host Conflicts
If port 5432 is taken, stop the local service:
```bash
sudo systemctl stop postgresql
```

---

## Phase 2: Starting Infrastructure
Symphony uses separate Docker Compose files for the database and security layers.

### 3. Start the Database
```bash
cd ~/workspace/Symphony/infra/docker
docker compose up -d
```

### 4. Start OpenBao (Secrets Management)
```bash
cd ~/workspace/Symphony/infra/openbao
docker compose up -d
```

### 5. Verify Running Services
```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```
*   **Expected Output**: Both `symphony-postgres` and `symphony-openbao` should show a status of "Up".

---

## Phase 3: System Initialization
### 6. Run the Canonical Bootstrap
This builds the `LedgerApi` and initializes the cryptographic domains in OpenBao.
```bash
cd ~/workspace/Symphony
bash scripts/dev/bootstrap.sh
```
*   **Verification**: Ensure the output states `✓ OpenBao bootstrapped with 5 key domains`.

### 7. Apply Database Migrations
Synchronize your database schema with the implementation logic.
```bash
bash scripts/db/migrate.sh
```

---

## Phase 4: Launching the Demo
### 8. Run the Ledger API
The Demo UI is served by the main Ledger API when run in the `pilot-demo` profile. You must source the secrets before running the project.
```bash
source /tmp/symphony_openbao/secrets.env
dotnet run --project services/ledger-api/dotnet/src/LedgerApi/LedgerApi.csproj
```
> [!NOTE]
> Sourcing `secrets.env` now automatically provides the `BAO_ROLE_ID` and `BAO_SECRET_ID` required for hardened mode. If you see an error about missing role IDs, ensure you have run Step 6 successfully.

### 9. Access the UI
Once the server is running, access the specialized demo endpoints:
*   **Supervisory Dashboard**: [http://localhost:8080/pilot-demo/supervisory](http://localhost:8080/pilot-demo/supervisory)
*   **Legacy View**: [http://localhost:8080/pilot-demo/supervisory-legacy](http://localhost:8080/pilot-demo/supervisory-legacy)
*   **Recipient Landing**: [http://localhost:8080/pilot-demo/evidence-link](http://localhost:8080/pilot-demo/evidence-link)

---

## Recurring Maintenance & Troubleshooting
*   **Bao Unseal**: If OpenBao shuts down, rerun Step 4 and Step 6.
*   **Stale Secrets**: If the API reports unauthorized access to the ledger, run `source /tmp/symphony_openbao/secrets.env` before starting the `dotnet run` command.
*   **Self-Test Error**: If you see `No supported self-test flag provided`, check that you are running `LedgerApi.csproj` and not `LedgerApi.DemoHost.csproj`.
