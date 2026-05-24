import express from 'express';

import { authenticate } from '../middlewares/authMiddleware.js';
import * as userController from '../controllers/userController.js';

const router = express.Router();

router.post('/register', userController.register);
router.post('/login', userController.login);

router.route('/profile')
    .get(authenticate, userController.getProfile)
    .put(authenticate, userController.updateProfile);
router.put('/profile/change-password', authenticate, userController.changePassword);

router.route('/profile/saved-places')
    .get(authenticate, userController.getSavedPlaces)
    .post(authenticate, userController.addSavedPlace);
router.delete('/profile/saved-places/:id', authenticate, userController.removeSavedPlace);

router.route('/profile/saved-tours')
    .get(authenticate, userController.getSavedTours)
    .post(authenticate, userController.addSavedTour);
router.delete('/profile/saved-tours/:id', authenticate, userController.removeSavedTour);

export default router;