import express from 'express';

import { authenticate } from '../middlewares/authMiddleware.js';
import { uploadReviewImages } from '../middlewares/uploadMiddleware.js';
import * as reviewController from '../controllers/reviewController.js';

const router = express.Router();

router.route('/my-reviews')
    .get(authenticate, reviewController.getMyReviews)
    .post(authenticate, uploadReviewImages.array('images', 5), reviewController.createReview);

router.route('/my-reviews/:reviewId')
    .put(authenticate, uploadReviewImages.array('images', 5), reviewController.updateReview)
    .delete(authenticate, reviewController.deleteReview);

router.get('/:type/:locationId', reviewController.getReviewsByLocation);

export default router;
