#!/usr/bin/env bash
set -euo pipefail

# LAYER 1: .githooks/pre-push
# TARGET: .githooks/pre-push
# STATUS: Already written to repo. This is the canonical snapshot.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$CURRENT_BRANCH" == "main" ]]; then
  echo "❌ BLOCKED: You are on 'main'. Work must occur on feature branches." >&2
  exit 1
fi

while read -r LOCAL_REF LOCAL_SHA REMOTE_REF REMOTE_SHA || [[ -n "${REMOTE_REF:-}" ]]; do
  if [[ "${REMOTE_REF:-}" == "refs/heads/main" ]]; then
    echo "❌ BLOCKED: Direct push to 'main' is forbidden." >&2
    echo "   Attempted: $LOCAL_REF → $REMOTE_REF" >&2
    echo "   Open a PR from your feature branch instead." >&2
    exit 1
  fi
done

if [[ "${GIT_PUSH_OPTION_COUNT:-0}" -gt 0 ]]; then
  for ((i=0; i<GIT_PUSH_OPTION_COUNT; i++)); do
    opt="$(eval echo "\$GIT_PUSH_OPTION_$i")"
    if [[ "$opt" == "force" || "$opt" == "force-with-lease" ]]; then
      echo "❌ BLOCKED: Force push is not permitted." >&2
      exit 1
    fi
  done
fi

bash "$ROOT/scripts/dev/pre_ci.sh"
