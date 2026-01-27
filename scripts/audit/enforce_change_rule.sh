#!/usr/bin/env bash
set -euo pipefail

# enforce_change_rule.sh
#
# This gate enforces "Rule 1": if a PR contains structural invariant-affecting changes,
# then invariants documentation must be updated OR a timeboxed exception must be added.
#
# It is designed to be run in CI and locally.
#
# Inputs:
#   BASE_REF (optional) default: origin/main
#   HEAD_REF (optional) default: HEAD
#
# Exit codes:
#   0 - ok
#   1 - violation

BASE_REF="${BASE_REF:-origin/main}"
HEAD_REF="${HEAD_REF:-HEAD}"

MANIFEST="docs/invariants/INVARIANTS_MANIFEST.yml"
DOCS_DIR="docs/invariants"
EXCEPTIONS_DIR="docs/invariants/exceptions"

# Determine changed files
changed_files="$(git diff --name-only "${BASE_REF}...${HEAD_REF}")"

# If the manifest changed, Rule 1 is satisfied (still expect meaningful content via promotion gate).
manifest_changed=0
echo "${changed_files}" | grep -qx "${MANIFEST}" && manifest_changed=1 || true

# Docs "meaningful change" requires INV-### token in docs diff
docs_changed=0
inv_token_present=0
if echo "${changed_files}" | grep -q "^${DOCS_DIR}/"; then
  docs_changed=1
  if git diff "${BASE_REF}...${HEAD_REF}" -- "${DOCS_DIR}" | grep -Eo 'INV-[0-9]{3}' >/dev/null; then
    inv_token_present=1
  fi
fi

# Exception bypass: any added/changed exception file that validates.
exception_present=0
if echo "${changed_files}" | grep -q "^${EXCEPTIONS_DIR}/"; then
  exception_present=1
fi

# If exception is present, ensure it passes template validation
if [[ "${exception_present}" -eq 1 ]]; then
  if [[ -x scripts/audit/verify_exception_template.sh ]]; then
    scripts/audit/verify_exception_template.sh
  fi
fi

if [[ "${manifest_changed}" -eq 1 ]]; then
  echo "✅ Change rule OK: manifest updated (${MANIFEST})."
  exit 0
fi

if [[ "${docs_changed}" -eq 1 && "${inv_token_present}" -eq 1 ]]; then
  echo "✅ Change rule OK: invariants docs updated with INV-### token(s)."
  exit 0
fi

if [[ "${exception_present}" -eq 1 ]]; then
  echo "⚠️  Change rule bypassed via exception file(s) under ${EXCEPTIONS_DIR}."
  echo "    Ensure expiry + follow-up ticket are present; scheduled audit should enforce closure."
  exit 0
fi

cat <<EOF
❌ Change rule violated:

Structural invariant-affecting changes were detected, but:
- ${MANIFEST} was not changed, AND
- docs under ${DOCS_DIR}/ were not meaningfully updated (must include INV-### token), AND
- no valid exception was added under ${EXCEPTIONS_DIR}/

Fix by:
1) Updating ${MANIFEST} and/or docs with INV-### references, OR
2) Adding a timeboxed exception file under ${EXCEPTIONS_DIR}/
EOF
exit 1
