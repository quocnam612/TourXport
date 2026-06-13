#!/usr/bin/env python3
import argparse
import hashlib
import json
import os
import re
import shutil
import sys
import time
from datetime import datetime
from pathlib import Path

import requests
from dotenv import load_dotenv


CRAWLER_DIR = Path(__file__).resolve().parents[1]
REPO_DIR = CRAWLER_DIR.parent
DEFAULT_INPUT = CRAWLER_DIR / "data" / "places" / "VIETNAM-2932.json"
DEFAULT_KEY_STATE = CRAWLER_DIR / "data" / ".rapidapi_key_state.json"
RAPIDAPI_HOST = "travel-advisor.p.rapidapi.com"


class ApiUsageLimitError(Exception):
    pass


class ApiRequestError(Exception):
    pass


def parse_args():
    parser = argparse.ArgumentParser(
        description="Add TripAdvisor photo URLs to place JSON items as an images field."
    )
    parser.add_argument(
        "--input",
        default=str(DEFAULT_INPUT),
        help="Path to places JSON file. Default: data/places/VIETNAM-2932.json",
    )
    parser.add_argument(
        "--start-id",
        help="sourceLocationId to start from, inclusive. Use this after changing API key.",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=3,
        help="Max image objects to store in images, including the existing image. Default: 3",
    )
    parser.add_argument("--currency", default="VND")
    parser.add_argument("--lang", default="vi_VN")
    parser.add_argument(
        "--delay",
        type=float,
        default=1.0,
        help="Seconds to sleep between locations. Default: 1",
    )
    parser.add_argument(
        "--max-pages",
        type=int,
        default=1,
        help="Max photos/list pages to request per location. Default: 1",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Refetch locations even when they already have a non-empty images field.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Parse the JSON and print the planned range without calling the API or writing.",
    )
    parser.add_argument(
        "--key-state",
        default=str(DEFAULT_KEY_STATE),
        help="Path to the persisted RapidAPI key rotation state file.",
    )
    parser.add_argument(
        "--reset-key-state",
        action="store_true",
        help="Forget exhausted/active key state before running.",
    )
    return parser.parse_args()


def read_json_file(path, default):
    try:
        with path.open("r", encoding="utf-8") as file:
            return json.load(file)
    except FileNotFoundError:
        return default
    except json.JSONDecodeError:
        return default


