import json
import os

from src.utils.file_io import save_to_data_json, save_to_json


def _as_number(value, fallback=0):
    if value in (None, ""):
        return fallback
    try:
        return float(value)
    except (TypeError, ValueError):
        return fallback


def _as_int(value, fallback=0):
    if value in (None, ""):
        return fallback
    try:
        return int(float(value))
    except (TypeError, ValueError):
        return fallback


def _compact(value):
    if isinstance(value, dict):
        return {key: _compact(item) for key, item in value.items() if item not in (None, "", [], {})}
    if isinstance(value, list):
        return [_compact(item) for item in value if item not in (None, "", [], {})]
    return value


def _with_nulls(value):
    if isinstance(value, dict):
        return {key: _with_nulls(item) for key, item in value.items()}
    if isinstance(value, list):
        return [_with_nulls(item) for item in value]
    return value


def _unwrap_item(item):
    if isinstance(item, dict) and isinstance(item.get("result_object"), dict):
        return item["result_object"]
    return item


def _is_generic_location(row, item):
    if isinstance(row, dict) and row.get("result_type") == "geos":
        return True

    category = item.get("category") or {}
    if isinstance(category, dict) and category.get("key") == "geographic":
        return True

    # City/province/country search results usually include aggregate counts
    # instead of representing one visitable place.
    if item.get("category_counts") or item.get("geo_type"):
        return True

    return False


def _image_url(item):
    images = item.get("photo", {}).get("images", {})
    for size in ("original", "large", "medium", "small", "thumbnail"):
        url = images.get(size, {}).get("url")
        if url:
            return url
    return item.get("imageUrl") or item.get("photo_url")


def _tags(item):
    names = []
    category = item.get("category")
    if isinstance(category, dict) and category.get("name"):
        names.append(category["name"])

    for subcategory in item.get("subcategory") or []:
        if isinstance(subcategory, dict) and subcategory.get("name"):
            names.append(subcategory["name"])

    return list(dict.fromkeys(names))


def _province_or_city(item, address, ancestors):
    for ancestor in ancestors:
        subcategories = ancestor.get("subcategory") or []
        keys = {entry.get("key") for entry in subcategories if isinstance(entry, dict)}
        if keys.intersection({"municipality", "province", "city"}):
            return ancestor.get("name")

    return address.get("city") or item.get("location_string")


def _image(item, title, city):
    url = _image_url(item)
    if not url:
        return None

    return {
        "url": url,
        "publicId": None,
        "source": "tripadvisor",
    }


def _location(item):
    latitude = _as_number(item.get("latitude"), None)
    longitude = _as_number(item.get("longitude"), None)
    if latitude is None or longitude is None:
        return None

    return {
        "type": "Point",
        "coordinates": [longitude, latitude],
    }


def _minutes_to_time(total_minutes):
    if total_minutes is None:
        return None
    hours = int(total_minutes) // 60
    minutes = int(total_minutes) % 60
    return f"{hours:02d}:{minutes:02d}"


def _opening_range_display(day_ranges):
    parts = []
    for entry in day_ranges or []:
        open_time = _minutes_to_time(entry.get("open_time"))
        close_time = _minutes_to_time(entry.get("close_time"))
        if open_time and close_time:
            parts.append(f"{open_time}-{close_time}")
    return ", ".join(parts)


def _opening_hours(item):
    hours = item.get("hours") or {}
    week_ranges = hours.get("week_ranges")
    if not week_ranges:
        return None

    first_day = week_ranges[0] if week_ranges else []
    display = _opening_range_display(first_day) if all(day == first_day for day in week_ranges) else None

    return {
        "display": display,
        "weekRanges": week_ranges,
    }


def _ranking(item):
    position = item.get("ranking_position")
    denominator = item.get("ranking_denominator")
    if position and denominator:
        return f"{position}/{denominator}"
    return item.get("ranking")


