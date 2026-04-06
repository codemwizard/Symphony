#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SCRIPT="$ROOT/scripts/security/lint_dotnet_quality.sh"

if [[ ! -x "$SCRIPT" ]]; then
  echo "Required script missing or not executable: $SCRIPT" >&2
  exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

mkdir -p "$tmp_dir/scripts/lib" "$tmp_dir/evidence/phase1"
cp "$ROOT/scripts/lib/evidence.sh" "$tmp_dir/scripts/lib/evidence.sh"

set +e
SYMPHONY_ENV=development DOTNET_LINT_ROOT="$tmp_dir" "$SCRIPT"
rc=$?
set -e

if [[ "$rc" -ne 0 ]]; then
  echo "Expected pass when no dotnet projects exist; got rc=$rc" >&2
  exit 1
fi

python3 - <<'PY' "$tmp_dir/evidence/phase1/dotnet_lint_quality.json"
import json,sys
data=json.load(open(sys.argv[1],encoding="utf-8"))
if data.get("status") != "PASS":
    raise SystemExit("status not PASS")
if data.get("note") != "no_dotnet_projects_found":
    raise SystemExit("note mismatch")
if data.get("targets_count") != 0:
    raise SystemExit("targets_count mismatch")
print("ok")
PY

mkdir -p "$tmp_dir/project_timeout/scripts/lib" "$tmp_dir/project_timeout/src" "$tmp_dir/project_timeout/fakebin" "$tmp_dir/project_timeout/evidence/phase1"
cp "$ROOT/scripts/lib/evidence.sh" "$tmp_dir/project_timeout/scripts/lib/evidence.sh"
cat > "$tmp_dir/project_timeout/src/Test.csproj" <<'EOF'
<Project Sdk="Microsoft.NET.Sdk">
</Project>
EOF
cat > "$tmp_dir/project_timeout/fakebin/dotnet" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cmd="${1:-}"
case "$cmd" in
  restore)
    exit 0
    ;;
  format)
    sleep 2
    exit 0
    ;;
  build)
    echo "build should not run after format timeout" >&2
    exit 99
    ;;
  *)
    echo "unexpected dotnet command: $cmd" >&2
    exit 98
    ;;
esac
EOF
chmod +x "$tmp_dir/project_timeout/fakebin/dotnet"

set +e
SYMPHONY_ENV=development PATH="$tmp_dir/project_timeout/fakebin:$PATH" DOTNET_LINT_ROOT="$tmp_dir/project_timeout" DOTNET_LINT_TIMEOUT_SEC=1 "$SCRIPT"
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "Expected failure when fake dotnet format times out" >&2
  exit 1
fi

python3 - <<'PY' "$tmp_dir/project_timeout/evidence/phase1/dotnet_lint_quality.json"
import json,sys
data=json.load(open(sys.argv[1],encoding="utf-8"))
if data.get("status") != "FAIL":
    raise SystemExit("timeout status mismatch")
if data.get("note") != "dotnet_format_timeout":
    raise SystemExit("timeout note mismatch")
if data.get("processed_targets_count") != 1:
    raise SystemExit("timeout processed target count mismatch")
summary = data.get("command_summary", {})
if summary.get("timeout_markers") != 1:
    raise SystemExit("timeout marker missing")
if summary.get("build_invocations", 0) != 0:
    raise SystemExit("build invocation should be skipped after timeout")
print("timeout_ok")
PY

mkdir -p "$tmp_dir/project_envblocked/scripts/lib" "$tmp_dir/project_envblocked/src" "$tmp_dir/project_envblocked/fakebin" "$tmp_dir/project_envblocked/evidence/phase1"
cp "$ROOT/scripts/lib/evidence.sh" "$tmp_dir/project_envblocked/scripts/lib/evidence.sh"
cat > "$tmp_dir/project_envblocked/src/Test.csproj" <<'EOF'
<Project Sdk="Microsoft.NET.Sdk">
</Project>
EOF
cat > "$tmp_dir/project_envblocked/fakebin/dotnet" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cmd="${1:-}"
case "$cmd" in
  restore)
    exit 0
    ;;
  format)
    echo "Unhandled exception: System.Net.Sockets.SocketException (13): Permission denied /tmp/fake"
    echo "   at System.IO.Pipes.NamedPipeClientStream.TryConnect(Int32 _)"
    exit 1
    ;;
  build)
    echo "build should not run after env-blocked format" >&2
    exit 99
    ;;
  *)
    echo "unexpected dotnet command: $cmd" >&2
    exit 98
    ;;
esac
EOF
chmod +x "$tmp_dir/project_envblocked/fakebin/dotnet"

set +e
SYMPHONY_ENV=development PATH="$tmp_dir/project_envblocked/fakebin:$PATH" DOTNET_LINT_ROOT="$tmp_dir/project_envblocked" "$SCRIPT"
rc=$?
set -e

if [[ "$rc" -ne 0 ]]; then
  echo "Expected pass when fake dotnet format is environment-blocked" >&2
  exit 1
fi

python3 - <<'PY' "$tmp_dir/project_envblocked/evidence/phase1/dotnet_lint_quality.json"
import json,sys
data=json.load(open(sys.argv[1],encoding="utf-8"))
if data.get("status") != "PASS":
    raise SystemExit("env blocked status mismatch")
if data.get("note") != "dotnet_format_env_blocked":
    raise SystemExit("env blocked note mismatch")
if data.get("format_env_blocked") is not True:
    raise SystemExit("env blocked flag mismatch")
if data.get("processed_targets_count") != 1:
    raise SystemExit("env blocked processed target count mismatch")
summary = data.get("command_summary", {})
if summary.get("short_circuit_markers") != 1:
    raise SystemExit("env blocked short-circuit marker missing")
if summary.get("build_invocations", 0) != 0:
    raise SystemExit("build invocation should be skipped after env-blocked format")
print("env_blocked_ok")
PY

echo "test_lint_dotnet_quality.sh passed"
