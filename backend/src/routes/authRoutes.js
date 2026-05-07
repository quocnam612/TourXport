import express from 'express';
import {
    register,
    login,
    getSavedPlaces,
    addSavedPlace,
    removeSavedPlace
} from '../controllers/authController.js';
import { authenticate } from '../middleware/authMiddleware.js';

const router = express.Router();

router.post('/register', register);
router.post('/login', login);

// Saved places routes
router.get('/saved-places', authenticate, getSavedPlaces);
router.post('/saved-places', authenticate, addSavedPlace);
router.delete('/saved-places', authenticate, removeSavedPlace);

export default router;