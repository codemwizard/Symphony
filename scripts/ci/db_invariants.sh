#!/usr/bin/env bash
set -euo pipefail

psql "$DATABASE_URL" -f scripts/db/test_invariants.sql
