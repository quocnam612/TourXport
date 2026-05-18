# TourXport

An AI tour generation Flutter app that plans everything you need to know for your tour of choice.

# Requirement

1. Docker
2. Flutter
3. `.env` file (look at `.env.example` file for more info)

# **Build & Debug**

## Backend

Docker compose only backend server (at project root folder)

* Windows

  ```
  docker compose up backend --build
  ```
* Linux

  ```
  docker-compose up backend --build
  ```

## AI Server

Docker compose only backend server (at project root folder)

* Windows

  ```
  docker compose up ai_backend --build
  ```
* Linux

  ```
  docker-compose up ai_backend --build
  ```

## Crawl Server

**CLI:**

1. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

2. Run the crawler using the `main.py` CLI:
   ```bash
   python src/main.py --task <task_name> --query <query_or_id> [additional_args]
   ```

**Examples:**
```bash
# Search for a location ID by name (Hanoi)
python src/main.py --task location_search --query Hanoi

# Fetch a list of restaurants by Location ID (10 results)
python src/main.py --task restaurants_list --query 293919 --limit 10

# Fetch hotel details by Location ID (check-in 01/12/2024, 2 adults)
python src/main.py --task hotels_details --query 293919 --checkin 2024-12-01 --adults 2
```

**Available tasks:**
- **Locations:** `location_search`
- **Hotels:**`hotels_list`, `hotels_details`
- **Restaurants:** `restaurants_list`, `restaurants_details`
- **Attractions:** `attractions_list`, `attractions_details`
- **Shared**: `reviews_list`, `photos_list`, `questions_list`, `answers_list`

## Application

Build & run Flutter app (at frontend folder)

  ```
  flutter run -d <YOUR_DEVICE_NAME>
  ```

or if you want to specify custom backend server:

  ```

  ```