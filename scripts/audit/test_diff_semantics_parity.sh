#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/scripts/audit/lib/parity_critical_scripts.sh"

# This fixture must run inside its own disposable repository even when callers
# export git plumbing variables (for example from hooks or linked worktrees).
GIT_ENV_UNSET=(
  -u GIT_DIR
  -u GIT_WORK_TREE
  -u GIT_INDEX_FILE
  -u GIT_COMMON_DIR
  -u GIT_OBJECT_DIRECTORY
  -u GIT_ALTERNATE_OBJECT_DIRECTORIES
  -u GIT_PREFIX
)

safe_git() {
  env "${GIT_ENV_UNSET[@]}" git "$@"
}

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

safe_git -C "$tmp_dir" init -q
safe_git -C "$tmp_dir" config user.email "ci@example.com"
safe_git -C "$tmp_dir" config user.name "CI"

tmp_git_dir="$(safe_git -C "$tmp_dir" rev-parse --absolute-git-dir)"
tmp_top="$(safe_git -C "$tmp_dir" rev-parse --show-toplevel)"
if [[ "$tmp_top" != "$tmp_dir" ]]; then
  echo "❌ parity fixture escaped disposable repo: expected top-level $tmp_dir, got $tmp_top" >&2
  exit 1
fi
if [[ "$tmp_git_dir" != "$tmp_dir/.git" ]]; then
  echo "❌ parity fixture escaped disposable repo: expected git dir $tmp_dir/.git, got $tmp_git_dir" >&2
  exit 1
fi

cat > "$tmp_dir/file.txt" <<'EOF'
baseline
EOF
safe_git -C "$tmp_dir" add file.txt
safe_git -C "$tmp_dir" commit -q -m "baseline"
safe_git -C "$tmp_dir" branch -M main

safe_git -C "$tmp_dir" checkout -q -b feature
cat > "$tmp_dir/file.txt" <<'EOF'
baseline
committed-change
EOF
safe_git -C "$tmp_dir" add file.txt
safe_git -C "$tmp_dir" commit -q -m "committed change"

cat > "$tmp_dir/staged_only.txt" <<'EOF'
staged-only
EOF
safe_git -C "$tmp_dir" add staged_only.txt

cat > "$tmp_dir/worktree_only.txt" <<'EOF'
worktree-only
EOF

changed="$(env "${GIT_ENV_UNSET[@]}" BASE_REF="main" HEAD_REF="HEAD" bash -lc "source '$ROOT_DIR/scripts/lib/git_diff_range_only.sh'; cd '$tmp_dir'; git_changed_files_range \"\$BASE_REF\" \"\$HEAD_REF\"")"

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
