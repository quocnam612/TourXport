import argparse
import asyncio
import sys
import os

# Ensure src is in the python path
sys.path.append(os.path.join(os.path.dirname(__file__), ".."))

from src.services.location_service import locations_search
from src.services.hotels import hotels_list_id, hotels_get_details
from src.services.google_maps_service import scrape_gmaps_restaurants
from src.services.restaurants import restaurants_list, restaurants_get_details
from src.services.attractions import attractions_list, attractions_get_details
from src.services.shared import reviews_list, photos_list, questions_list, answers_list

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
    parser = argparse.ArgumentParser(description="TourXport Crawler CLI")
    parser.add_argument("--task", type=str, required=True, 
                        choices=[
                            "location_search", 
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
    parser.add_argument("--query", type=str, required=True,
                        help="The search query, location ID, or question ID.")
    parser.add_argument("--adults", type=int, default=1, help="Number of adults (for hotels_list).")
    parser.add_argument("--rooms", type=int, default=1, help="Number of rooms (for hotels_list).")
    parser.add_argument("--nights", type=int, default=1, help="Number of nights (for hotels_list).")

    args, unknown = parser.parse_known_args()
    kwargs = parse_kwargs(unknown)

    if args.task == "location_search":
        print(f"Searching for: {args.query} with {kwargs}")
        locations_search(query=args.query, **kwargs)
        
    elif args.task == "google-maps":
        print(f"Running Google Maps scraper for: {args.query}")
        asyncio.run(scrape_gmaps_restaurants(query=args.query))
        
    else:
        # All other tasks expect an integer ID
        try:
            target_id = int(args.query)
        except ValueError:
            print(f"Error: query must be a valid integer ID for task '{args.task}'.")
            return

        if args.task == "hotels_list":
            print(f"Fetching hotels for location_id: {target_id} with {kwargs}")
            hotels_list_id(location_id=target_id, adults=args.adults, rooms=args.rooms, nights=args.nights, **kwargs)
            
        elif args.task == "hotels_details":
            print(f"Fetching hotel details for location_id: {target_id} with {kwargs}")
            hotels_get_details(location_id=target_id, **kwargs)
            
        elif args.task == "restaurants_list":
            print(f"Fetching restaurants for location_id: {target_id} with {kwargs}")
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
