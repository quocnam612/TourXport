import express from 'express';
import {
    getLocations,
    getLocationById,
    getNearbyLocations,
    searchLocations
} from '../controllers/locationsController.js';

const router = express.Router();

router.get('/', getLocations);
// router.get('/nearby', getNearbyLocations);
router.get('/:id', getLocationById);
router.post('/search', searchLocations);

export default router;