def _search_text(place):
    parts = [
        f"{place['title']} ở {place['city']}." if place.get("city") else place["title"],
    ]
    if place.get("category"):
        parts.append(f"Loại địa điểm: {place['category']}.")
    if place.get("tags"):
        parts.append(f"Tags: {', '.join(place['tags'])}.")
    if place.get("description"):
        parts.append(f"Mô tả: {place['description']}")
    if place.get("totalScore"):
        parts.append(f"Đánh giá: {place['totalScore']}/5 từ {place.get('reviewsCount', 0)} lượt review.")
    if place.get("ranking"):
        parts.append(f"Xếp hạng: {place['ranking']}.")
    if place.get("priceRange"):
        parts.append(f"Giá: {place['priceRange']}.")

    return " ".join(parts)


def transform_to_places(raw_data):
    rows = raw_data.get("data", raw_data) if isinstance(raw_data, dict) else raw_data
    if not isinstance(rows, list):
        rows = [rows]

    places = []

    for row in rows:
        item = _unwrap_item(row)
        if not isinstance(item, dict):
            continue

        if _is_generic_location(row, item):
            continue

        location_id = item.get("location_id")
        if not location_id or str(location_id) == "0":
            continue

        title = item.get("name") or item.get("title")
        if not title:
            continue

        address = item.get("address_obj") or {}
        ancestors = item.get("ancestors") or []
        city = _province_or_city(item, address, ancestors)
        tags = _tags(item)
        image = _image(item, title, city)
        if image:
            image["publicId"] = None

        place = {
            "sourceLocationId": str(location_id),
            "title": title,
            "city": city,
            "totalScore": _as_number(item.get("rating")),
            "ranking": _ranking(item),
            "reviewsCount": _as_int(item.get("num_reviews") or item.get("reviewsCount")),
            "category": tags[-1] if tags else None,
            "priceRange": item.get("price_level") or item.get("price") or item.get("priceRange"),
            "description": item.get("description") or item.get("geo_description"),
            "embedding": None,
            "searchText": None,
            "tags": tags,
            "image": image,
            "location": _location(item),
            "openingHours": _opening_hours(item),
        }
        place["searchText"] = _search_text(place)
        places.append(_with_nulls(place))

    return places


def save_places_output(raw_data, filename):
    places = transform_to_places(raw_data)
    save_to_json(places, filename)
    print(f"Places exported: {len(places)}")
    return places


def collect_output_places(prefix):
    data_dir = os.path.join(os.path.dirname(__file__), "..", "..", "data")
    output_dir = os.path.join(data_dir, "output")
    places = []
    seen_ids = set()

    if not os.path.isdir(output_dir):
        print(f"No output directory found at {output_dir}")
        return [], 0

    filenames = sorted(
        filename for filename in os.listdir(output_dir)
        if filename.startswith(prefix) and filename.endswith("_places.json")
    )

    for filename in filenames:
        filepath = os.path.join(output_dir, filename)
        with open(filepath, "r", encoding="utf-8") as json_file:
            data = json.load(json_file)

        if not isinstance(data, list):
            continue

        for place in data:
            source_id = place.get("sourceLocationId")
            if not source_id or str(source_id) == "0":
                continue
            if source_id and source_id in seen_ids:
                continue
            seen_ids.add(source_id)
            places.append(place)

    return places, len(filenames)


def clean_output_places(prefix):
    data_dir = os.path.join(os.path.dirname(__file__), "..", "..", "data")
    output_dir = os.path.join(data_dir, "output")
    if not os.path.isdir(output_dir):
        return 0

    removed = 0
    for filename in os.listdir(output_dir):
        if not filename.startswith(prefix) or not filename.endswith("_places.json"):
            continue
        os.remove(os.path.join(output_dir, filename))
        removed += 1

    print(f"Cleaned output files: {removed}")
    return removed


def merge_output_places(prefix, output_filename):
    places, file_count = collect_output_places(prefix)
    save_to_data_json(places, output_filename)
    print(f"Merged files: {file_count}")
    print(f"Merged places exported: {len(places)}")
    return places


def save_merged_output_places(prefix, region_name=None, clean_output=False):
    places, file_count = collect_output_places(prefix)
    compact_region = "".join((region_name or prefix).split())
    final_filename = f"{compact_region}-{len(places)}.json"
    save_to_data_json(places, final_filename)
    print(f"Merged files: {file_count}")
    print(f"Merged places exported: {len(places)}")
    if clean_output:
        clean_output_places(prefix)
    return places
