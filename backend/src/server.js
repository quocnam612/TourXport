import express from 'express';
import cors from 'cors';
import mongoose from 'mongoose';

import config from './config/config.js'; 
import authRoutes from './routes/authRoutes.js';
import locationsRoutes from './routes/locationsRoutes.js';

const app = express();

// Middlewares
app.use(express.json());
app.use(cors({origin: config.cors.allowedOrigins}));

// API routes
app.use('/auth', authRoutes);
app.use('/locations', locationsRoutes);

mongoose.connect(config.database.uri)
.then(() => {
    console.log('✅ Connected to MongoDB Atlas');
    app.listen(config.port, () => {
        console.log(`🚀 Server running on http://localhost:${config.port}`);
        console.log(`🌍 Environment: ${config.env}`);
    });
})
.catch((err) => {
    console.error('❌ Database connection error:', err.message);
});