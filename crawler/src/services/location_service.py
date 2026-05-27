from src.core.travel_advisor import travel_advisor_client
from src.utils.file_io import save_to_json

def auto_complete_v2(name: str, lang: str = "vi_VN", units: str = "km"):
    endpoint = "locations/v2/auto-complete"
    params = {
        "query": name,
        "lang": lang,
        "units": units
    }
    
    print(f"Auto-complete: {name}...")
    try:
        data = travel_advisor_client.get(endpoint, params)
    except Exception as e:
        print(f"Error fetching data: {e}")
        return None
    
    filename = f"{name.replace(' ', '_').lower()}_locations.json"
    save_to_json(data, filename)
    return data

def locations_search(query: str, lang: str = "vi_VN", units: str = "km", save_raw: bool = True):
    endpoint = "locations/search"
    params = {
        "query": query,
        "lang": lang,
        "units": units
    }
    try:
        data = travel_advisor_client.get(endpoint, params)
    except Exception as e:
        print(f"Error fetching data: {e}")
        return None
    
    if save_raw:
        filename = f"{query.replace(' ', '_').lower()}_search.json"
        save_to_json(data, filename)
    return data
