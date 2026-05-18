import os
from dotenv import load_dotenv

# Load variables from .env file at the outermost project folder (TourXport/TourXport)
dotenv_path = os.path.join(os.path.dirname(__file__), "..", "..", "..", ".env")
load_dotenv(dotenv_path)

class Settings:
    RAPIDAPI_KEY: str = os.getenv("RAPIDAPI_KEY", "")
    RAPIDAPI_HOST: str = "travel-advisor.p.rapidapi.com"
    
settings = Settings()
