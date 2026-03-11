#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

export RUN_DEMO_GATES=1
export RUN_PHASE1_GATES="${RUN_PHASE1_GATES:-1}"

exec scripts/dev/pre_ci.sh

