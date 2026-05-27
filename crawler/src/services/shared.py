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
    
    if data:
        filename = f"{location_id}_photos_list.json"
        save_to_json(data, filename)
    
    return data

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
