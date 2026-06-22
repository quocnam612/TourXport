import 'dotenv/config';

const isProduction = process.env.NODE_ENV === 'production';
const defaultAiBackendUrl = isProduction
    ? 'https://tourxport-ai-backend.onrender.com'
    : `http://localhost:${process.env.PORT_AI || 8000}`;
const rapidApiKeys = (process.env.RAPIDAPI_KEYS || process.env.RAPIDAPI_KEY_POOL || '')
    .split(/[,\s;]+/)
    .map((key) => key.trim())
    .filter(Boolean);

const config = {
    env: process.env.NODE_ENV || 'development',
    port: Number(process.env.PORT || process.env.PORT_BACKEND || 3000),
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
        url: process.env.AI_BACKEND_URL || process.env.AI_BASE_URL || defaultAiBackendUrl,
        pingAttempts: Number(process.env.AI_BACKEND_PING_ATTEMPTS || 2),
        pingDelayMs: Number(process.env.AI_BACKEND_PING_DELAY_MS || 60000),
        pingTimeoutMs: Number(process.env.AI_BACKEND_PING_TIMEOUT_MS || 15000),
        requestTimeoutMs: Number(process.env.AI_BACKEND_REQUEST_TIMEOUT_MS || 120000),
    },

    travelAdvisor: {
        apiKey: process.env.RAPIDAPI_KEY || rapidApiKeys[0],
        apiKeys: rapidApiKeys,
        host: process.env.RAPIDAPI_HOST || 'travel-advisor.p.rapidapi.com',
    },

    google: {
        clientId: process.env.GOOGLE_CLIENT_ID,
    },

    discord: {
        clientId: process.env.DISCORD_CLIENT_ID,
        clientSecret: process.env.DISCORD_CLIENT_SECRET,
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

if (!config.travelAdvisor.apiKey) {
    console.warn('WARNING: RAPIDAPI_KEY or RAPIDAPI_KEYS is not defined in .env file!');
}

if (!config.cloudinary.cloudName || !config.cloudinary.apiKey || !config.cloudinary.apiSecret) {
    console.warn('WARNING: One or more Cloudinary configuration values are not defined in .env file!');
}

if (!config.google.clientId) {
    console.warn('WARNING: GOOGLE_CLIENT_ID is not defined in .env file!');
}

if (!config.discord.clientId || !config.discord.clientSecret) {
    console.warn('WARNING: DISCORD_CLIENT_ID or DISCORD_CLIENT_SECRET is not defined in .env file!');
}

export default config;
