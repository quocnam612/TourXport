import express from 'express';

import { authenticate } from '../middlewares/authMiddleware.js';
import { uploadAvatar } from '../middlewares/uploadMiddleware.js';
import * as userController from '../controllers/userController.js';

const router = express.Router();

router.post('/register', userController.register);
router.post('/login', userController.login);
router.post('/google', userController.googleLogin);
router.post('/facebook', userController.facebookLogin);

router.route('/profile')
    .get(authenticate, userController.getProfile)
    .put(authenticate, userController.updateProfile);

router.put('/profile/avatar', authenticate, uploadAvatar.single('avatar'), userController.updateAvatar);
    
router.put('/profile/change-password', authenticate, userController.changePassword);
router.put('/profile/add-login-method', authenticate, userController.addLoginMethod);

router.route('/profile/saved-places')
    .get(authenticate, userController.getSavedPlaces)
    .post(authenticate, userController.addSavedPlace);
router.delete('/profile/saved-places/:id', authenticate, userController.removeSavedPlace);

router.route('/profile/saved-tours')
    .get(authenticate, userController.getSavedTours)
    .post(authenticate, userController.addSavedTour);
router.delete('/profile/saved-tours/:id', authenticate, userController.removeSavedTour);

export default router;
