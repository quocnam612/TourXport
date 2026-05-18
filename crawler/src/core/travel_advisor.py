import requests
from src.core.config import settings

class TravelAdvisorClient:
    def __init__(self):
        self.base_url = f"https://{settings.RAPIDAPI_HOST}"
        self.headers = {
            "x-rapidapi-key": settings.RAPIDAPI_KEY,
            "x-rapidapi-host": settings.RAPIDAPI_HOST,
            "Content-Type": "application/json"
        }

    def get(self, endpoint: str, params: dict):
        url = f"{self.base_url}/{endpoint}"
        response = requests.get(url, headers=self.headers, params=params)
        response.raise_for_status()
        return response.json()

travel_advisor_client = TravelAdvisorClient()
