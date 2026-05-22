#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

START_FILE="${1:-data/start.txt}"
LIMIT="${LIMIT:-30}"
PAGES="${PAGES:-30}"
LANGUAGE="${LANGUAGE:-vi_VN}"
CURRENCY="${CURRENCY:-VND}"

if [[ ! -f "$START_FILE" ]]; then
  echo "Start file not found: $START_FILE" >&2
  exit 1
fi

PYTHON_BIN="python"
if [[ -x ".venv/bin/python" ]]; then
  PYTHON_BIN=".venv/bin/python"
fi

region_name_for_geo_id() {
  local geo_id="$1"
  awk -v id="$geo_id" '
    $NF == id {
      name = ""
      for (i = 1; i < NF; i++) name = name $i
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
  if [[ -n "$region_name" ]]; then
    if find data -maxdepth 1 -type f -name "${region_name}-*.json" | grep -q .; then
      echo "Skipping $geo_id ($region_name): final file already exists"
      continue
    fi
  fi

  echo "Crawling attractions for geo_id=$geo_id"
  "$PYTHON_BIN" src/main.py \
    --task attractions_list \
    --query "$geo_id" \
    --limit "$LIMIT" \
    --pages "$PAGES" \
    --lang "$LANGUAGE" \
    --currency "$CURRENCY" \
    --format places \
    --clean_output true
done < "$START_FILE"
