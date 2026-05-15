import express from 'express';

import * as locationController from '../controllers/locationController.js';

const router = express.Router();

router.get('/', locationController.getLocations);
router.get('/:id', locationController.getLocationById);
router.post('/search', locationController.searchLocations);

export default router;