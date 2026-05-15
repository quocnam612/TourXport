import express from 'express';
import cors from 'cors';
import mongoose from 'mongoose';

import config from './config/config.js'; 
import authRoutes from './routes/authRoutes.js';
import locationsRoutes from './routes/locationsRoutes.js';
// import tourRoutes from './routes/tourRoutes.js';

const app = express();

// Middleware
app.use(express.json());
app.use(cors());

// API routes
app.use('/auth', authRoutes);
app.use('/locations', locationsRoutes);
// app.use('/tours', tourRoutes);

// Global error handler
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({
        success: false,
        message: 'Something went wrong on the server!',
        error: err.message
    });
});

// Database connection
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