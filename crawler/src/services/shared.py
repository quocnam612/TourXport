from src.core.travel_advisor import travel_advisor_client
from src.utils.file_io import save_to_json
import time

def reviews_list(
    location_id: int, # Returned in locations/search
    keyword: str = None,
    limit: int = 20, # Items per response (max 20)
    currency: str = "USD",
    offset: int = 0,
    lang: str = "vi_VN"
    ):
    endpoint = "reviews/list"
    params = {
        "location_id": location_id,
        "keyword": keyword,
        "limit": limit,
        "currency": currency,
        "offset": offset,
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
        filename = f"{location_id}_reviews_list.json"
        save_to_json(data, filename)
    
    return data

def photos_list(
    location_id: int, 
    currency: str = "USD",
    limit: int = 50, # Max 50
    offset: int = 0,
    lang: str = "vi_VN"
    ):
    endpoint = "photos/list"
    params = {
        "location_id": location_id,
        "limit": limit,
        "offset": offset,
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
    
    # if data:
    #     filename = f"{location_id}_photos_list.json"
    #     save_to_json(data, filename)
    
    return data

def get_high_quality_photos(
    location_id: int, 
    currency: str = "USD",
    limit: int = 50, # Target number of photos to return
    offset: int = 0, # Starting offset
    lang: str = "vi_VN",
    max_pages: int = 1 # Limit the number of API calls
):
    """
    Fetches photos and extracts image URLs based on priority:
    1. is_blessed == True AND linked_reviews is empty
    2. is_blessed == True OR linked_reviews is empty
    3. Neither
    """
    bucket_1 = [] # Both conditions met
    bucket_2 = [] # One condition met
    bucket_3 = [] # Neither condition met
    
    current_offset = offset
    api_limit = 50 # Max allowed by the API per request
    pages_fetched = 0
    
    while len(bucket_1) < limit and pages_fetched < max_pages:
        data = photos_list(
            location_id=location_id,
            currency=currency,
            limit=api_limit,
            offset=current_offset,
            lang=lang
        )
        pages_fetched += 1
        
        if not data or not isinstance(data, dict) or not data.get("data"):
            break
            
        fetched_items = data["data"]
        
        for item in fetched_items:
            is_blessed = item.get("is_blessed") is True
            no_linked_reviews = not bool(item.get("linked_reviews"))
            
            # Extract URL: priority original > large
            images = item.get("images") or {}
            original = images.get("original") or {}
            large = images.get("large") or {}
            
            original_url = original.get("url")
            large_url = large.get("url")
            
            url = original_url if original_url else large_url
            if not url:
                continue
                
            if is_blessed and no_linked_reviews:
                if len(bucket_1) < limit:
                    bucket_1.append(url)
            elif is_blessed or no_linked_reviews:
                bucket_2.append(url)
            else:
                bucket_3.append(url)
                
        # If API returned less items than requested, we've reached the end
        if len(fetched_items) < api_limit:
            break
            
        # Increment offset for next page
        current_offset += api_limit
            
    # Combine buckets to satisfy the limit
    result = bucket_1
    if len(result) < limit:
        result.extend(bucket_2[:limit - len(result)])
    if len(result) < limit:
        result.extend(bucket_3[:limit - len(result)])
        
    return result

def questions_list(
    location_id: int, 
    offset: int = 0,
    limit: int = 10 # Max 10
    ):
    endpoint = "questions/list"
    params = {
        "location_id": location_id,
        "limit": limit,
        "offset": offset
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
        filename = f"{location_id}_questions_list.json"
        save_to_json(data, filename)
    
    return data

def answers_list(
    question_id: int, 
    offset: int = 0,
    limit: int = 10 # Max 10
    ):
    endpoint = "answers/list"
    params = {
        "question_id": question_id,
        "offset": offset,
        "limit": limit
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
        filename = f"{question_id}_answers_list.json"
        save_to_json(data, filename)
    
    return data
