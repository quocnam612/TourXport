import asyncio
from playwright.async_api import async_playwright
from src.utils.file_io import save_to_json

async def scrape_gmaps_restaurants(query: str):
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=False)
        page = await browser.new_page()
        
        # Format query for URL
        formatted_query = query.replace(" ", "+")
        search_url = f"https://www.google.com/maps/search/{formatted_query}"
        print(f"🚀 Navigating to: {search_url}")
        await page.goto(search_url)

        # Wait for the results to actually load
        try:
            await page.wait_for_selector('div[role="feed"]', timeout=10000)
        except Exception as e:
            print("❌ Could not find the feed element within timeout. The page layout might be different.")
            await browser.close()
            return []

        locations = await page.query_selector_all('div[role="article"]')
        
        food_data = []

        for loc in locations[:10]:
            name_element = await loc.query_selector('.qBF1Pd')
            rating_element = await loc.query_selector('.MW4T7d')
            
            name = await name_element.inner_text() if name_element else "Unknown"
            rating = await rating_element.inner_text() if rating_element else "No rating"
            
            food_data.append({"name": name, "rating": rating})

        print(f"\n--- 🔥 {query.upper()} LOCATIONS FOUND ---")
        for item in food_data:
            print(f"📍 {item['name']} | ⭐ {item['rating']}")

        await browser.close()
        
        filename = f"{query.replace(' ', '_').lower()}_gmaps.json"
        save_to_json(food_data, filename)
        return food_data
