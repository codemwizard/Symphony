#!/usr/bin/env bash
# ============================================================
# lint_search_path.sh
# Fail if any SECURITY DEFINER function lacks "SET search_path"
# (or does not include pg_catalog and public).
#
# Usage:
#   scripts/db/lint_search_path.sh
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MIG_DIR="$REPO_ROOT/schema/migrations"

if [[ ! -d "$MIG_DIR" ]]; then
  echo "lint_search_path: migrations dir not found: $MIG_DIR" >&2
  exit 2
fi

fail=0

# AWK state machine: capture function header from CREATE FUNCTION until AS $...$
awk_program='
function reset_state() {
  in_header=0
  secdef=0
  has_set=0
  has_pg_catalog=0
  has_public=0
  func_name=""
}
function maybe_fail(file) {
  if (secdef == 1) {
    if (has_set == 0) {
      printf("FAIL: %s: SECURITY DEFINER function missing SET search_path: %s\n", file, func_name) > "/dev/stderr"
      exit_code=1
    } else if (has_pg_catalog == 0 || has_public == 0) {
      printf("FAIL: %s: SET search_path must include pg_catalog and public: %s\n", file, func_name) > "/dev/stderr"
      exit_code=1
    }
  }
}
BEGIN { exit_code=0; reset_state() }

{
  line=$0

  # Start of a function definition
  if (match(line, /^[[:space:]]*CREATE([[:space:]]+OR[[:space:]]+REPLACE)?[[:space:]]+FUNCTION[[:space:]]+/)) {
    # If we were already tracking a header, finalize it before starting new one
    if (in_header==1) {
      maybe_fail(FILENAME)
      reset_state()
    }

    in_header=1
    func_name=line
    sub(/^[[:space:]]*CREATE([[:space:]]+OR[[:space:]]+REPLACE)?[[:space:]]+FUNCTION[[:space:]]+/, "", func_name)
    sub(/\(.*/, "", func_name)
    gsub(/[[:space:]]+$/, "", func_name)
  }

  if (in_header==1) {
    if (line ~ /SECURITY[[:space:]]+DEFINER/) secdef=1

    if (line ~ /SET[[:space:]]+search_path[[:space:]]*=/) {
      has_set=1
      if (line ~ /pg_catalog/) has_pg_catalog=1
      if (line ~ /public/) has_public=1
    }

    # End of function header (AS $$ / AS $tag$ / AS $$)
    if (line ~ /^[[:space:]]*AS[[:space:]]+\$.*\$/) {
      maybe_fail(FILENAME)
      reset_state()
    }
  }
}
END {
  # If file ended mid-header, finalize check
  if (in_header==1) maybe_fail(FILENAME)
  exit exit_code
}
'

# Run across all migration SQL files
while IFS= read -r -d '' f; do
  if ! awk "$awk_program" "$f"; then
    fail=1
  fi
done < <(find "$MIG_DIR" -maxdepth 1 -type f -name '*.sql' -print0 | sort -z)

if [[ "$fail" -ne 0 ]]; then
  echo "lint_search_path: FAILED" >&2
  exit 1
fi

echo "lint_search_path: OK"
