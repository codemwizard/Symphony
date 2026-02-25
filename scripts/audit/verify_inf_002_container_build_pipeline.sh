#!/usr/bin/env bash
set -euo pipefail

TASK_ID="TSK-P1-INF-002"
EVIDENCE_PATH="evidence/phase1/inf_002_container_build_pipeline.json"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --evidence)
      EVIDENCE_PATH="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required" >&2
  exit 1
fi

declare -a NAMES=(
  "ledger-api"
  "executor-worker"
  "db-migration-job"
)

declare -a CONTEXTS=(
  "services/ledger-api"
  "services/executor-worker"
  "infra/db-migration-job"
)

declare -a DOCKERFILES=(
  "services/ledger-api/Dockerfile"
  "services/executor-worker/Dockerfile"
  "infra/db-migration-job/Dockerfile"
)

declare -a TAGS=(
  "symphony/phase1-ledger-api:inf002"
  "symphony/phase1-executor-worker:inf002"
  "symphony/phase1-db-migration-job:inf002"
)

errors=0
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
checks_file="$tmpdir/build_checks.ndjson"

for i in "${!NAMES[@]}"; do
  name="${NAMES[$i]}"
  context="${CONTEXTS[$i]}"
  dockerfile="${DOCKERFILES[$i]}"
  tag="${TAGS[$i]}"

  if [[ ! -f "$dockerfile" ]]; then
    echo "missing Dockerfile: $dockerfile" >&2
    errors=$((errors+1))
    continue
  fi

  from_line="$(grep -E '^FROM ' "$dockerfile" | head -n1 || true)"
  if [[ -z "$from_line" ]]; then
    echo "missing FROM in $dockerfile" >&2
    errors=$((errors+1))
    continue
  fi

  base_image="${from_line#FROM }"
  base_image="${base_image%% *}"
  digest_pinned=false
  if [[ "$base_image" == *"@sha256:"* ]]; then
    digest_pinned=true
  else
    errors=$((errors+1))
    echo "base image is not digest-pinned in $dockerfile: $base_image" >&2
  fi

  non_root=false
  if grep -Eq '^USER\s+[^[:space:]]+' "$dockerfile"; then
    non_root=true
  else
    errors=$((errors+1))
    echo "missing USER directive in $dockerfile" >&2
  fi

  docker build -f "$dockerfile" -t "$tag" "$context" >/dev/null
  first_id="$(docker image inspect "$tag" --format '{{.Id}}')"

  docker build -f "$dockerfile" -t "$tag" "$context" >/dev/null
  second_id="$(docker image inspect "$tag" --format '{{.Id}}')"

  deterministic=false
  if [[ "$first_id" == "$second_id" ]]; then
    deterministic=true
  else
    errors=$((errors+1))
    echo "nondeterministic build detected for $name" >&2
  fi

  base_digest=""
  if [[ "$base_image" == *"@sha256:"* ]]; then
    base_digest="sha256:${base_image##*@sha256:}"
  fi

  printf '{"service":"%s","dockerfile":"%s","image":"%s","image_digest":"%s","base_image":"%s","base_image_digest":"%s","digest_pinned":%s,"non_root":%s,"deterministic":%s}\n' \
    "$name" "$dockerfile" "$tag" "$first_id" "$base_image" "$base_digest" "$digest_pinned" "$non_root" "$deterministic" >> "$checks_file"
done

status="PASS"
if (( errors > 0 )); then
  status="FAIL"
fi

mkdir -p "$(dirname "$EVIDENCE_PATH")"
python3 - <<PY
import datetime, json, pathlib, subprocess
checks=[]
for line in pathlib.Path("$checks_file").read_text(encoding="utf-8").splitlines():
    line=line.strip()
    if line:
        checks.append(json.loads(line))

try:
    git_sha=subprocess.check_output(["git","rev-parse","HEAD"], text=True).strip()
except Exception:
    git_sha="UNKNOWN"

out={
  "check_id":"$TASK_ID",
  "task_id":"$TASK_ID",
  "status":"$status",
  "pass":"$status"=="PASS",
  "timestamp_utc":datetime.datetime.now(datetime.timezone.utc).replace(microsecond=0).isoformat().replace('+00:00','Z'),
  "git_sha":git_sha,
  "details":{
    "build_order":["ledger-api","executor-worker","db-migration-job"],
    "determinism_policy":"same source -> same image digest",
    "pinned_base_required":True,
    "non_root_required":True
  },
  "images":checks
}
path=pathlib.Path("$EVIDENCE_PATH")
path.write_text(json.dumps(out, indent=2)+"\n", encoding="utf-8")
print(f"Evidence written: {path}")
if out["status"]!="PASS":
    raise SystemExit(1)
PY
