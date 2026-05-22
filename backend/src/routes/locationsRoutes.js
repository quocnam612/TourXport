import express from 'express';

import * as locationController from '../controllers/locationController.js';

const router = express.Router();

router.post('/search', locationController.searchLocations);

router.get('/nearby', locationController.getNearbyLocations);

router.get('/', locationController.getLocations);

router.get('/:id', locationController.getLocationById);

export default router;