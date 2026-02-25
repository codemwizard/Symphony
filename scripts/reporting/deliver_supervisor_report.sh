#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"

program_id="${1:-${PROGRAM_ID:-}}"
out_dir="${2:-${REPORT_OUT_DIR:-./evidence/phase1/reports}}"
signing_key="${SUPERVISOR_REPORT_SIGNING_KEY_PATH:-${3:-}}"

if [[ -z "${program_id}" ]]; then
  echo "Usage: deliver_supervisor_report.sh <program_id> [out_dir] [signing_key_path]" >&2
  exit 2
fi
if [[ -z "${signing_key}" || ! -f "${signing_key}" ]]; then
  echo "ERROR: signing key not found; set SUPERVISOR_REPORT_SIGNING_KEY_PATH or pass arg3" >&2
  exit 2
fi

mkdir -p "$out_dir"
report_path="$out_dir/supervisor_report_${program_id}.json"
sig_path="$report_path.sig"
pub_path="$report_path.pub.pem"

psql "$DATABASE_URL" -X -A -t -v ON_ERROR_STOP=1 \
  -c "WITH agg AS (SELECT m.entity_id AS program_id, e.event_type, count(*)::bigint AS event_count, min(e.observed_at) AS first_observed_at, max(e.observed_at) AS last_observed_at FROM public.member_device_events e JOIN public.members m ON m.member_id = e.member_id WHERE m.entity_id = '$program_id'::uuid GROUP BY m.entity_id, e.event_type) SELECT coalesce(json_agg(json_build_object('event_type', event_type, 'event_count', event_count, 'first_observed_at', first_observed_at, 'last_observed_at', last_observed_at) ORDER BY event_type), '[]'::json)::text FROM agg;" \
  > /tmp/supervisor_report_payload.json

payload="$(cat /tmp/supervisor_report_payload.json)"
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
git_sha="$(git rev-parse HEAD 2>/dev/null || echo UNKNOWN)"

cat > "$report_path" <<JSON
{
  "program_id": "$program_id",
  "generated_at_utc": "$ts",
  "generated_by": "scripts/reporting/deliver_supervisor_report.sh",
  "git_sha": "$git_sha",
  "aggregate": $payload
}
JSON

openssl dgst -sha256 -sign "$signing_key" -out "$sig_path" "$report_path"
openssl pkey -in "$signing_key" -pubout -out "$pub_path" >/dev/null 2>&1

echo "report_path:$report_path"
echo "signature_path:$sig_path"
echo "public_key_path:$pub_path"
