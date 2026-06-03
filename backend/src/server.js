import express from 'express';
import cors from 'cors';
import mongoose from 'mongoose';

import config from './config/config.js';
import errorMiddleware from './middlewares/errorMiddleware.js';

import authRoutes from './routes/authRoutes.js';
import hotelRoutes from './routes/hotelRoutes.js';
import locationsRoutes from './routes/locationRoutes.js';
import restaurantRoutes from './routes/restaurantRoutes.js';
import reviewRoutes from './routes/reviewRoutes.js';
import tourRoutes from './routes/tourRoutes.js';
import weatherRoutes from './routes/weatherRoutes.js';

const app = express();

app.use(express.json());
app.use(cors());

// API routes
app.use('/auth', authRoutes);
app.use('/locations', locationsRoutes);
app.use('/hotels', hotelRoutes);
app.use('/restaurants', restaurantRoutes);
app.use('/tours', tourRoutes);
app.use('/reviews', reviewRoutes);
app.use('/weather', weatherRoutes);

// Default route
app.get('/', (req, res, next) => {
    res.status(200).json({
        success: true,
        message: 'Welcome to Smart Tourism API'
    });
});

app.use((req, res, next) => {
    res.status(404).json({
        success: false,
        message: 'Route not found'
    });
});

app.use(errorMiddleware);

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
