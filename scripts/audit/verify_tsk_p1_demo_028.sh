#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="TSK-P1-DEMO-028"
EVIDENCE_PATH="${1:-$ROOT_DIR/evidence/phase1/tsk_p1_demo_028_image_flow.json}"
LEDGER_DOCKERFILE="$ROOT_DIR/services/ledger-api/Dockerfile"
WORKER_DOCKERFILE="$ROOT_DIR/services/executor-worker/Dockerfile"
GUIDE="$ROOT_DIR/docs/operations/SYMPHONY_DEMO_DEPLOYMENT_GUIDE.md"
BUILD_SCRIPT="$ROOT_DIR/scripts/dev/build_demo_images.sh"

[[ -f "$LEDGER_DOCKERFILE" ]]
[[ -f "$WORKER_DOCKERFILE" ]]
[[ -f "$GUIDE" ]]
[[ -f "$BUILD_SCRIPT" ]]
command -v docker >/dev/null 2>&1

if rg -n 'echo .*container image built' "$LEDGER_DOCKERFILE" "$WORKER_DOCKERFILE" >/dev/null; then
  echo "placeholder image entrypoint still present" >&2
  exit 1
fi

rg -n 'host-based `\.NET publish`|host-based \.NET publish|supported demo deployment path is host-based publish|Kestrel' "$GUIDE" >/dev/null
rg -n 'scripts/dev/build_demo_images\.sh|docker build -f services/ledger-api/Dockerfile|docker build -f services/executor-worker/Dockerfile' "$GUIDE" >/dev/null

LEDGER_TAG="symphony/demo-ledger-api:tsk-p1-demo-028"
WORKER_TAG="symphony/demo-executor-worker:tsk-p1-demo-028"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

LEDGER_TAG="$LEDGER_TAG" WORKER_TAG="$WORKER_TAG" "$BUILD_SCRIPT" >/dev/null

LEDGER_ENTRYPOINT="$(docker image inspect "$LEDGER_TAG" --format '{{json .Config.Entrypoint}}')"
WORKER_ENTRYPOINT="$(docker image inspect "$WORKER_TAG" --format '{{json .Config.Entrypoint}}')"
LEDGER_HAS_UI="$(docker run --rm --entrypoint /bin/sh "$LEDGER_TAG" -lc 'test -f /app/src/supervisory-dashboard/index.html && echo yes')"

python3 - <<'PY' "$TASK_ID" "$EVIDENCE_PATH" "$LEDGER_TAG" "$WORKER_TAG" "$LEDGER_ENTRYPOINT" "$WORKER_ENTRYPOINT" "$LEDGER_HAS_UI"
import datetime, json, pathlib, subprocess, sys
task_id, evidence, ledger_tag, worker_tag, ledger_entrypoint, worker_entrypoint, ledger_has_ui = sys.argv[1:]
sha = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
ledger_id = subprocess.check_output(['docker', 'image', 'inspect', ledger_tag, '--format', '{{.Id}}'], text=True).strip()
worker_id = subprocess.check_output(['docker', 'image', 'inspect', worker_tag, '--format', '{{.Id}}'], text=True).strip()
payload = {
    'check_id': 'TSK-P1-DEMO-028-IMAGE-FLOW',
    'task_id': task_id,
    'timestamp_utc': datetime.datetime.now(datetime.timezone.utc).replace(microsecond=0).isoformat().replace('+00:00', 'Z'),
    'git_sha': sha,
    'status': 'PASS',
    'pass': True,
    'details': {
        'host_based_publish_supported_path': True,
        'ledger_api_image': {
            'tag': ledger_tag,
            'image_id': ledger_id,
            'entrypoint': json.loads(ledger_entrypoint),
            'bundles_supervisory_ui': ledger_has_ui.strip() == 'yes'
        },
        'executor_worker_image': {
            'tag': worker_tag,
            'image_id': worker_id,
            'entrypoint': json.loads(worker_entrypoint)
        },
        'build_commands': [
            f'LEDGER_TAG={ledger_tag} WORKER_TAG={worker_tag} scripts/dev/build_demo_images.sh'
        ]
    }
}
path = pathlib.Path(evidence)
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(payload, indent=2) + '\n', encoding='utf-8')
PY
