#!/usr/bin/env bash
# Verifier for TSK-P3-CLEAN-006: Verify archived Phase 3 files excluded from task generation
# Acceptance criteria:
#   [ID tsk_p3_clean_006_work_01] Scan docs/PHASE3/archive/**
#   [ID tsk_p3_clean_006_work_02] Verify all files marked DO-NOT-INGEST
#   [ID tsk_p3_clean_006_work_03] Verify all files marked NON-CANONICAL

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ARCHIVE_DIR="$ROOT/docs/PHASE3/archive"
EVIDENCE_DIR="$ROOT/evidence/phase3"
EVIDENCE_PATH="$EVIDENCE_DIR/tsk_p3_clean_006.json"
TASK_ID="TSK-P3-CLEAN-006"
GIT_SHA="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo 'unknown')"
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
STATUS="PASS"
CHECKS="[]"

add_check() {
  local name="$1" result="$2" detail="${3:-}"
  CHECKS=$(python3 -c "
import json, sys
checks = json.loads(sys.argv[1])
checks.append({'name': sys.argv[2], 'result': sys.argv[3], 'detail': sys.argv[4]})
print(json.dumps(checks))
" "$CHECKS" "$name" "$result" "$detail")
  if [ "$result" = "FAIL" ]; then
    STATUS="FAIL"
  fi
}

# Find all markdown files in archive
FILES=$(find "$ARCHIVE_DIR" -type f -name "*.md" 2>/dev/null || echo "")

ALL_FILES_INGEST_MARKED=true
ALL_FILES_NON_CANONICAL=true
OBSERVED_PATHS="[]"
FAILED_INGEST=""
FAILED_CANONICAL=""

for file in $FILES; do
  rel_path=${file#"$ROOT/"}
  OBSERVED_PATHS=$(python3 -c "import json, sys; p=json.loads(sys.argv[1]); p.append(sys.argv[2]); print(json.dumps(p))" "$OBSERVED_PATHS" "$rel_path")
  
  if ! grep -q "DO-NOT-INGEST" "$file"; then
    ALL_FILES_INGEST_MARKED=false
    FAILED_INGEST="$FAILED_INGEST $rel_path"
  fi
  
  if ! grep -q "NON-CANONICAL" "$file"; then
    ALL_FILES_NON_CANONICAL=false
    FAILED_CANONICAL="$FAILED_CANONICAL $rel_path"
  fi
done

if [ "$ALL_FILES_INGEST_MARKED" = true ]; then
  add_check "all_files_marked_do_not_ingest" "PASS" "All files in archive contain DO-NOT-INGEST"
else
  add_check "all_files_marked_do_not_ingest" "FAIL" "Files missing DO-NOT-INGEST: $FAILED_INGEST"
fi

if [ "$ALL_FILES_NON_CANONICAL" = true ]; then
  add_check "all_files_marked_non_canonical" "PASS" "All files in archive contain NON-CANONICAL"
else
  add_check "all_files_marked_non_canonical" "FAIL" "Files missing NON-CANONICAL: $FAILED_CANONICAL"
fi

# Emit evidence
mkdir -p "$EVIDENCE_DIR"
python3 -c "
import json, sys
import hashlib
import os

root_dir = sys.argv[3]
observed_paths = json.loads(sys.argv[4])
hashes = {}

for path in observed_paths:
    full_path = os.path.join(root_dir, path)
    if os.path.exists(full_path):
        with open(full_path, 'rb') as f:
            hashes[path] = hashlib.sha256(f.read()).hexdigest()

evidence = {
    'task_id': sys.argv[1],
    'git_sha': sys.argv[2],
    'timestamp_utc': sys.argv[5],
    'status': sys.argv[6],
    'checks': json.loads(sys.argv[7]),
    'observed_paths': observed_paths,
    'observed_hashes': hashes
}
print(json.dumps(evidence, indent=2))
" "$TASK_ID" "$GIT_SHA" "$ROOT" "$OBSERVED_PATHS" "$TIMESTAMP" "$STATUS" "$CHECKS" > "$EVIDENCE_PATH"

echo "$STATUS"
if [ "$STATUS" = "FAIL" ]; then
  exit 1
fi
