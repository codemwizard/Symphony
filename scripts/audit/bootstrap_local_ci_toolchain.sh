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
OFFLINE_MODE="${SYMPHONY_OFFLINE:-0}"
VENDORED_RG_PATH="${SYMPHONY_VENDORED_RG_PATH:-}"

mkdir -p "$BIN_DIR"

# Keep semgrep runtime paths repo-local to avoid host permission drift.
SEMGREP_RUNTIME_DIR="${SYMPHONY_SEMGREP_RUNTIME_DIR:-$ROOT_DIR/.cache/semgrep}"
mkdir -p "$SEMGREP_RUNTIME_DIR"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$ROOT_DIR/.cache/xdg/config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$ROOT_DIR/.cache/xdg/cache}"
mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
export SEMGREP_SETTINGS_FILE="${SEMGREP_SETTINGS_FILE:-$SEMGREP_RUNTIME_DIR/settings.yml}"
if [[ ! -f "$SEMGREP_SETTINGS_FILE" ]]; then
  printf '{}\n' > "$SEMGREP_SETTINGS_FILE"
fi

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
  if [[ "$OFFLINE_MODE" == "1" ]]; then
    if [[ -n "$VENDORED_RG_PATH" && -x "$VENDORED_RG_PATH" ]]; then
      install -m 0755 "$VENDORED_RG_PATH" "$BIN_DIR/rg"
      need_rg=0
    else
      echo "ERROR: offline mode enabled (SYMPHONY_OFFLINE=1) and pinned rg ${RIPGREP_VERSION} is not available." >&2
      echo "Action: provide SYMPHONY_VENDORED_RG_PATH to an executable rg binary, or pre-install ${BIN_DIR}/rg at version ${RIPGREP_VERSION}." >&2
      exit 1
    fi
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
  semgrep_version="$("$VENV_DIR/bin/python3" -c 'from importlib import metadata as m; print(m.version("semgrep"))' || echo "UNAVAILABLE")"
  echo "  semgrep: ${semgrep_version}"
fi
