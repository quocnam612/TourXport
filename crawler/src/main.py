import argparse
import asyncio
import sys
import os
import time
import unicodedata

# Ensure src is in the python path
sys.path.append(os.path.join(os.path.dirname(__file__), ".."))

from src.services.location_service import locations_search
from src.services.hotels import hotels_list_id, hotels_get_details
from src.services.google_maps_service import scrape_gmaps_restaurants
from src.services.restaurants import restaurants_list, restaurants_get_details
from src.services.attractions import attractions_list, attractions_get_details
from src.services.shared import reviews_list, photos_list, questions_list, answers_list
from src.utils.place_transformer import save_places_output, save_merged_output_places


def _normalize_text(value):
    text = unicodedata.normalize("NFD", str(value or "").lower())
    text = "".join(char for char in text if unicodedata.category(char) != "Mn")
    return " ".join(text.replace("-", " ").split())


def _row_item(row):
    item = row.get("result_object") if isinstance(row, dict) else None
    if isinstance(item, dict):
        return item
    return row if isinstance(row, dict) else {}


def _is_lodging_result(row):
    item = _row_item(row)

    if isinstance(row, dict) and row.get("result_type") == "lodging":
        return True

    category = item.get("category") or {}
    category_values = {
        str(category.get("key") or "").lower(),
        str(category.get("name") or "").lower(),
    }
    if category_values.intersection({"hotel", "hotels", "lodging", "khách sạn", "khách sạn"}):
        return True

    for subcategory in item.get("subcategory") or []:
        value = str(subcategory.get("key") or subcategory.get("name") or "").lower()
        if value in {"hotel", "hotels", "lodging", "khách sạn", "khách sạn"}:
            return True

    return False


def _search_geo_context(rows, query):
    query_text = _normalize_text(query)
    geo_ids = set()
    geo_names = set()

    for row in rows:
        if not isinstance(row, dict) or row.get("result_type") != "geos":
            continue

        item = _row_item(row)
        name = item.get("name")
        location_string = item.get("location_string")
        haystack = _normalize_text(f"{name} {location_string}")
        if query_text and query_text not in haystack and haystack not in query_text:
            continue

        location_id = item.get("location_id")
        if location_id:
            geo_ids.add(str(location_id))
        if name:
            geo_names.add(_normalize_text(name))
        if location_string:
            geo_names.add(_normalize_text(location_string))

    if not geo_names and query_text:
        geo_names.add(query_text)

    return geo_ids, geo_names


def _belongs_to_search_geo(row, geo_ids, geo_names):
    item = _row_item(row)

    for ancestor in item.get("ancestors") or []:
        ancestor_id = ancestor.get("location_id")
        if ancestor_id and str(ancestor_id) in geo_ids:
            return True

        ancestor_name = _normalize_text(ancestor.get("name"))
        if ancestor_name and ancestor_name in geo_names:
            return True

    address = item.get("address_obj") or {}
    fields = [
        item.get("location_string"),
        address.get("city"),
        address.get("state"),
    ]
    text = _normalize_text(" ".join(str(field or "") for field in fields))
    return any(name and name in text for name in geo_names)


def _save_hotels_from_search(query, region_name, lang, units, clean_output):
    compact_region = "".join((region_name or query).split())
    output_prefix = f"{compact_region}Hotels" if not compact_region.endswith("Hotels") else compact_region

    print(f"Searching hotels for region: {query}")
    data = locations_search(query=query, lang=lang, units=units, save_raw=False)
    rows = data.get("data", []) if isinstance(data, dict) else []
    geo_ids, geo_names = _search_geo_context(rows, query)
    lodging_rows = [
        row for row in rows
        if _is_lodging_result(row) and _belongs_to_search_geo(row, geo_ids, geo_names)
    ]
    print(
        f"Location search rows: {len(rows)}, "
        f"geo ids: {len(geo_ids)}, lodging rows: {len(lodging_rows)}"
    )

    if not lodging_rows:
        print("No lodging results found. Nothing to merge.")
        return []

    save_places_output({"data": lodging_rows}, f"{output_prefix}_search_places.json")
    return save_merged_output_places(
        output_prefix,
        region_name=output_prefix,
        clean_output=clean_output,
        output_subdir="hotels",
    )


def parse_kwargs(unknown_args):
    kwargs = {}
    i = 0
    while i < len(unknown_args):
        if unknown_args[i].startswith("--"):
            key = unknown_args[i][2:]
            if i + 1 < len(unknown_args) and not unknown_args[i+1].startswith("--"):
                val = unknown_args[i+1]
                if val.isdigit():
                    val = int(val)
                elif val.lower() == 'true':
                    val = True
                elif val.lower() == 'false':
                    val = False
                kwargs[key] = val
                i += 2
            else:
                kwargs[key] = True
                i += 1
        else:
            i += 1
    return kwargs

