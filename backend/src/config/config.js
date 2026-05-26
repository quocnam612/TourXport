import 'dotenv/config';

const config = {
    env: 'development',
    port: 3000,
    aiPort: 8000,

    jwt: {
        key: process.env.JWT_KEY || 'default_jwt_secret_key',
        expiresIn: '3d',
        algorithm: 'HS256'
    },

    search: {
        defaultLimit: 20,
        maxLimit: 100
    },

    cors: {
        allowedOrigins: ['http://localhost:3000', 'http://localhost:8000']
    },

    database: {
        uri: process.env.MONGO_URI_TEST || process.env.MONGO_URI,
    },

    aiBackend: {
        url: process.env.AI_BACKEND_URL || `http://localhost:${process.env.PORT_AI || 8000}`,
    },

    openRouteService: {
        apiKey: process.env.OPENROUTESERVICE_API_KEY,
    },

    openWeatherMap: {
        apiKey: process.env.OPENWEATHERMAP_API_KEY,
    },

    cloudinary: {
        cloudName: process.env.CLOUDINARY_CLOUD_NAME,
        apiKey: process.env.CLOUDINARY_API_KEY,
        apiSecret: process.env.CLOUDINARY_API_SECRET,
    }
};

if (!config.database.uri) {
    console.warn('WARNING: MONGO_URI is not defined in .env file!');
}

if (!config.openRouteService.apiKey) {
    console.warn('WARNING: OPENROUTESERVICE_API_KEY is not defined in .env file!');
}

if (!config.openWeatherMap.apiKey) {
    console.warn('WARNING: OPENWEATHERMAP_API_KEY is not defined in .env file!');
}

if (!config.cloudinary.cloudName || !config.cloudinary.apiKey || !config.cloudinary.apiSecret) {
    console.warn('WARNING: One or more Cloudinary configuration values are not defined in .env file!');
}

export default config;
