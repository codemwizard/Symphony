# Deterministic Debugging Playbook

**Date:** 2026-04-30
**Purpose:** Repeatable, step-by-step diagnostic patterns for common CI/pipeline failure classes.
These patterns are proven to resolve issues in a single pass where undirected debugging typically fails across multiple sessions.

---

## Pattern 1: Structured Format Parsing Failures

**Applies when:** An assertion or parser fails on data that was written by the same system. The error shows an empty, garbled, or misaligned field value.

**Example failure signature:**
```
ERROR: Expected step 2, got
```

### Root Cause Class

A variable interpolated into a structured line (delimited by `|`, `:`, `,`, etc.) contains an **embedded newline**, splitting one logical line into multiple physical lines. The parser reads line N+1 as a new record, finds no delimiters, and all fields after the first are empty.

### Diagnostic Steps

| Step | Action | What you're looking for |
|------|--------|------------------------|
| **1** | **Read the error value literally** | Is the value wrong, empty, or garbled? Empty/garbled → format problem. Wrong value → logic problem. |
| **2** | **Find the reader (assertion/parser)** | What delimiter does it expect? (`IFS='|'`, `cut -d,`, etc.) |
| **3** | **Find the writer (emitter)** | Does the writer's format match the reader's delimiter? |
| **4** | **If formats match, trace interpolated data** | Which variables are computed at runtime (via `$(...)`) vs hardcoded? |
| **5** | **Rank variables by newline risk** | Any variable from a subprocess can produce multi-line output. Prioritize: `grep -o`, `psql -t`, `awk`, `find`, `ls`. |
| **6** | **Run the suspicious command standalone** | Does it produce exactly one line? If not, you've found the bug. |
| **7** | **Confirm by reconstructing the corruption** | Show exactly how multi-line output breaks the format into the observed error. |
| **8** | **Fix at the source** | Constrain the output to one line (`head -1`, `tr -d '\n'`, `| tail -1`, etc.) |

### Worked Example: PRECI Sequence Assertion Failure

**Error:** `ERROR: Expected step 2, got`

**Step 1 — Read literally:** `step_num` is empty, not wrong. This is a format/parsing problem.

**Step 2 — Find the reader:**
```bash
while IFS='|' read -r prefix step_num step_name ...; do
```
Reader expects pipe-delimited lines.

**Step 3 — Find the writer:**
```bash
printf "PRECI_STEP|%s|%s|%s|%s|%s|%s|%s\n" "$PRECI_STEP_COUNTER" \
  "$step_name" "$command_digest" "$evidence_digest" \
  "$env_fingerprint" "$executor_id" "$timestamp"
```
Writer uses pipe delimiters. Formats match → problem is in the data.

**Step 4 — Trace interpolated data:** Seven variables. `env_fingerprint` calls `capture_env_fingerprint()`, which runs `grep` and `psql` → suspicious.

**Step 5 — Rank by newline risk:** Inside `capture_env_fingerprint()`:
```bash
migration_head=$(ls -1 schema/migrations/*.sql | sort | tail -1 | grep -oP '\d+')
```
`grep -oP '\d+'` outputs **every match on its own line**.

**Step 6 — Run standalone:**
```bash
$ ls -1 schema/migrations/*.sql | sort | tail -1 | grep -oP '\d+'
0187
8
25519
```
Three lines from filename `0187_wave8_integrate_ed25519_verification.sql`. **Bug found.**

**Step 7 — Reconstruct the corruption:** `migration_head` becomes `"0187\n8\n25519"`. The `printf` produces:
```
PRECI_STEP|1|run_schema_checks|<digest>|NONE|<hash>:0187
8
25519:<checksum>|<executor>|<timestamp>
```
Reader sees line 2 as `8` with no pipes → `step_num` is empty after `IFS='|'` split. Matches error exactly.

**Step 8 — Fix:**
```bash
# Before:
migration_head=$(... | grep -oP '\d+' || echo "unknown")
# After:
migration_head=$(... | grep -oP '\d+' | head -1 || echo "unknown")
```

### Common Newline Sources in Shell

| Pattern | Risk | Mitigation |
|---------|------|------------|
| `grep -o` / `grep -oP` | Outputs each match on its own line | `\| head -1` or anchor regex to match once |
| `psql -t` | May include blank leading/trailing lines | `\| tr -d '\n'` or `\| xargs` |
| `find` | One result per line by design | `\| head -1` |
| `awk '{print $N}'` on multi-line input | Preserves input line count | Pipe input through `head -1` first |
| Command substitution `$(...)` | Strips trailing newlines but preserves internal ones | Validate output is single-line before interpolation |

---

## Pattern 2: Hash/Checksum Drift (Baseline Mismatch)

**Applies when:** A stored hash or checksum no longer matches a runtime-computed hash, but both the artifact and the data source appear correct in isolation.

**Example failure signature:**
```
Baseline drift detected
baseline_hash: 8ca013d5...
current_hash:  888af428...
```

### Root Cause Class

The stored artifact (baseline) was generated from **data source A**, but the runtime check computes its hash against **data source B**. Both sources represent the "same" schema, but differ in representation because of how they were built (incremental vs from-scratch, different tool versions, different creation order).

