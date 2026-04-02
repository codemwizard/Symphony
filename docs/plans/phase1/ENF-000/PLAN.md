# PLAN: ENF-000 — .gitattributes LF enforcement

Status: planned
Phase: 1
Task: ENF-000
Agent: ARCHITECT

---

## Mission

Copy `symphony-enforcement-v2/gitattributes/.gitattributes` to the repo root
so that `.sh`, `.md`, `.yml`, `.env`, `.json`, `.py`, and `.toml` files are
stored with LF line endings regardless of the authoring OS.

---

## Constraints

- Do not edit the staging file — copy it as-is.
- Do not touch `scripts/agent/run_task.sh` or any governance file.
- If a `.gitattributes` already exists, read it first and check for conflicts.

---

## Prerequisites

- None (root task in ENF wave).

---

## Step 1 — Check for existing .gitattributes

```bash
ls -la .gitattributes 2>/dev/null || echo "NOT FOUND"
```

If a file exists, read it and confirm no conflicting rules before proceeding.

---

## Step 2 — Apply

```bash
cp symphony-enforcement-v2/gitattributes/.gitattributes .gitattributes
```

---

## Step 3 — Verify content

```bash
grep 'eol=lf' .gitattributes
```

Expected: matches for `*.sh`, `*.md`, `*.yml`, `*.env`, `*.json`, `*.py`, `*.toml`.

---

## Step 4 — Create verifier and emit evidence

Create `scripts/audit/verify_enf_000.sh` that:
1. Checks `.gitattributes` exists at repo root.
2. Greps for `eol=lf` for each required extension.
3. Emits `evidence/phase1/enf_000_gitattributes_lf.json` with `status`, `checks`, `failures`, `observed_rules`.
4. Exits 0 on PASS, 1 on FAIL.

Run the verifier:

```bash
bash scripts/audit/verify_enf_000.sh
```

---

## Verification commands

```bash
bash scripts/audit/verify_enf_000.sh
python3 scripts/audit/validate_evidence.py --task ENF-000 --evidence evidence/phase1/enf_000_gitattributes_lf.json
bash scripts/dev/pre_ci.sh
```

---

## Evidence paths

- `evidence/phase1/enf_000_gitattributes_lf.json`

---

## Approval references

No governance file is touched. Standard Architect approval applies.
