import express from 'express';

import { authenticate } from '../middlewares/authMiddleware.js';
import * as reviewController from '../controllers/reviewController.js';

const router = express.Router();

router.route('/my-reviews')
    .get(authenticate, reviewController.getMyReviews)
    .post(authenticate, reviewController.createReview);

router.route('/my-reviews/:reviewId')
    .put(authenticate, reviewController.updateReview)
    .delete(authenticate, reviewController.deleteReview);

router.get('/:type/:locationId', reviewController.getReviewsByLocation);

export default router;
