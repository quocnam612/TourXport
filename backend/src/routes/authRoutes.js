import express from 'express';
import {
    register,
    login,
    getProfile,
    getSavedPlaces,
    addSavedPlace,
    removeSavedPlace,
    updateProfile
} from '../controllers/authController.js';
import { authenticate } from '../middlewares/authMiddleware.js';

// import { upload } from '../middlewares/uploadMiddleware.js';

const router = express.Router();

router.post('/register', register);
router.post('/login', login);
router.get('/profile', authenticate, getProfile);
router.put('/profile', authenticate, updateProfile);
// router.post('/upload', authenticate, upload.single('image'), (req, res) => {
//     if (!req.file) {
//         return res.status(400).json({ success: false, message: 'No file uploaded' });
//     }
//     const imageUrl = `/uploads/${req.file.filename}`;
//     res.json({ success: true, imageUrl });
// });

// Saved places routes
router.get('/saved-places', authenticate, getSavedPlaces);
router.post('/saved-places', authenticate, addSavedPlace);
router.delete('/saved-places', authenticate, removeSavedPlace);

export default router;