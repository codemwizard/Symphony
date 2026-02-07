#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

# Goal: make local pre-ci match CI toolchain pins.
# CI installs pinned PyPI deps and a pinned rg binary. Locally we do the same, repo-scoped.

source "$ROOT_DIR/scripts/audit/ci_toolchain_versions.env"

VENV_DIR="${SYMPHONY_VENV_DIR:-$ROOT_DIR/.venv}"
TOOLCHAIN_DIR="${SYMPHONY_TOOLCHAIN_DIR:-$ROOT_DIR/.toolchain}"
BIN_DIR="$TOOLCHAIN_DIR/bin"

mkdir -p "$BIN_DIR"

if [[ ! -x "$VENV_DIR/bin/python3" ]]; then
  python3 -m venv "$VENV_DIR"
fi

"$VENV_DIR/bin/python3" -m pip install --upgrade pip >/dev/null
"$VENV_DIR/bin/python3" -m pip install \
  "pyyaml==${PYYAML_VERSION}" \
  "jsonschema==${JSONSCHEMA_VERSION}" \
  "semgrep==${SEMGREP_VERSION}" \
  pytest >/dev/null

# Install pinned rg binary into repo toolchain bin if missing/mismatched.
need_rg=1
if [[ -x "$BIN_DIR/rg" ]]; then
  have="$("$BIN_DIR/rg" --version | head -n1 | awk '{print $2}')"
  if [[ "$have" == "$RIPGREP_VERSION" ]]; then
    need_rg=0
  fi
fi

if [[ "$need_rg" == "1" ]]; then
  tmp="/tmp/ripgrep-${RIPGREP_VERSION}.tgz"
  dir="/tmp/ripgrep-${RIPGREP_VERSION}-x86_64-unknown-linux-musl"
  rm -rf "$dir"
  curl -sSL -o "$tmp" \
    "https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/ripgrep-${RIPGREP_VERSION}-x86_64-unknown-linux-musl.tar.gz"
  tar -xzf "$tmp" -C /tmp
  install -m 0755 "$dir/rg" "$BIN_DIR/rg"
fi

# Expose semgrep in the repo-local toolchain bin so PATH wiring matches CI intent.
if [[ -x "$VENV_DIR/bin/semgrep" ]]; then
  ln -sf "$VENV_DIR/bin/semgrep" "$BIN_DIR/semgrep"
fi

echo "Local toolchain bootstrapped:"
echo "  python: $VENV_DIR/bin/python3"
echo "  rg: $("$BIN_DIR/rg" --version | head -n1)"
if [[ -x "$BIN_DIR/semgrep" ]]; then
  echo "  semgrep: $("$BIN_DIR/semgrep" --version | tr -d '\n')"
fi
