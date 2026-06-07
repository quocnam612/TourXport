import express from 'express';
import { authenticate } from '../middlewares/authMiddleware.js';
import * as appReviewController from '../controllers/appReviewController.js';

const router = express.Router();

// Public: Get all app reviews (paginated)
router.get('/', appReviewController.getAppReviews);

// Authenticated: Get my app reviews
router.get('/my-reviews', authenticate, appReviewController.getMyAppReviews);

// Authenticated: Create app review
router.post('/', authenticate, appReviewController.createAppReview);

// Authenticated: Update my app review
router.put('/:reviewId', authenticate, appReviewController.updateAppReview);

// Authenticated: Delete my app review
router.delete('/:reviewId', authenticate, appReviewController.deleteAppReview);

export default router;
