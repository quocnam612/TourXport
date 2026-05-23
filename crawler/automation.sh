#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

START_FILE="${1:-data/start.txt}"
LIMIT="${LIMIT:-30}"
PAGES="${PAGES:-30}"
LANGUAGE="${LANGUAGE:-vi_VN}"
CURRENCY="${CURRENCY:-VND}"
REQUEST_DELAY="${REQUEST_DELAY:-5}"

if [[ ! -f "$START_FILE" ]]; then
  echo "Start file not found: $START_FILE" >&2
  exit 1
fi

mkdir -p data/hotels

PYTHON_BIN="python"
if [[ -x ".venv/bin/python" ]]; then
  PYTHON_BIN=".venv/bin/python"
fi

region_name_for_geo_id() {
  local geo_id="$1"
  awk -v id="$geo_id" '
    $NF == id {
      name = ""
      for (i = 1; i < NF; i++) {
        if (name != "") name = name " "
        name = name $i
      }
      print name
      exit
    }
  ' data/regions.txt
}

while IFS= read -r geo_id || [[ -n "$geo_id" ]]; do
  geo_id="${geo_id%%#*}"
  geo_id="$(printf '%s' "$geo_id" | xargs)"

  if [[ -z "$geo_id" ]]; then
    continue
  fi

  region_name="$(region_name_for_geo_id "$geo_id")"
  if [[ -z "$region_name" ]]; then
    echo "Skipping $geo_id: region name not found in data/regions.txt"
    continue
  fi

  if find data/hotels -maxdepth 1 -type f -name "${region_name}Hotels-*.json" | grep -q .; then
    echo "Skipping $geo_id ($region_name): hotel file already exists"
    continue
  fi

  echo "Crawling hotels for geo_id=$geo_id ($region_name)"
  "$PYTHON_BIN" src/main.py \
    --task hotels_list \
    --query "$geo_id" \
    --limit "$LIMIT" \
    --pages "$PAGES" \
    --lang "$LANGUAGE" \
    --currency "$CURRENCY" \
    --format places \
    --region_name "${region_name}Hotels" \
    --clean_output true \
    --request_delay "$REQUEST_DELAY" \
    --fallback_search_query "$region_name"

  sleep "$REQUEST_DELAY"
done < "$START_FILE"
