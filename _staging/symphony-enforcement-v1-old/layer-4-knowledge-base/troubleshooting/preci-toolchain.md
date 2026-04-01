# Troubleshooting: PRECI.BOOTSTRAP.TOOLCHAIN

**Failure signature:** `PRECI.BOOTSTRAP.TOOLCHAIN`
**Gate:** `pre_ci.bootstrap_local_ci_toolchain`
**Owner:** platform
**DRD level:** L1

## What this means

The toolchain bootstrap failed. A required CLI tool is missing or the
`.toolchain/bin` symlink is broken.

## Expected failure output

```
ERROR: scripts/audit/bootstrap_local_ci_toolchain.sh not found
```

Or from inside the bootstrap script:

```
ERROR: required tool 'yq' not found
ERROR: .toolchain/bin not on PATH
```

## Diagnostic steps

1. **Run bootstrap directly and read the full output:**
   ```bash
   bash scripts/audit/bootstrap_local_ci_toolchain.sh
   ```
   The script names the missing tool explicitly.

2. **Check PATH after bootstrap:**
   ```bash
   export PATH="$PWD/.toolchain/bin:$PATH"
   which yq ripgrep dotnet
   ```

3. **Check `.toolchain/bin` exists and is populated:**
   ```bash
   ls -la .toolchain/bin/
   ```

4. **Re-install the missing tool** per its documentation, then re-run bootstrap.

## Clearing the DRD lockout

```bash
# Step 1 — create the casefile
scripts/audit/new_remediation_casefile.sh \
  --phase phase1 \
  --slug toolchain-bootstrap \
  --failure-signature PRECI.BOOTSTRAP.TOOLCHAIN \
  --origin-gate-id pre_ci.bootstrap_local_ci_toolchain \
  --repro-command "scripts/dev/pre_ci.sh"

# Step 2 — document root cause in PLAN.md

# Step 3 — remove lockout
rm .toolchain/pre_ci_debug/drd_lockout.env

# Step 4 — re-run
scripts/dev/pre_ci.sh
```
