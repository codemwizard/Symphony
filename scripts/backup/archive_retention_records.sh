#!/usr/bin/env bash
set -euo pipefail

SOURCE_FILE="${SOURCE_FILE:-}"
OUT_DIR="${OUT_DIR:-}"
LOOKBACK_DAYS="${LOOKBACK_DAYS:-365}"
RUN_LOG="${RUN_LOG:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source) SOURCE_FILE="$2"; shift 2 ;;
    --out-dir) OUT_DIR="$2"; shift 2 ;;
    --lookback-days) LOOKBACK_DAYS="$2"; shift 2 ;;
    --run-log) RUN_LOG="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

[[ -n "$SOURCE_FILE" && -f "$SOURCE_FILE" ]] || { echo "missing_source_file" >&2; exit 1; }
[[ -n "$OUT_DIR" ]] || { echo "missing_out_dir" >&2; exit 1; }
[[ -n "$RUN_LOG" ]] || { echo "missing_run_log" >&2; exit 1; }

mkdir -p "$OUT_DIR" "$(dirname "$RUN_LOG")"

archive_run_id="arch_$(date -u +%Y%m%dT%H%M%SZ)_$RANDOM"
archive_file="$OUT_DIR/${archive_run_id}.jsonl"
signature_file="$archive_file.sha256"

python3 - <<'PY' "$SOURCE_FILE" "$archive_file" "$LOOKBACK_DAYS"
import json
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

source, out, lookback_days = sys.argv[1:]
cutoff = datetime.now(timezone.utc) - timedelta(days=int(lookback_days))
allowed = {"FIC_AML_CUSTOMER_ID", "BFSA_FINANCIAL"}
written = 0

with Path(source).open("r", encoding="utf-8") as src, Path(out).open("w", encoding="utf-8") as dst:
    for line in src:
        line = line.strip()
        if not line:
            continue
        row = json.loads(line)
        rc = row.get("retention_class")
        anchored = row.get("anchored_at")
        if rc not in allowed:
            continue
        try:
            anchored_dt = datetime.fromisoformat(anchored.replace("Z", "+00:00"))
        except Exception:
            continue
        if anchored_dt <= cutoff:
            dst.write(json.dumps(row, separators=(",", ":")) + "\n")
            written += 1
PY

records_archived=$(wc -l < "$archive_file" | tr -d ' ')
sha256sum "$archive_file" | awk '{print $1}' > "$signature_file"

python3 - <<'PY' "$RUN_LOG" "$archive_run_id" "$archive_file" "$signature_file" "$records_archived"
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

run_log, run_id, archive_file, sig_file, records = sys.argv[1:]
entry = {
  "archive_run_id": run_id,
  "archive_file": archive_file,
  "signature_file": sig_file,
  "records_archived": int(records),
  "timestamp_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
}
Path(run_log).parent.mkdir(parents=True, exist_ok=True)
with Path(run_log).open("a", encoding="utf-8") as f:
  f.write(json.dumps(entry) + "\n")
print(json.dumps(entry))
PY
