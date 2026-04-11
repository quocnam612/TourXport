import 'dotenv/config';

const config = {
    env: process.env.NODE_ENV || 'development',
    port: parseInt(process.env.PORT_BACKEND) || 3000,
    aiPort: parseInt(process.env.PORT_AI) || 8000,

    jwt: {
        key: process.env.JWT_KEY || 'default_jwt_secret_key',
        expiresIn: process.env.JWT_EXPIRATION || '3d'
    },

    crawler: {
        delay: parseInt(process.env.CRAWL_DELAY) || 2,
    },

    cors: {
        allowedOrigins: process.env.ALLOWED_ORIGINS ? process.env.ALLOWED_ORIGINS.split(',') : ['http://localhost:3000']
    },

    database: {
        uri: process.env.MONGO_URI_TEST || process.env.MONGO_URI,
    },

    openai: {
        apiKey: process.env.OPENAI_API_KEY,
    }
};

if (!config.database.uri) {
    console.warn('WARNING: MONGO_URI is not defined in .env file!');
}

if (!config.openai.apiKey) {
    console.warn('WARNING: OPENAI_API_KEY is not defined in .env file!');
}

export default config;