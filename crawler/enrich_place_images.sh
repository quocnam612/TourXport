#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

PYTHON_BIN="${PYTHON_BIN:-python}"
if [[ -x ".venv/bin/python" ]]; then
  PYTHON_BIN=".venv/bin/python"
fi

INPUT_FILE="${INPUT_FILE:-data/places/VIETNAM-2932.json}"
IMAGE_LIMIT="${IMAGE_LIMIT:-10}"
LANGUAGE="${LANGUAGE:-vi_VN}"
CURRENCY="${CURRENCY:-VND}"
REQUEST_DELAY="${REQUEST_DELAY:-1}"
MAX_PAGES="${MAX_PAGES:-1}"
KEY_STATE="${KEY_STATE:-data/.rapidapi_key_state.json}"
START_ID="${START_ID:-}"

if [[ $# -gt 0 && "$1" != --* ]]; then
  START_ID="$1"
  shift
fi

args=(
  scripts/enrich_place_images.py
  --input "$INPUT_FILE"
  --limit "$IMAGE_LIMIT"
  --lang "$LANGUAGE"
  --currency "$CURRENCY"
  --delay "$REQUEST_DELAY"
  --max-pages "$MAX_PAGES"
  --key-state "$KEY_STATE"
)

if [[ -n "$START_ID" ]]; then
  args+=(--start-id "$START_ID")
fi

args+=("$@")

exec "$PYTHON_BIN" "${args[@]}"
