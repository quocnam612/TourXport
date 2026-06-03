import express from 'express';
import { getWeather } from '../controllers/weatherController.js';

const router = express.Router();

// GET /weather
router.get('/', getWeather);

export default router;
