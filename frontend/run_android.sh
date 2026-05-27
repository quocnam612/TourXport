#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ -f "$ROOT_DIR/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$ROOT_DIR/.env"
  set +a
fi

API_BASE_URL="${API_BASE_URL:-http://10.0.2.2:3000}"

args=(
  run
  -d "${ANDROID_DEVICE_ID:-android}"
  --dart-define "API_BASE_URL=$API_BASE_URL"
)

if [[ -n "${GOOGLE_CLIENT_ID:-}" ]]; then
  args+=(--dart-define "GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID")
fi

flutter "${args[@]}"
