#!/usr/bin/env bash
set -euo pipefail

ARCHIVE_FILE="${ARCHIVE_FILE:-}"
SIGNATURE_FILE="${SIGNATURE_FILE:-}"
RESTORE_FILE="${RESTORE_FILE:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --archive-file) ARCHIVE_FILE="$2"; shift 2 ;;
    --signature-file) SIGNATURE_FILE="$2"; shift 2 ;;
    --restore-file) RESTORE_FILE="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

[[ -f "$ARCHIVE_FILE" ]] || { echo "missing_archive_file" >&2; exit 1; }
[[ -f "$SIGNATURE_FILE" ]] || { echo "missing_signature_file" >&2; exit 1; }
[[ -n "$RESTORE_FILE" ]] || { echo "missing_restore_file" >&2; exit 1; }

expected="$(cat "$SIGNATURE_FILE" | tr -d '[:space:]')"
actual="$(sha256sum "$ARCHIVE_FILE" | awk '{print $1}')"
[[ "$expected" == "$actual" ]] || { echo "signature_mismatch" >&2; exit 1; }

mkdir -p "$(dirname "$RESTORE_FILE")"
cp "$ARCHIVE_FILE" "$RESTORE_FILE"

echo "signature_verified=true"
echo "restore_file=$RESTORE_FILE"
