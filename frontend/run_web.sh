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

WEB_HOST="${WEB_HOST:-localhost}"
WEB_PORT="${WEB_PORT:-7357}"
API_BASE_URL="${API_BASE_URL:-http://localhost:3000}"
AI_BASE_URL="${AI_BASE_URL:-http://localhost:8000}"

args=(
  run
  -d chrome
  --web-hostname "$WEB_HOST"
  --web-port "$WEB_PORT"
  --dart-define "API_BASE_URL=$API_BASE_URL"
  --dart-define "AI_BASE_URL=$AI_BASE_URL"
)

if [[ -n "${GOOGLE_CLIENT_ID:-}" ]]; then
  args+=(--dart-define "GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID")
fi

if [[ -n "${DISCORD_CLIENT_ID:-}" ]]; then
  args+=(--dart-define "DISCORD_CLIENT_ID=$DISCORD_CLIENT_ID")
fi

flutter "${args[@]}"
