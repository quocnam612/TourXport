from src.core.travel_advisor import travel_advisor_client
from src.utils.file_io import save_to_json
import time

def hotels_list_id(
    location_id: int, # Returned in locations/search
    adults: int, # Adults in all rooms
    rooms: int, 
    nights: int, 
    checkin: str = None, # Check in date format yyyy-MM-dd
    offset: int = 0, 
    pricesmax: int = None,  # 120$ -> 120
    pricesmin: int = None,
    zff: str = None, # Hotel style
    subcategory: str = None,
    hotel_class: str = None,
    currency: str = "USD",
    amenities: str = None,
    child_rm_ages: str = None, # Age of every children, seperated by comma
    order: str = "asc", # asc | desc
    limit: int = 5, # Max 30
    sort: str = "recommended", # recommended | popularity | price
    lang: str = "vi_VN",
    save_raw: bool = True,
    return_status: bool = False
    ):
    endpoint = "hotels/list"
    params = {
        "location_id": location_id,
        "adults": adults,
        "rooms": rooms,
        "nights": nights,
        "checkin": checkin,
        "offset": offset,
        "pricesmax": pricesmax,
        "pricesmin": pricesmin,
        "zff": zff,
        "subcategory": subcategory,
        "hotel_class": hotel_class,
        "currency": currency,
        "amenities": amenities,
        "child_rm_ages": child_rm_ages,
        "order": order,
        "limit": limit,
        "sort": sort,
        "lang": lang
    }
    max_retries = 1
    data = None
    
    for attempt in range(max_retries):
        try:
            data = travel_advisor_client.get(endpoint, params)
            # Check if data is empty or if "data" array is empty
            if not data or not data.get("data"):
                print(f"Attempt {attempt + 1}: 0 results found.")
                if attempt < max_retries - 1:
                    time.sleep(5)
                    continue
                return (None, "empty") if return_status else None
            break # Success, we have data
        except Exception as e:
            print(f"Error fetching data on attempt {attempt + 1}: {e}")
            if attempt < max_retries - 1:
                time.sleep(5)
                continue
            return (None, "error") if return_status else None
    
    if data and save_raw:
        filename = f"{location_id}_hotels_search.json"
        save_to_json(data, filename)
    
    return (data, "ok") if return_status else data

def hotels_get_details(
    location_id: int, # Returned in hotels/list
    checkin: str = None,
    adults: int = None,
    lang: str = "vi_VN",
    child_rm_ages: str = None,
    currency: str = "USD",
    nights: int = None,
    rooms: int = None
    ):
    endpoint = "hotels/get-details"
    params = {
        "location_id": location_id,
        "checkin": checkin,
        "adults": adults,
        "lang": lang,
        "child_rm_ages": child_rm_ages,
        "currency": currency,
        "nights": nights,
        "rooms": rooms  
    }
    max_retries = 1
    data = None
    
    for attempt in range(max_retries):
        try:
            data = travel_advisor_client.get(endpoint, params)
            # Check if data is empty or if "data" array is empty
            if not data or ("data" in data and not data["data"]):
                print(f"Attempt {attempt + 1}: 0 results found.")
                if attempt < max_retries - 1:
                    time.sleep(5)
                    continue
                return None
            break # Success, we have data
        except Exception as e:
            print(f"Error fetching data on attempt {attempt + 1}: {e}")
            if attempt < max_retries - 1:
                time.sleep(5)
                continue
            return None
    
    if data:
        filename = f"{location_id}_hotels_details.json"
        save_to_json(data, filename)
    
    return data
