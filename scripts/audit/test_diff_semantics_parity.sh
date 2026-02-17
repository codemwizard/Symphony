#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/scripts/audit/lib/parity_critical_scripts.sh"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

git -C "$tmp_dir" init -q
git -C "$tmp_dir" config user.email "ci@example.com"
git -C "$tmp_dir" config user.name "CI"

cat > "$tmp_dir/file.txt" <<'EOF'
baseline
EOF
git -C "$tmp_dir" add file.txt
git -C "$tmp_dir" commit -q -m "baseline"
git -C "$tmp_dir" branch -M main

git -C "$tmp_dir" checkout -q -b feature
cat > "$tmp_dir/file.txt" <<'EOF'
baseline
committed-change
EOF
git -C "$tmp_dir" add file.txt
git -C "$tmp_dir" commit -q -m "committed change"

cat > "$tmp_dir/staged_only.txt" <<'EOF'
staged-only
EOF
git -C "$tmp_dir" add staged_only.txt

cat > "$tmp_dir/worktree_only.txt" <<'EOF'
worktree-only
EOF

changed="$(BASE_REF="main" HEAD_REF="HEAD" bash -lc "source '$ROOT_DIR/scripts/lib/git_diff_range_only.sh'; cd '$tmp_dir'; git_changed_files_range \"\$BASE_REF\" \"\$HEAD_REF\"")"

if echo "$changed" | grep -q '^staged_only.txt$'; then
  echo "❌ staged_only.txt leaked into range-only changed files"
  exit 1
fi
if echo "$changed" | grep -q '^worktree_only.txt$'; then
  echo "❌ worktree_only.txt leaked into range-only changed files"
  exit 1
fi
if ! echo "$changed" | grep -q '^file.txt$'; then
  echo "❌ committed file.txt missing from range-only changed files"
  exit 1
fi

if parity_critical_scripts | grep -q 'preflight_structural_staged.sh'; then
  echo "❌ staged preflight script is still marked parity-critical"
  exit 1
fi

echo "Diff semantics parity fixtures passed."
