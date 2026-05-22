import express from 'express';

import * as locationController from '../controllers/locationController.js';

const router = express.Router();

// SEARCH LOCATIONS
router.post(
    '/search',
    locationController.searchLocations
);

// GET NEARBY LOCATIONS
router.get(
    '/nearby',
    locationController.getNearbyLocations
);

// GET ALL LOCATIONS
router.get(
    '/',
    locationController.getLocations
);

// GET LOCATION BY ID
router.get(
    '/:id',
    locationController.getLocationById
);

export default router;