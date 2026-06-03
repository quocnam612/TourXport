import { getWeatherByCoordinates } from '../services/WeatherService.js';

export const getWeather = async (req, res, next) => {
    const { lat, lon } = req.query;

    if (!lat || !lon) {
        return res.status(400).json({
            success: false,
            message: 'Both latitude (lat) and longitude (lon) query parameters are required.'
        });
    }

    try {
        const weatherData = await getWeatherByCoordinates(lat, lon);
        return res.status(200).json({
            success: true,
            data: weatherData
        });
    } catch (error) {
        // Pass error to express error handling middleware
        next(error);
    }
};

export default {
    getWeather
};
