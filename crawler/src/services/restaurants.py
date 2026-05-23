from src.core.travel_advisor import travel_advisor_client
from src.utils.file_io import save_to_json
import time

def restaurants_list(
    location_id: int, # Returned in locations/search
    restaurant_tagcategory: str = None, # Establishment type
    restaurant_tagcategory_standalone: str = None,
    restaurant_mealtype: str = None, # Meals
    combined_food: str = None, # Cuisine type
    currency: str = "USD",
    lunit: str = "km", # km | mi
    dietary_restrictions: str = None, # Dietary restrictions
    limit: int = 30, # Max 30
    prices_restaurant: str = None,
    min_rating: str = None, # Min 3 max 5
    open_now: bool = None, # Return restaurants which are open now
    offset: int = 0,
    restaurant_styles: str = None, # Restaurant features
    lang: str = "vi_VN",
    restaurant_dining_options: str = None, # Restaurant features
    save_raw: bool = True,
    return_status: bool = False
    ):
    endpoint = "restaurants/list"
    params = {
        "location_id": location_id,
        "currency": currency,
        "limit": limit,
        "offset": offset,
        "lang": lang,
        "lunit": lunit,
        "restaurant_tagcategory": restaurant_tagcategory,
        "restaurant_tagcategory_standalone": restaurant_tagcategory_standalone,
        "restaurant_mealtype": restaurant_mealtype,
        "combined_food": combined_food,
        "dietary_restrictions": dietary_restrictions,
        "prices_restaurant": prices_restaurant,
        "min_rating": min_rating,
        "open_now": open_now,
        "restaurant_styles": restaurant_styles,
        "restaurant_dining_options": restaurant_dining_options
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
                return (None, "empty") if return_status else None
            break # Success, we have data
        except Exception as e:
            print(f"Error fetching data on attempt {attempt + 1}: {e}")
            if attempt < max_retries - 1:
                time.sleep(5)
                continue
            return (None, "error") if return_status else None
    
    if data and save_raw:
        filename = f"{location_id}_restaurants_list.json"
        save_to_json(data, filename)
    
    return (data, "ok") if return_status else data

def restaurants_get_details(
    location_id: int, 
    currency: str = "USD",
    lang: str = "vi_VN"
    ):
    endpoint = "restaurants/get-details"
    params = {
        "location_id": location_id,
        "currency": currency,
        "lang": lang
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
        filename = f"{location_id}_restaurants_details.json"
        save_to_json(data, filename)
    
    return data
