from src.core.travel_advisor import travel_advisor_client
from src.utils.file_io import save_to_json
import time

def attractions_list(
    location_id: int, # Returned in locations/search
    currency: str = "USD", # Currency code
    lang: str = "vi_VN", # Language code
    lunit: str = "km", # km | mi
    min_rating: str = None, # Min 3 max 5
    limit: int = 30, # Items per response (max 30)
    sort: str = "recommended", # recommended | ranking 
    bookable_first: bool = None, # Book online first
    subcategory: str = None, # 
    offset: int = 0 # Paging purpose
    ):
    endpoint = "attractions/list"
    params = {
        "location_id": location_id,
        "currency": currency,
        "lang": lang,
        "lunit": lunit,
        "min_rating": min_rating,
        "limit": limit,
        "sort": sort,
        "bookable_first": bookable_first,
        "subcategory": subcategory,
        "offset": offset
    }
    max_retries = 3
    data = None
    
    for attempt in range(max_retries):
        try:
            data = travel_advisor_client.get(endpoint, params)
            # Check if data is empty or if "data" array is empty
            if not data or ("data" in data and not data["data"]):
                print(f"Attempt {attempt + 1}: 0 results found, retrying in 5 seconds...")
                time.sleep(5)
                continue
            break # Success, we have data
        except Exception as e:
            print(f"Error fetching data on attempt {attempt + 1}: {e}")
            if attempt < max_retries - 1:
                time.sleep(5)
                continue
            return None
    
    if data:
        filename = f"{location_id}_attractions_list.json"
        save_to_json(data, filename)
    
    return data

def attractions_get_details(
    location_id: int, # Returned in attractions/list
    currency: str = "USD", # Currency code
    lang: str = "vi_VN" # Language code
    ):
    endpoint = "attractions/get-details"
    params = {
        "location_id": location_id,
        "currency": currency,
        "lang": lang
    }
    max_retries = 3
    data = None
    
    for attempt in range(max_retries):
        try:
            data = travel_advisor_client.get(endpoint, params)
            # Check if data is empty or if "data" array is empty
            if not data or ("data" in data and not data["data"]):
                print(f"Attempt {attempt + 1}: 0 results found, retrying in 5 seconds...")
                time.sleep(5)
                continue
            break # Success, we have data
        except Exception as e:
            print(f"Error fetching data on attempt {attempt + 1}: {e}")
            if attempt < max_retries - 1:
                time.sleep(5)
                continue
            return None
    
    if data:
        filename = f"{location_id}_attractions_details.json"
        save_to_json(data, filename)
    
    return data
