import express from 'express';

import * as locationController from '../controllers/locationController.js';

const router = express.Router();


// SEARCH
router.post('/search', locationController.searchLocations);


// NEARBY SEARCH
router.get('/nearby', locationController.getNearbyLocations);


// GET ALL
router.get('/', locationController.getLocations);


// GET BY ID
router.get('/:id', locationController.getLocationById);

// CREATE PLACE
router.post('/create', locationController.createLocation);

export default router;