### Diagnostic Steps

| Step | Action | What you're looking for |
|------|--------|------------------------|
| **1** | **Read the comparison logic** | What two things are being compared? Where does each come from? |
| **2** | **Check the easy failure modes** | Tool version mismatch? Wrong file path? Missing file? Wrong database? |
| **3** | **Identify the runtime context** | Is the runtime value computed against the **same data source** the artifact was generated from? This is the critical question. |
| **4** | **Test both sources independently** | Hash artifact against source A, hash against source B. Which matches, which doesn't? |
| **5** | **Diff the actual content** | Don't just compare hashes — look at what's *different*. Systematic diff = different source. Random diff = non-determinism. |
| **6** | **Determine the canonical source of truth** | The artifact must be generated from whatever the **checker** compares it against. Not the other way around. |
| **7** | **Regenerate from the correct source** | One command, verified by re-hashing. |

### Worked Example: Schema Baseline Drift

**Error:** `Baseline drift detected` with mismatched hashes.

**Step 1 — Read comparison logic:** `check_baseline_drift.sh` canonicalizes the baseline file → hash A, does `pg_dump` of `DATABASE_URL` and canonicalizes → hash B, fails if A ≠ B.

**Step 2 — Check easy modes:** Evidence file shows `pg_dump` version 18.3 matches server version 18.3, dump source is the container. No version skew.

**Step 3 — Identify runtime context:** The error output shows `Dropping temp DB: symphony_pre_ci_...`. Reading `pre_ci.sh`, the flow is:
1. Create fresh empty DB
2. Repoint `DATABASE_URL` to it
3. Apply all migrations from scratch
4. Run `check_baseline_drift.sh` → compares baseline against **ephemeral from-scratch DB**

The baseline was generated from the **live long-lived DB**. The checker runs against a **fresh from-scratch DB**. **Different sources.**

**Step 4 — Test both independently:**

| Comparison | Baseline hash | Dump hash | Result |
|-----------|---------------|-----------|--------|
| Baseline vs live DB | `8ca013d5...` | `8ca013d5...` | ✅ Match |
| Baseline vs ephemeral DB | `8ca013d5...` | `888af428...` | ❌ Mismatch |

This confirms the baseline was generated from the live DB but is checked against the ephemeral DB.

**Step 5 — Diff content:** Hundreds of lines differ — all in function bodies, CHECK constraints, and trigger logic from Wave 8 migrations (0172–0187). Systematic, not random. Confirms different-source hypothesis.

**Step 6 — Determine source of truth:** `pre_ci.sh` checks against the from-scratch ephemeral DB. Therefore the baseline must be generated from a from-scratch run.

**Step 7 — Regenerate:**
```bash
# Canonicalize the ephemeral dump (already produced in step 4)
cp /tmp/ephemeral_dump.sql schema/baselines/current/0001_baseline.sql

# Verify
sha256sum /tmp/verify_baseline_norm.sql /tmp/ephemeral_dump.sql
# Both: 888af4286c9530057c1c4b5fc712465fc1ef749b24fe912df47d80a39954a751
```

### Why Other Agents Fail at This

| Trap | What happens | Why it wastes time |
|------|-------------|-------------------|
| **Diffing the wrong pair** | They diff baseline vs *live* DB, see they match, and conclude "there's no drift." | They didn't read `pre_ci.sh` to see it uses an ephemeral DB. |
| **Trying to fix migrations** | They see function body diffs and try to edit migration SQL to make from-scratch output match the live DB. | Forward-only policy forbids editing applied migrations. And the migrations aren't wrong — the baseline is. |
| **Editing the canonicalizer** | They assume the canonicalizer is non-deterministic and add normalization rules. | The canonicalizer is deterministic — the inputs genuinely differ. |
| **Regenerating from the live DB** | They re-dump the live DB as a "fix." Same hash, same failure. | They didn't identify that the checker uses from-scratch, not live. |

### General Principle

> **A stored hash is a contract between a generator and a checker. When the check fails, figure out what the checker actually computes against — then regenerate the artifact from that same source.** The mistake is assuming the generator and checker use the same input. Often they don't, and the drift is in the *input selection*, not the data.

---

## Meta-Pattern: Why Single-Pass Resolution Works

Both patterns above share a common structure:

1. **Read the mechanism, not the symptom.** Open the code that produces the error. Understand the exact comparison or parse being done. Don't guess from the error message alone.

2. **Enumerate the failure space.** For a hash comparison, there are exactly two inputs. For a format parse, there is a reader format and N interpolated variables. The bug is in one of these — not elsewhere.

3. **Test each candidate independently.** Run the suspicious command, hash the suspicious file, print the suspicious variable. Don't reason about what it *should* produce — observe what it *actually* produces.

4. **Confirm by reconstruction.** Before applying a fix, demonstrate that you can reconstruct the exact error from the actual data. If you can't reconstruct it, you haven't found the root cause.

5. **Fix at the source.** Change the one thing that produces incorrect input. Don't add workarounds downstream.

The reason this works in one pass is that it's **eliminative, not exploratory**. You're not trying things to see what works. You're narrowing a finite set of candidates to the one that's broken, proving it's broken, and fixing it.
