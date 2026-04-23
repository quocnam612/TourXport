import express from 'express';
import {
    getLocations,
    getLocationById,
    getNearby,
    searchLocations
} from '../controllers/locationsController.js';

const router = express.Router();

router.get('/', getLocations);
// router.get('/nearby', getNearby);
router.get('/:id', getLocationById);
router.post('/search', searchLocations);

export default router;