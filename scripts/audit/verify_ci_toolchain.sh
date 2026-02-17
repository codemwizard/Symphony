#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

source "$ROOT_DIR/scripts/lib/evidence.sh"
EVIDENCE_TS="$(evidence_now_utc)"
EVIDENCE_GIT_SHA="$(git_sha)"
EVIDENCE_SCHEMA_FP="$(schema_fingerprint)"
export EVIDENCE_TS EVIDENCE_GIT_SHA EVIDENCE_SCHEMA_FP

# Load pinned versions (defaults if file missing)
if [[ -f "$ROOT_DIR/scripts/audit/ci_toolchain_versions.env" ]]; then
  # shellcheck disable=SC1090
  source "$ROOT_DIR/scripts/audit/ci_toolchain_versions.env"
fi

EXPECTED_PYYAML_VERSION="${PYYAML_VERSION:-6.0.1}"
EXPECTED_JSONSCHEMA_VERSION="${JSONSCHEMA_VERSION:-4.23.0}"
EXPECTED_RIPGREP_VERSION="${RIPGREP_VERSION:-14.1.0}"
EXPECTED_SEMGREP_VERSION="${SEMGREP_VERSION:-}"

# Keep semgrep runtime paths repo-local to avoid host permission drift.
SEMGREP_RUNTIME_DIR="${SYMPHONY_SEMGREP_RUNTIME_DIR:-$ROOT_DIR/.cache/semgrep}"
mkdir -p "$SEMGREP_RUNTIME_DIR"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$ROOT_DIR/.cache/xdg/config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$ROOT_DIR/.cache/xdg/cache}"
mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
export SEMGREP_SETTINGS_FILE="${SEMGREP_SETTINGS_FILE:-$SEMGREP_RUNTIME_DIR/settings.yml}"
if [[ ! -f "$SEMGREP_SETTINGS_FILE" ]]; then
  printf '{}\n' > "$SEMGREP_SETTINGS_FILE"
fi

# Prefer repo-local venv python when present (for local/CI parity).
PYTHON_BIN="python3"
if [[ -x "$ROOT_DIR/.venv/bin/python3" ]]; then
  PYTHON_BIN="$ROOT_DIR/.venv/bin/python3"
fi
export PYTHON_BIN

# Prefer repo-local pinned rg binary when present.
if [[ -x "$ROOT_DIR/.toolchain/bin/rg" ]]; then
  export PATH="$ROOT_DIR/.toolchain/bin:$PATH"
fi

rg_present=0
rg_version=""
if command -v rg >/dev/null 2>&1; then
  rg_present=1
  rg_version="$(rg --version | head -n1 | awk '{print $2}')"
fi

semgrep_present=0
semgrep_version=""
if command -v semgrep >/dev/null 2>&1; then
  semgrep_present=1
  semgrep_version="$("$PYTHON_BIN" -c 'from importlib import metadata as m; print(m.version("semgrep"))' || echo "")"
fi

export EXPECTED_PYYAML_VERSION EXPECTED_JSONSCHEMA_VERSION EXPECTED_RIPGREP_VERSION
export RG_PRESENT="$rg_present" RG_VERSION="$rg_version"
export EXPECTED_SEMGREP_VERSION SEMGREP_PRESENT="$semgrep_present" SEMGREP_VERSION_ACTUAL="$semgrep_version"

EVIDENCE_FILE="$ROOT_DIR/evidence/phase0/ci_toolchain.json"
export EVIDENCE_FILE
mkdir -p "$(dirname "$EVIDENCE_FILE")"

"$PYTHON_BIN" - <<'PY'
import json
import os
from pathlib import Path

expected_pyyaml = os.environ.get("EXPECTED_PYYAML_VERSION", "")
expected_jsonschema = os.environ.get("EXPECTED_JSONSCHEMA_VERSION", "")
expected_rg = os.environ.get("EXPECTED_RIPGREP_VERSION", "")
expected_semgrep = os.environ.get("EXPECTED_SEMGREP_VERSION", "")

rg_present = os.environ.get("RG_PRESENT", "0") == "1"
rg_version = os.environ.get("RG_VERSION") or ""
semgrep_present = os.environ.get("SEMGREP_PRESENT", "0") == "1"
semgrep_version = os.environ.get("SEMGREP_VERSION_ACTUAL") or ""

missing = []
mismatched = []
errors = []

# Check ripgrep
if not rg_present:
    missing.append("ripgrep")
else:
    if expected_rg and rg_version and rg_version != expected_rg:
        mismatched.append(f"ripgrep:{rg_version}!={expected_rg}")

# Check PyYAML + jsonschema
actual_pyyaml = ""
actual_jsonschema = ""

try:
    import yaml  # type: ignore
    actual_pyyaml = getattr(yaml, "__version__", "UNKNOWN")
except Exception as e:
    missing.append("pyyaml")
    errors.append(f"pyyaml:{e}")

try:
    from importlib import metadata as _metadata  # Python 3.8+
    actual_jsonschema = _metadata.version("jsonschema")
except Exception as e:
    # fallback: try importing and reading __version__
    try:
        import jsonschema  # type: ignore
        actual_jsonschema = getattr(jsonschema, "__version__", "UNKNOWN")
    except Exception as e2:
        missing.append("jsonschema")
        errors.append(f"jsonschema:{e2}")

if actual_pyyaml and expected_pyyaml and actual_pyyaml != expected_pyyaml:
    mismatched.append(f"pyyaml:{actual_pyyaml}!={expected_pyyaml}")

if actual_jsonschema and expected_jsonschema and actual_jsonschema != expected_jsonschema:
    mismatched.append(f"jsonschema:{actual_jsonschema}!={expected_jsonschema}")

# Check Semgrep (CI parity). Enforce when a pinned version is declared.
if expected_semgrep:
    if not semgrep_present:
        missing.append("semgrep")
    else:
        if semgrep_version and semgrep_version != expected_semgrep:
            mismatched.append(f"semgrep:{semgrep_version}!={expected_semgrep}")

status = "PASS"
if missing or mismatched or errors:
    status = "FAIL"

out = {
    "check_id": "CI-TOOLCHAIN",
    "timestamp_utc": os.environ.get("EVIDENCE_TS"),
    "git_sha": os.environ.get("EVIDENCE_GIT_SHA"),
    "schema_fingerprint": os.environ.get("EVIDENCE_SCHEMA_FP"),
    "status": status,
    "expected": {
        "ripgrep": expected_rg,
        "pyyaml": expected_pyyaml,
        "jsonschema": expected_jsonschema,
        "semgrep": expected_semgrep or None,
    },
    "actual": {
        "ripgrep": rg_version if rg_present else None,
        "pyyaml": actual_pyyaml or None,
        "jsonschema": actual_jsonschema or None,
        "semgrep": semgrep_version if semgrep_present else None,
    },
    "missing": missing,
    "mismatched": mismatched,
    "errors": errors,
}

Path(os.environ["EVIDENCE_FILE"]).write_text(json.dumps(out, indent=2) + "\n")

if status != "PASS":
    print("CI toolchain verification failed")
    if missing:
        print(f"Missing: {', '.join(missing)}")
    if mismatched:
        print(f"Version mismatch: {', '.join(mismatched)}")
    if errors:
        print(f"Errors: {', '.join(errors)}")
    raise SystemExit(1)

print(f"CI toolchain verification passed. Evidence: {os.environ['EVIDENCE_FILE']}")
PY
