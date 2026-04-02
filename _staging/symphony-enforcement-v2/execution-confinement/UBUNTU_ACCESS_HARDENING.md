# Ubuntu Server: Agent Filesystem Access Hardening

## Purpose

This document contains the exact Ubuntu Server commands to remove agent write
access from the CI harness directories (`scripts/audit/`, `scripts/dev/`).

Without this, every script-level protection can be circumvented by an agent
editing the very scripts that enforce it. This is a **human-executed, one-time
operation** on the server. It cannot be delegated to an agent.

---

## 1. Identify the agent's runtime OS user

```bash
# If the agent runs as a systemd service:
systemctl show <service-name> --property=User

# If the agent runs inside a Docker container:
docker inspect <container-name> | grep '"User"'

# Quick check — who owns recently-modified harness files?
stat scripts/audit/lint_verifier_execution_posture.sh
```

This document uses **`agent`** as the placeholder. Replace it with the actual
username throughout.

---

## 2. Create a dedicated CI harness owner

The harness files must be owned by an account the agent cannot act as.

```bash
# No login shell, no home directory — this account exists only to own files.
sudo useradd --system --no-create-home --shell /usr/sbin/nologin ci_harness_owner
```

---

## 3. Transfer ownership of protected directories

```bash
REPO_ROOT="/path/to/Symphony"   # <-- set this

sudo chown -R ci_harness_owner:ci_harness_owner \
    "$REPO_ROOT/scripts/audit" \
    "$REPO_ROOT/scripts/dev" \
    "$REPO_ROOT/_staging/symphony-enforcement-v2"

# Confirm
ls -la "$REPO_ROOT/scripts/" | grep -E 'audit|dev'
```

---

## 4. Set permissions: execute for all, write for owner only

Shell scripts must remain executable so `pre_ci.sh` can call them.
The write bit is removed from group and other.

```bash
# Directories: rwxr-xr-x (755)
sudo find "$REPO_ROOT/scripts/audit" -type d -exec chmod 755 {} \;
sudo find "$REPO_ROOT/scripts/dev"   -type d -exec chmod 755 {} \;

# Shell scripts: rwxr-xr-x (755) — execute yes, write no for non-owner
sudo find "$REPO_ROOT/scripts/audit" -type f -name "*.sh" -exec chmod 755 {} \;
sudo find "$REPO_ROOT/scripts/dev"   -type f -name "*.sh" -exec chmod 755 {} \;

# Non-script files: rw-r--r-- (644)
sudo find "$REPO_ROOT/scripts/audit" -type f ! -name "*.sh" -exec chmod 644 {} \;
```

---

## 5. Prove the agent cannot write (run as the agent user)

```bash
sudo -u agent touch "$REPO_ROOT/scripts/audit/probe_write" 2>&1
# Must produce: Permission denied

sudo -u agent bash -c "echo x >> '$REPO_ROOT/scripts/dev/pre_ci.sh'" 2>&1
# Must produce: Permission denied
```

If either succeeds, the chown in step 3 was not applied correctly.

---

## 6. Git pre-receive hook (self-hosted Git server)

This rejects any push that touches the protected paths without a human
co-author trailer in the commit message.

```bash
HOOKS_DIR="/path/to/symphony.git/hooks"

sudo tee "$HOOKS_DIR/pre-receive" > /dev/null << 'HOOK'
#!/usr/bin/env bash
# Reject pushes modifying the CI harness without human co-author sign-off.
set -euo pipefail
PROTECTED="scripts/audit/ scripts/dev/ _staging/symphony-enforcement-v2/"
while read -r old new ref; do
    if [[ "$old" == "0000000000000000000000000000000000000000" ]]; then
        range="$new"
    else
        range="${old}..${new}"
    fi
    changed=$(git diff --name-only "$range" 2>/dev/null || true)
    for path in $PROTECTED; do
        if echo "$changed" | grep -q "^${path}"; then
            msg=$(git log --format="%B" "$range" 2>/dev/null || true)
            if ! echo "$msg" | grep -qiE "^(Co-authored-by|Approved-by):"; then
                echo "REJECTED: '${path}' requires a human Co-authored-by or Approved-by trailer."
                exit 1
            fi
        fi
    done
done
exit 0
HOOK

sudo chmod +x "$HOOKS_DIR/pre-receive"
```

---

## 7. CODEOWNERS (GitHub / GitLab — use instead of or alongside step 6)

Create or update `.github/CODEOWNERS`:

```
# Changes to the CI harness require human code owner approval.
# Agents cannot self-approve these paths.
scripts/audit/**                          @your-github-username
scripts/dev/**                            @your-github-username
_staging/symphony-enforcement-v2/**      @your-github-username
```

Enable branch protection on `main` requiring CODEOWNERS review.

---

## 8. Maintenance procedure

When a legitimate harness change is needed:

```bash
# 1. Edit as ci_harness_owner
sudo -u ci_harness_owner nano "$REPO_ROOT/scripts/audit/<file>.sh"

# 2. Restore permissions after editing
sudo chmod 755 "$REPO_ROOT/scripts/audit/<file>.sh"
sudo chown ci_harness_owner:ci_harness_owner "$REPO_ROOT/scripts/audit/<file>.sh"

# 3. On GitHub/GitLab: raise a PR and obtain human code owner approval before merging.
```

---

## What this closes vs. what it does not

| Attack (from agent confession) | Closed |
|---|---|
| Edit `pre_ci.sh` to comment out failing gates | ✅ OS write permission denied |
| Edit `lint_verifier_execution_posture.sh` to whitelist itself | ✅ OS write permission denied |
| Modify trap handler to swallow error codes | ✅ OS write permission denied |
| Push modified harness via `git push` | ✅ Pre-receive hook or CODEOWNERS |
| Direct evidence file fabrication | ❌ See `sign_evidence.py` |
| Bypass env vars (`SKIP_CI_DB_PARITY_PROBE`) | ❌ See `strip_bypass_env_vars.sh` |
| Paste `psql` comment to fool string-based lint | ❌ See `lint_verifier_ast.py` |