def main():
    description = (
        "TourXport Crawler CLI"
    )
    epilog = """
location_search:     --query, --lang, --units
hotels_search:       --query, --lang, --units
hotels_list:         --query, --adults, --rooms, --nights, --checkin, --offset, --pricesmax, --pricesmin, 
                     --zff, --subcategory, --hotel_class, --currency, --amenities, --child_rm_ages, 
                     --order, --limit, --sort, --lang
hotels_details:      --query, --checkin, --adults, --lang, --child_rm_ages, --currency, --nights, --rooms
restaurants_list:    --query, --currency, --lunit, --limit, --offset, --lang, --restaurant_tagcategory,
                     --restaurant_tagcategory_standalone, --restaurant_mealtype, --combined_food,
                     --dietary_restrictions, --prices_restaurant, --min_rating, --open_now, 
                     --restaurant_styles, --restaurant_dining_options
restaurants_details: --query, --currency, --lang
attractions_list:    --query, --currency, --lang, --lunit, --min_rating, --limit, --sort, --bookable_first, 
                     --subcategory, --offset
attractions_details: --query, --currency, --lang
reviews_list:        --query, --keyword, --limit, --currency, --offset, --lang
photos_list:         --query, --currency, --limit, --offset, --lang
questions_list:      --query, --offset, --limit
answers_list:        --query, --offset, --limit

Example: python src/main.py --task restaurants_list --query 293919 --limit 10 --currency EUR
"""
    parser = argparse.ArgumentParser(
        description=description, 
        epilog=epilog,
        formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument("--task", type=str, required=True, 
                        choices=[
                            "location_search", 
                            "hotels_search",
                            "hotels_list", 
                            "hotels_details",
                            "restaurants_list",
                            "restaurants_details",
                            "attractions_list",
                            "attractions_details",
                            "reviews_list",
                            "photos_list",
                            "questions_list",
                            "answers_list",
                            "google-maps"
                        ],
                        help="The task you want to run.")

    args, unknown = parser.parse_known_args()
    kwargs = parse_kwargs(unknown)
    
    query = kwargs.pop("query", None)
    if not query:
        print("Error: --query is required for all tasks.")
        return

    output_format = kwargs.pop("format", None)
    clean_output = kwargs.pop("clean_output", False)
    pages = int(kwargs.pop("pages", 1))
    region_name = kwargs.pop("region_name", None)
    request_delay = int(kwargs.pop("request_delay", 5))
    fallback_search_query = kwargs.pop("fallback_search_query", None)

    if args.task == "location_search":
        print(f"Searching for: {query} with {kwargs}")
        locations_search(query=query, **kwargs)

    elif args.task == "hotels_search":
        lang = kwargs.get("lang", "vi_VN")
        units = kwargs.get("units", "km")
        _save_hotels_from_search(query, region_name, lang, units, clean_output)
        
    elif args.task == "google-maps":
        print(f"Running Google Maps scraper for: {query}")
        asyncio.run(scrape_gmaps_restaurants(query=query))
        
    else:
        # All other tasks expect an integer ID
        try:
            target_id = int(query)
        except ValueError:
            print(f"Error: query must be a valid integer ID for task '{args.task}'.")
            return

        if args.task == "hotels_list":
            if "adults" not in kwargs: kwargs["adults"] = 1
            if "rooms" not in kwargs: kwargs["rooms"] = 1
            if "nights" not in kwargs: kwargs["nights"] = 1
            limit = int(kwargs.get("limit", 5))
            print(f"Fetching hotels for location_id: {target_id} with {kwargs}")

            if output_format == "places":
                fetched_pages = 0
                empty_pages = 0
                for page in range(pages):
                    page_kwargs = {
                        **kwargs,
                        "offset": int(kwargs.get("offset", 0)) + (page * limit),
                        "save_raw": False,
                        "return_status": True,
                    }
                    data, status = hotels_list_id(location_id=target_id, **page_kwargs)
                    if status == "error":
                        print(f"Offset {page_kwargs['offset']}: request failed.")
                        print("Hotel API request failed. Stopping this location without merge.")
                        break

                    if status == "empty" or not data or not data.get("data"):
                        print(f"Offset {page_kwargs['offset']}: raw=0, places=0")
                        empty_pages += 1
                        if empty_pages >= 2:
                            print("Two consecutive empty hotel pages. Stopping crawl.")
                            break
                        if request_delay > 0:
                            print(f"Waiting {request_delay}s before next request...")
                            time.sleep(request_delay)
                        continue

                    places = save_places_output(data, f"{target_id}_{page_kwargs['offset']}_places.json")
                    print(f"Offset {page_kwargs['offset']}: raw={len(data.get('data', []))}, places={len(places)}")
                    if not places:
                        empty_pages += 1
                        if empty_pages >= 2:
                            print("Two consecutive empty hotel pages. Stopping crawl.")
                            break
                        if request_delay > 0:
                            print(f"Waiting {request_delay}s before next request...")
                            time.sleep(request_delay)
                        continue

                    empty_pages = 0
                    fetched_pages += 1
                    if request_delay > 0 and page < pages - 1:
                        print(f"Waiting {request_delay}s before next request...")
                        time.sleep(request_delay)

                if fetched_pages:
                    save_merged_output_places(
                        str(target_id),
                        region_name=region_name,
                        clean_output=clean_output,
                        output_subdir="hotels",
                    )
                else:
                    print("No hotel data fetched. Nothing to merge.")
                    if fallback_search_query:
                        _save_hotels_from_search(
                            fallback_search_query,
                            region_name,
                            kwargs.get("lang", "vi_VN"),
                            kwargs.get("units", "km"),
                            clean_output,
                        )
            else:
                hotels_list_id(location_id=target_id, **kwargs)
            
        elif args.task == "hotels_details":
            print(f"Fetching hotel details for location_id: {target_id} with {kwargs}")
            hotels_get_details(location_id=target_id, **kwargs)
            
        elif args.task == "restaurants_list":
            print(f"Fetching restaurants for location_id: {target_id} with {kwargs}")
            limit = int(kwargs.get("limit", 30))

            if output_format == "places":
                fetched_pages = 0
                empty_pages = 0
                for page in range(pages):
                    page_kwargs = {
                        **kwargs,
                        "offset": int(kwargs.get("offset", 0)) + (page * limit),
                        "save_raw": False,
                        "return_status": True,
                    }
                    data, status = restaurants_list(location_id=target_id, **page_kwargs)
                    if status == "error":
                        print(f"Offset {page_kwargs['offset']}: request failed.")
                        print("Restaurant API request failed. Stopping this location without merge.")
                        break

                    if status == "empty" or not data or not data.get("data"):
                        print(f"Offset {page_kwargs['offset']}: raw=0, places=0")
                        empty_pages += 1
                        if empty_pages >= 2:
                            print("Two consecutive empty restaurant pages. Stopping crawl.")
                            break
                        if request_delay > 0:
                            print(f"Waiting {request_delay}s before next request...")
                            time.sleep(request_delay)
                        continue

                    places = save_places_output(data, f"{target_id}_{page_kwargs['offset']}_places.json")
                    print(f"Offset {page_kwargs['offset']}: raw={len(data.get('data', []))}, places={len(places)}")
                    if not places:
                        empty_pages += 1
                        if empty_pages >= 2:
                            print("Two consecutive empty restaurant pages. Stopping crawl.")
                            break
                        if request_delay > 0:
                            print(f"Waiting {request_delay}s before next request...")
                            time.sleep(request_delay)
                        continue

                    empty_pages = 0
                    fetched_pages += 1
                    if request_delay > 0 and page < pages - 1:
                        print(f"Waiting {request_delay}s before next request...")
                        time.sleep(request_delay)

                if fetched_pages:
                    save_merged_output_places(
                        str(target_id),
                        region_name=region_name,
                        clean_output=clean_output,
                        output_subdir="foods",
                    )
                else:
                    print("No restaurant data fetched. Nothing to merge.")
            else:
                restaurants_list(location_id=target_id, **kwargs)
            
        elif args.task == "restaurants_details":
            print(f"Fetching restaurant details for location_id: {target_id} with {kwargs}")
            restaurants_get_details(location_id=target_id, **kwargs)
            
        elif args.task == "attractions_list":
            print(f"Fetching attractions for location_id: {target_id} with {kwargs}")
            attractions_list(location_id=target_id, **kwargs)
            
        elif args.task == "attractions_details":
            print(f"Fetching attraction details for location_id: {target_id} with {kwargs}")
            attractions_get_details(location_id=target_id, **kwargs)
            
        elif args.task == "reviews_list":
            print(f"Fetching reviews for location_id: {target_id} with {kwargs}")
            reviews_list(location_id=target_id, **kwargs)
            
        elif args.task == "photos_list":
            print(f"Fetching photos for location_id: {target_id} with {kwargs}")
            photos_list(location_id=target_id, **kwargs)
            
        elif args.task == "questions_list":
            print(f"Fetching questions for location_id: {target_id} with {kwargs}")
            questions_list(location_id=target_id, **kwargs)
            
        elif args.task == "answers_list":
            print(f"Fetching answers for question_id: {target_id} with {kwargs}")
            answers_list(question_id=target_id, **kwargs)

if __name__ == "__main__":  
    main()
