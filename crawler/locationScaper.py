import asyncio
from playwright.async_api import async_playwright

async def scrape_vung_tau_food():
    async with async_playwright() as p:
        # Launch browser (headless=False lets you see the magic happen)
        browser = await p.chromium.launch(headless=False)
        page = await browser.new_page()
        
        # We're hitting a search query for Vũng Tàu restaurants
        search_url = "https://www.google.com/maps/search/nhà+hàng+Vũng+Tàu"
        print(f"🚀 Navigating to: {search_url}")
        await page.goto(search_url)

        # Wait for the results to actually load
        await page.wait_for_selector('div[role="feed"]')

        # Basic logic to grab the first few results
        # Note: In a real "pro" tool, you'd add a loop to scroll down the sidebar
        locations = await page.query_selector_all('div[role="article"]')
        
        food_data = []

        for loc in locations[:10]:  # Let's grab the top 10 for now
            name_element = await loc.query_selector('.qBF1Pd')
            rating_element = await loc.query_selector('.MW4T7d')
            
            name = await name_element.inner_text() if name_element else "Unknown"
            rating = await rating_element.inner_text() if rating_element else "No rating"
            
            food_data.append({"name": name, "rating": rating})

        print("\n--- 🔥 VŨNG TÀU FOOD LOCATIONS FOUND ---")
        for item in food_data:
            print(f"📍 {item['name']} | ⭐ {item['rating']}")

        await browser.close()

if __name__ == "__main__":
    asyncio.run(scrape_vung_tau_food())