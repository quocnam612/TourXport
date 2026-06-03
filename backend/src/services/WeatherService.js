import config from '../config/config.js';

const WEATHER_API_URL = 'https://api.openweathermap.org/data/2.5';
const CACHE_TTL_MS = 30 * 60 * 1000; // 30 minutes in milliseconds
const cache = new Map();

/**
 * Rounds a coordinate to 2 decimal places for efficient caching of geographic areas (~1.1 km accuracy)
 */
const getCacheKey = (lat, lon) => {
    return `${Number(lat).toFixed(2)}_${Number(lon).toFixed(2)}`;
};

/**
 * Clean up expired items in cache to prevent memory leak
 */
const cleanExpiredCache = () => {
    const now = Date.now();
    for (const [key, value] of cache.entries()) {
        if (now - value.timestamp > CACHE_TTL_MS) {
            cache.delete(key);
        }
    }
};

/**
 * Get current weather and forecast for latitude and longitude
 */
export const getWeatherByCoordinates = async (lat, lon) => {
    if (!lat || !lon) {
        throw new Error('Latitude and Longitude are required');
    }

    const apiKey = config.openWeatherMap.apiKey;
    if (!apiKey) {
        throw new Error('OPENWEATHERMAP_API_KEY is not defined in backend env');
    }

    cleanExpiredCache();

    const cacheKey = getCacheKey(lat, lon);
    const cachedData = cache.get(cacheKey);
    const now = Date.now();

    if (cachedData && (now - cachedData.timestamp < CACHE_TTL_MS)) {
        console.log(`[WeatherService] Returning cached weather for key: ${cacheKey}`);
        return cachedData.data;
    }

    try {
        console.log(`[WeatherService] Fetching fresh weather from OpenWeatherMap for lat: ${lat}, lon: ${lon}`);
        
        // Fetch current weather and 5-day / 3-hour forecast in parallel
        const [currentRes, forecastRes] = await Promise.all([
            fetch(`${WEATHER_API_URL}/weather?lat=${lat}&lon=${lon}&appid=${apiKey}&units=metric&lang=vi`),
            fetch(`${WEATHER_API_URL}/forecast?lat=${lat}&lon=${lon}&appid=${apiKey}&units=metric&lang=vi`)
        ]);

        if (!currentRes.ok) {
            const errBody = await currentRes.json().catch(() => null);
            throw new Error(errBody?.message || `Current weather failed with status ${currentRes.status}`);
        }

        if (!forecastRes.ok) {
            const errBody = await forecastRes.json().catch(() => null);
            throw new Error(errBody?.message || `Forecast weather failed with status ${forecastRes.status}`);
        }

        const currentData = await currentRes.json();
        const forecastData = await forecastRes.json();

        // Process forecast data to get one representative forecast per day (at 12:00 PM / midday if possible)
        const dailyForecasts = [];
        const seenDays = new Set();
        const currentLocalDateString = new Date(currentData.dt * 1000).toDateString();

        for (const item of forecastData.list) {
            const date = new Date(item.dt * 1000);
            const dateString = date.toDateString();

            // Skip today's forecast since we have current weather
            if (dateString === currentLocalDateString) continue;

            // Pick midday forecast (12:00:00) or first forecast seen for future days
            const timeStr = date.toTimeString();
            const isMidDay = timeStr.includes('12:00') || timeStr.includes('13:00') || timeStr.includes('11:00');

            if (!seenDays.has(dateString) || isMidDay) {
                // If it's mid-day, overwrite the day's first forecast to ensure high quality daytime weather prediction
                const formatted = {
                    date: date.toISOString(),
                    temp: item.main.temp,
                    tempMin: item.main.temp_min,
                    tempMax: item.main.temp_max,
                    weather: item.weather[0]?.main,
                    description: item.weather[0]?.description,
                    icon: item.weather[0]?.icon,
                    humidity: item.main.humidity
                };

                const existingIndex = dailyForecasts.findIndex(f => new Date(f.date).toDateString() === dateString);
                if (existingIndex !== -1) {
                    dailyForecasts[existingIndex] = formatted;
                } else {
                    dailyForecasts.push(formatted);
                    seenDays.add(dateString);
                }
            }
        }

        const result = {
            current: {
                temp: currentData.main.temp,
                tempMin: currentData.main.temp_min,
                tempMax: currentData.main.temp_max,
                weather: currentData.weather[0]?.main,
                description: currentData.weather[0]?.description,
                icon: currentData.weather[0]?.icon,
                humidity: currentData.main.humidity,
                cityName: currentData.name
            },
            forecast: dailyForecasts.slice(0, 3) // Return 3 days forecast
        };

        // Save to cache
        cache.set(cacheKey, {
            timestamp: now,
            data: result
        });

        return result;

    } catch (error) {
        console.error(`[WeatherService] Error fetching weather data: ${error.message}`);
        throw error;
    }
};

export default {
    getWeatherByCoordinates
};
