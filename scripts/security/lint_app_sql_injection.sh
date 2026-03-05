#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

run_app_sql_injection_fixtures() {
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' RETURN

  cat >"$tmp_dir/ok.cs" <<'CS'
var cmd = "SELECT * FROM users WHERE id = @id";
CS
  cat >"$tmp_dir/bad.cs" <<'CS'
var sql = "SELECT * FROM users WHERE id = " + userId;
CS

  cat >"$tmp_dir/ok.py" <<'PY'
query = "SELECT * FROM users WHERE id = %s"
PY
  cat >"$tmp_dir/bad.py" <<'PY'
query = f"SELECT * FROM users WHERE id = {user_id}"
PY

  local hits=0
  if rg -n --no-heading -P '(?i)\b(select|insert|update|delete)\b.*\+' "$tmp_dir/bad.cs" >/dev/null; then
    hits=$((hits + 1))
  fi
  if rg -n --no-heading -P "(?i)f[\"'][^\"']*\\b(select|insert|update|delete)\\b[^\"']*\\{[^}]+\\}" "$tmp_dir/bad.py" >/dev/null; then
    hits=$((hits + 1))
  fi

  if [[ "$hits" -lt 2 ]]; then
    echo "Fixture verification failed: expected SQLi patterns were not detected"
    exit 1
  fi

  echo "Fixture verification passed"
}

if [[ "${1:-}" == "--fixtures" && "${2:-}" == "app_sql_injection" ]]; then
  run_app_sql_injection_fixtures
  exit 0
fi

echo "==> Application-Layer SQL Injection Lint (C# and Python)"

mapfile -d '' files < <(
  find . \
    \( -path './.git' -o -path './.venv' -o -path './node_modules' -o -path './bin' -o -path './obj' -o -path './_scratch' \
       -o -path '*/tests/*' -o -path '*/test/*' \) -prune -o \
    \( -name '*.cs' -o -name '*.py' \) -print0
)

cs_count=0
py_count=0
violations=0

for f in "${files[@]}"; do
  [[ -f "$f" ]] || continue
  case "$f" in
    *.cs) cs_count=$((cs_count + 1)) ;;
    *.py) py_count=$((py_count + 1)) ;;
  esac

done

echo "Found $cs_count C# files and $py_count Python files"

echo ""
echo "=== C# SQL Injection Patterns ==="
for f in "${files[@]}"; do
  [[ "$f" == *.cs ]] || continue
  if rg -n --no-heading -P '(?i)\b(select|insert|update|delete)\b.*\+' "$f" >/tmp/sqli_hits.txt; then
    echo "❌ C# SQLi pattern in $f"
    cat /tmp/sqli_hits.txt
    violations=$((violations + 1))
  fi

done

echo ""
echo "=== Python SQL Injection Patterns ==="
for f in "${files[@]}"; do
  [[ "$f" == *.py ]] || continue
  if rg -n --no-heading -P "(?i)(f[\"'][^\"']*\\b(select|insert|update|delete)\\b[^\"']*\\{[^}]+\\}|\\b(select|insert|update|delete)\\b.*\\+)" "$f" >/tmp/sqli_hits.txt; then
    echo "❌ Python SQLi pattern in $f"
    cat /tmp/sqli_hits.txt
    violations=$((violations + 1))
  fi

done

echo ""
echo "=== Summary ==="
echo "Files scanned: $cs_count C#, $py_count Python"
echo "Violations found: $violations"

if [[ "$violations" -gt 0 ]]; then
  echo "❌ SQL INJECTION BLOCK: Found $violations potential SQL injection vulnerabilities"
  exit 1
fi

echo "✅ No obvious SQL injection patterns detected"
