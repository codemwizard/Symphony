#!/usr/bin/env bash
set -euo pipefail

# lint_pii_leakage_payloads.sh
#
# Phase-0 mechanical guardrail: fail closed on obvious raw-PII key leakage
# in regulated payload/log/evidence surfaces.
#
# Intentionally structural/static: grep-style, deterministic, and cheap.
#
# Allow markers:
#   - "symphony:pii_ok" (inline allow for a specific line/fixture)
#
# Env knobs (for unit tests / narrowing scope):
#   PII_LINT_ROOTS="src packages scripts schema"  (space-separated repo roots)
#   PII_LINT_EXCLUDE_GLOBS="docs/** **/*.md"       (space-separated globs)
#   PII_LINT_MAX_FINDINGS=50

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"

EVIDENCE_DIR="$ROOT_DIR/evidence/phase0"
EVIDENCE_FILE="$EVIDENCE_DIR/pii_leakage_payloads.json"
mkdir -p "$EVIDENCE_DIR"

CHECK_ID="SEC-PII-LEAKAGE-PAYLOADS"
GATE_ID="SEC-G17"
INVARIANT_ID="INV-112"

PII_LINT_ROOTS="${PII_LINT_ROOTS:-src packages scripts schema}"
PII_LINT_EXCLUDE_GLOBS="${PII_LINT_EXCLUDE_GLOBS:-docs/** scripts/**/tests/** **/*_test.* **/*.md **/*.txt **/*.png **/*.jpg **/*.jpeg **/*.gif **/*.pdf **/*.zip **/*.tgz **/*.gz **/*.tar **/*.bin **/*.exe **/*.dll **/*.so **/*.dylib}"
PII_LINT_MAX_FINDINGS="${PII_LINT_MAX_FINDINGS:-50}"

have_rg=0
if command -v rg >/dev/null 2>&1; then
  have_rg=1
fi

if [[ "$have_rg" -ne 1 ]]; then
  # Fail closed: this is a security gate and should not silently skip.
  python3 - <<PY
import json
from pathlib import Path
out = {
  "check_id": "${CHECK_ID}",
  "gate_id": "${GATE_ID}",
  "invariant_id": "${INVARIANT_ID}",
  "timestamp_utc": "${EVIDENCE_TS}",
  "git_sha": "${EVIDENCE_GIT_SHA}",
  "schema_fingerprint": "${EVIDENCE_SCHEMA_FP}",
  "status": "FAIL",
  "ok": False,
  "errors": ["missing_dependency:rg"],
  "findings": [],
  "notes": "ripgrep (rg) not found in PATH; gate fails closed for CI/local parity",
}
Path("${EVIDENCE_FILE}").write_text(json.dumps(out, indent=2, sort_keys=True) + "\\n", encoding="utf-8")
PY
  echo "❌ rg (ripgrep) not found; cannot run PII leakage lint (fail closed)."
  exit 2
fi

echo "==> Regulated payload guardrails (PII leakage lint)"

# We intentionally key on "PII keyword near payload/evidence/log-like context" to avoid
# blocking docs or benign identifiers unrelated to payload surfaces.
CONTEXT_RE='(payload|outbox|evidence|attest|message|body|request|response|log|logger|audit)'
PII_KEY_RE='(nrc|msisdn|phone(_number)?|email|passport|national[_-]?id|date[_-]?of[_-]?birth|dob|first[_-]?name|last[_-]?name|full[_-]?name|address)'
PATTERN="(${CONTEXT_RE}).{0,80}\\b(${PII_KEY_RE})\\b|\\b(${PII_KEY_RE})\\b.{0,80}(${CONTEXT_RE})"

tmp_findings="$(mktemp)"
tmp_matches="$(mktemp)"
tmp_filtered="$(mktemp)"
trap 'rm -f "$tmp_findings" "$tmp_matches" "$tmp_filtered"' EXIT

rg_args=()
for root in $PII_LINT_ROOTS; do
  [[ -e "$root" ]] || continue
  rg_args+=("$root")
done

exclude_args=()
for g in $PII_LINT_EXCLUDE_GLOBS; do
  exclude_args+=("--glob" "!$g")
done

# Default behavior: include typical code/SQL; exclude docs/binaries.
# Then filter out allow-marked lines.
#
# Important: `rg` returns exit code 1 when no matches are found; that's not an error.
rg_rc=0
if rg -n --pcre2 --no-messages "${exclude_args[@]}" "$PATTERN" "${rg_args[@]}" >"$tmp_matches"; then
  rg_rc=0
else
  rg_rc=$?
  if [[ "$rg_rc" -ne 1 ]]; then
    echo "❌ rg failed unexpectedly (rc=$rg_rc)"
    exit 2
  fi
fi

rg_rc2=0
if rg -n --pcre2 --no-messages -v "symphony:pii_ok" "$tmp_matches" >"$tmp_filtered"; then
  rg_rc2=0
else
  rg_rc2=$?
  if [[ "$rg_rc2" -ne 1 ]]; then
    echo "❌ rg filter failed unexpectedly (rc=$rg_rc2)"
    exit 2
  fi
fi

head -n "$PII_LINT_MAX_FINDINGS" "$tmp_filtered" >"$tmp_findings"

findings_count="$(wc -l <"$tmp_findings" | tr -d ' ')"
ok=1
status="PASS"
errors=()

if [[ "$findings_count" -gt 0 ]]; then
  ok=0
  status="FAIL"
  errors+=("pii_keyword_near_regulated_context")
fi

export EVIDENCE_FILE
export FINDINGS_FILE="$tmp_findings"
export CHECK_ID GATE_ID INVARIANT_ID
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP
export PII_LINT_ROOTS PII_LINT_EXCLUDE_GLOBS
export OK="$ok"
export STATUS="$status"
export ERRORS="${errors[*]}"

python3 - <<'PY'
import json
import os
from pathlib import Path

evidence_file = os.environ["EVIDENCE_FILE"]
findings_path = os.environ.get("FINDINGS_FILE", "")

findings = []
for line in Path(findings_path).read_text(encoding="utf-8").splitlines():
    # format: file:line:match
    parts = line.split(":", 2)
    if len(parts) < 3:
        continue
    f, ln, rest = parts[0], parts[1], parts[2]
    findings.append({"file": f, "line": int(ln) if ln.isdigit() else None, "snippet": rest[:240]})

out = {
  "check_id": os.environ["CHECK_ID"],
  "gate_id": os.environ["GATE_ID"],
  "invariant_id": os.environ["INVARIANT_ID"],
  "timestamp_utc": os.environ.get("EVIDENCE_TS"),
  "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
  "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
  "status": os.environ["STATUS"],
  "ok": os.environ["OK"] == "1",
  "roots": os.environ["PII_LINT_ROOTS"].split(),
  "exclude_globs": os.environ["PII_LINT_EXCLUDE_GLOBS"].split(),
  "pattern_note": "PII keyword within 80 chars of regulated context keyword; allow via symphony:pii_ok marker",
  "errors": [e for e in os.environ.get("ERRORS", "").split() if e],
  "findings": findings,
}

Path(evidence_file).write_text(json.dumps(out, indent=2, sort_keys=True) + "\n", encoding="utf-8")
PY

if [[ "$ok" -ne 1 ]]; then
  echo "❌ PII leakage payload lint failed"
  echo "   Findings (top $PII_LINT_MAX_FINDINGS):"
  sed 's/^/ - /' "$tmp_findings" | head -n 20
  exit 1
fi

echo "✅ PII leakage payload lint passed"