def write_json_file(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp_path = path.with_suffix(path.suffix + ".tmp")
    with tmp_path.open("w", encoding="utf-8") as file:
        json.dump(data, file, ensure_ascii=False, indent=2)
        file.write("\n")
    tmp_path.replace(path)


def split_keys(value):
    return [key.strip() for key in re.split(r"[\s,;]+", value or "") if key.strip()]


def key_hash(api_key):
    return hashlib.sha256(api_key.encode("utf-8")).hexdigest()


def short_key_hash(api_key):
    return key_hash(api_key)[:10]


def load_api_keys():
    load_dotenv(REPO_DIR / ".env")
    keys = []
    seen = set()

    for key in [os.getenv("RAPIDAPI_KEY", "").strip()]:
        if key and key not in seen:
            keys.append(key)
            seen.add(key)

    for env_name in ("RAPIDAPI_KEYS", "RAPIDAPI_KEY_POOL"):
        for key in split_keys(os.getenv(env_name, "")):
            if key and key not in seen:
                keys.append(key)
                seen.add(key)

    if not keys:
        raise SystemExit("Missing RAPIDAPI_KEY or RAPIDAPI_KEYS in .env")
    return keys


class RapidApiKeyPool:
    def __init__(self, keys, state_path):
        self.keys = keys
        self.state_path = state_path
        self.hashes = [key_hash(key) for key in keys]
        self.state = read_json_file(state_path, {})
        exhausted = self.state.get("exhausted_key_hashes", [])
        self.exhausted_hashes = {value for value in exhausted if value in self.hashes}
        self.active_index = self._initial_active_index()
        self.save()

    @property
    def current_key(self):
        return self.keys[self.active_index]

    @property
    def current_label(self):
        return f"{self.active_index + 1}/{len(self.keys)}#{short_key_hash(self.current_key)}"

    def _initial_active_index(self):
        active_hash = self.state.get("active_key_hash")
        if active_hash in self.hashes and active_hash not in self.exhausted_hashes:
            return self.hashes.index(active_hash)

        index = self._first_available_index()
        if index is None:
            raise SystemExit(
                f"All configured RapidAPI keys are marked exhausted in {self.state_path}. "
                "Add a new key or run with --reset-key-state after quota resets."
            )
        return index

    def _first_available_index(self, start_after=None):
        if start_after is None:
            indices = range(len(self.keys))
        else:
            indices = [
                (start_after + step) % len(self.keys)
                for step in range(1, len(self.keys) + 1)
            ]

        for index in indices:
            if self.hashes[index] not in self.exhausted_hashes:
                return index
        return None

    def save(self):
        self.state = {
            "active_key_hash": self.hashes[self.active_index],
            "active_key_index": self.active_index,
            "exhausted_key_hashes": sorted(self.exhausted_hashes),
            "updatedAt": datetime.now().isoformat(timespec="seconds"),
        }
        write_json_file(self.state_path, self.state)

    def rotate_after_limit(self):
        exhausted_index = self.active_index
        self.exhausted_hashes.add(self.hashes[exhausted_index])
        next_index = self._first_available_index(start_after=exhausted_index)
        if next_index is None:
            self.save()
            return False

        self.active_index = next_index
        self.save()
        return True


def is_usage_limit_response(response, body_text):
    if response.status_code in {401, 403, 429}:
        return True

    lowered = body_text.lower()
    quota_markers = (
        "quota",
        "usage",
        "rate limit",
        "too many requests",
        "exceeded",
        "over the allowed",
        "you have exceeded",
        "not subscribed",
    )
    return any(marker in lowered for marker in quota_markers)


def request_photo_page(session, api_key, location_id, *, limit, offset, currency, lang):
    url = f"https://{RAPIDAPI_HOST}/photos/list"
    headers = {
        "x-rapidapi-key": api_key,
        "x-rapidapi-host": RAPIDAPI_HOST,
        "Content-Type": "application/json",
    }
    params = {
        "location_id": location_id,
        "limit": limit,
        "offset": offset,
        "currency": currency,
        "lang": lang,
    }

    try:
        response = session.get(url, headers=headers, params=params, timeout=30)
    except requests.RequestException as exc:
        raise ApiRequestError(f"request failed: {exc}") from exc

    body_text = response.text or ""
    if is_usage_limit_response(response, body_text):
        snippet = " ".join(body_text.split())[:240]
        raise ApiUsageLimitError(f"HTTP {response.status_code}: {snippet}")

    try:
        response.raise_for_status()
    except requests.HTTPError as exc:
        snippet = " ".join(body_text.split())[:240]
        raise ApiRequestError(f"HTTP {response.status_code}: {snippet}") from exc

    try:
        return response.json()
    except ValueError as exc:
        raise ApiRequestError("API returned non-JSON response") from exc


def image_object(url):
    return {
        "url": url,
        "publicId": None,
        "source": "tripadvisor",
    }


def append_unique(images, seen_urls, url):
    if not url or url in seen_urls:
        return
    seen_urls.add(url)
    images.append(image_object(url))


def primary_image_url(place):
    image = place.get("image")
    if isinstance(image, dict) and image.get("url"):
        return image["url"]
    return None


def get_high_quality_photo_urls(
    session,
    api_key,
    location_id,
    *,
    limit,
    currency,
    lang,
    max_pages,
):
    bucket_1 = []
    bucket_2 = []
    bucket_3 = []
    offset = 0
    api_limit = 50

    for _ in range(max_pages):
        data = request_photo_page(
            session,
            api_key,
            location_id,
            limit=api_limit,
            offset=offset,
            currency=currency,
            lang=lang,
        )
        items = data.get("data") if isinstance(data, dict) else None
        if not items:
            break

        for item in items:
            if not isinstance(item, dict):
                continue

            images = item.get("images") or {}
            original = images.get("original") or {}
            large = images.get("large") or {}
            url = original.get("url") or large.get("url")
            if not url:
                continue

            is_blessed = item.get("is_blessed") is True
            no_linked_reviews = not bool(item.get("linked_reviews"))
            if is_blessed and no_linked_reviews:
                bucket_1.append(url)
            elif is_blessed or no_linked_reviews:
                bucket_2.append(url)
            else:
                bucket_3.append(url)

        if len(items) < api_limit:
            break
        offset += api_limit

    result = []
    seen_urls = set()
    for url in [*bucket_1, *bucket_2, *bucket_3]:
        if url in seen_urls:
            continue
        seen_urls.add(url)
        result.append(url)
        if len(result) >= limit:
            break
    return result


def write_json(path, data):
    tmp_path = path.with_suffix(path.suffix + ".tmp")
    with tmp_path.open("w", encoding="utf-8") as file:
        json.dump(data, file, ensure_ascii=False, indent=2)
        file.write("\n")
    tmp_path.replace(path)


def create_backup(path):
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    backup_path = path.with_suffix(path.suffix + f".bak-{timestamp}")
    shutil.copy2(path, backup_path)
    print(f"Backup created: {backup_path}")


def find_start_index(places, start_id):
    if not start_id:
        return 0
    for index, place in enumerate(places):
        if str(place.get("sourceLocationId") or "") == str(start_id):
            return index
    raise SystemExit(f"Start id not found in input file: {start_id}")


def main():
    args = parse_args()
    input_path = Path(args.input)
    if not input_path.is_absolute():
        input_path = CRAWLER_DIR / input_path
    input_path = input_path.resolve()

    key_state_path = Path(args.key_state)
    if not key_state_path.is_absolute():
        key_state_path = CRAWLER_DIR / key_state_path
    key_state_path = key_state_path.resolve()

    with input_path.open("r", encoding="utf-8") as file:
        places = json.load(file)

    if not isinstance(places, list):
        raise SystemExit(f"Expected top-level JSON array: {input_path}")

    start_index = find_start_index(places, args.start_id)
    print(f"Input: {input_path}")
    print(f"Total places: {len(places)}")
    print(f"Start index: {start_index}")

    if args.dry_run:
        first_id = places[start_index].get("sourceLocationId") if places[start_index:] else None
        print(f"Dry run only. First sourceLocationId: {first_id}")
        return

    if args.reset_key_state and key_state_path.exists():
        key_state_path.unlink()
        print(f"Reset key state: {key_state_path}")

    key_pool = RapidApiKeyPool(load_api_keys(), key_state_path)
    print(f"RapidAPI keys configured: {len(key_pool.keys)}")
    print(f"Using RapidAPI key: {key_pool.current_label}")
    create_backup(input_path)

    session = requests.Session()
    processed = 0
    skipped = 0

    for index in range(start_index, len(places)):
        place = places[index]
        if not isinstance(place, dict):
            skipped += 1
            continue

        source_id = place.get("sourceLocationId")
        if not source_id:
            print(f"[{index + 1}/{len(places)}] Skip: missing sourceLocationId")
            skipped += 1
            continue

        if not args.force and isinstance(place.get("images"), list) and place["images"]:
            print(f"[{index + 1}/{len(places)}] Skip {source_id}: images already exists")
            skipped += 1
            continue

        title = place.get("title") or ""
        print(f"[{index + 1}/{len(places)}] Fetch photos for {source_id} {title}")

        images = []
        seen_urls = set()
        primary_url = primary_image_url(place)
        if primary_url:
            seen_urls.add(primary_url)

        while True:
            try:
                photo_urls = get_high_quality_photo_urls(
                    session,
                    key_pool.current_key,
                    source_id,
                    limit=args.limit,
                    currency=args.currency,
                    lang=args.lang,
                    max_pages=args.max_pages,
                )
                break
            except KeyboardInterrupt:
                print("")
                print(f"Interrupted at sourceLocationId={source_id}")
                print("Resume from this id with:")
                print(f"  ./enrich_place_images.sh {source_id}")
                return 130
            except ApiUsageLimitError as exc:
                exhausted_key = key_pool.current_label
                print("")
                print(
                    f"API usage/key limit reached for key {exhausted_key} "
                    f"at sourceLocationId={source_id}"
                )
                print(f"Reason: {exc}")
                if key_pool.rotate_after_limit():
                    print(f"Rotated to RapidAPI key: {key_pool.current_label}")
                    print(f"Retrying sourceLocationId={source_id}")
                    continue

                print("No configured RapidAPI keys left.")
                print(f"Add another key to RAPIDAPI_KEYS in .env, then resume with:")
                print(f"  ./enrich_place_images.sh {source_id}")
                return 2
            except ApiRequestError as exc:
                print("")
                print(f"Stopped at sourceLocationId={source_id}")
                print(f"Reason: {exc}")
                print("Resume from this id after fixing the issue with:")
                print(f"  ./enrich_place_images.sh {source_id}")
                return 3

        for url in photo_urls:
            append_unique(images, seen_urls, url)
            if len(images) >= args.limit:
                break

        place["images"] = images
        write_json(input_path, places)
        processed += 1
        print(f"Saved {len(images)} images for {source_id}")

        if args.delay > 0 and index < len(places) - 1:
            try:
                time.sleep(args.delay)
            except KeyboardInterrupt:
                next_place = places[index + 1]
                next_id = (
                    next_place.get("sourceLocationId")
                    if isinstance(next_place, dict)
                    else None
                )
                print("")
                print(f"Interrupted after saving sourceLocationId={source_id}")
                if next_id:
                    print("Resume from next id with:")
                    print(f"  ./enrich_place_images.sh {next_id}")
                return 130

    print("")
    print(f"Done. Processed: {processed}, skipped: {skipped}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
