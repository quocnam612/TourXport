import AppReviewDB from '../models/AppReviewDB.js';
import UserDB from '../models/UserDB.js';
import respond from '../utils/respond.js';
import { parsePositiveInt } from '../utils/parser.js';

const toAppReviewResponse = (review) => ({
    id: review._id,
    userId: review.userId,
    rating: review.rating,
    title: review.title,
    text: review.text,
    user: review.user,
    helpful_votes: review.helpful_votes,
    createdAt: review.createdAt,
    updatedAt: review.updatedAt
});

export const createAppReview = async (req, res, next) => {
    try {
        const { rating, title, text } = req.body;

        // Validate input
        if (!rating || !title || !text) {
            return next(respond.httpError('Rating, title, and text are required', 400));
        }

        if (rating < 1 || rating > 5) {
            return next(respond.httpError('Rating must be between 1 and 5', 400));
        }

        if (title.trim().length === 0 || title.trim().length > 100) {
            return next(respond.httpError('Title must be between 1 and 100 characters', 400));
        }

        if (text.trim().length === 0 || text.trim().length > 1000) {
            return next(respond.httpError('Text must be between 1 and 1000 characters', 400));
        }

        // Get user info
        const user = await UserDB.findById(req.user.id);
        if (!user) {
            return next(respond.httpError('User not found', 404));
        }

        // Create review
        const review = new AppReviewDB({
            userId: req.user.id,
            rating: Math.round(rating),
            title: title.trim(),
            text: text.trim(),
            user: {
                username: user.name || user.email,
                avatar: user.avatar || { url: '', public_id: '' }
            }
        });

        await review.save();

        res.status(201).json({
            success: true,
            data: toAppReviewResponse(review)
        });
    } catch (error) {
        next(error);
    }
};

export const getAppReviews = async (req, res, next) => {
    try {
        const page = parsePositiveInt(req.query.page, 1);
        const limit = Math.min(parsePositiveInt(req.query.limit, 20), 100);
        const skip = (page - 1) * limit;

        const [reviews, total] = await Promise.all([
            AppReviewDB.find()
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(limit),
            AppReviewDB.countDocuments()
        ]);

        res.status(200).json({
            success: true,
            count: reviews.length,
            total,
            page,
            totalPages: Math.ceil(total / limit),
            data: reviews.map(toAppReviewResponse)
        });
    } catch (error) {
        next(error);
    }
};

export const getMyAppReviews = async (req, res, next) => {
    try {
        const page = parsePositiveInt(req.query.page, 1);
        const limit = Math.min(parsePositiveInt(req.query.limit, 20), 100);
        const skip = (page - 1) * limit;

        const [reviews, total] = await Promise.all([
            AppReviewDB.find({ userId: req.user.id })
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(limit),
            AppReviewDB.countDocuments({ userId: req.user.id })
        ]);

        res.status(200).json({
            success: true,
            count: reviews.length,
            total,
            page,
            totalPages: Math.ceil(total / limit),
            data: reviews.map(toAppReviewResponse)
        });
    } catch (error) {
        next(error);
    }
};

export const updateAppReview = async (req, res, next) => {
    try {
        const { reviewId } = req.params;
        const { rating, title, text } = req.body;

        const review = await AppReviewDB.findById(reviewId);
        if (!review) {
            return next(respond.httpError('Review not found', 404));
        }

        // Check ownership
        if (review.userId.toString() !== req.user.id) {
            return next(respond.httpError('You can only edit your own reviews', 403));
        }

        // Validate input
        if (rating && (rating < 1 || rating > 5)) {
            return next(respond.httpError('Rating must be between 1 and 5', 400));
        }

        if (title && (title.trim().length === 0 || title.trim().length > 100)) {
            return next(respond.httpError('Title must be between 1 and 100 characters', 400));
        }

        if (text && (text.trim().length === 0 || text.trim().length > 1000)) {
            return next(respond.httpError('Text must be between 1 and 1000 characters', 400));
        }

        // Update fields
        if (rating) review.rating = Math.round(rating);
        if (title) review.title = title.trim();
        if (text) review.text = text.trim();

        await review.save();

        res.status(200).json({
            success: true,
            data: toAppReviewResponse(review)
        });
    } catch (error) {
        next(error);
    }
};

export const deleteAppReview = async (req, res, next) => {
    try {
        const { reviewId } = req.params;

        const review = await AppReviewDB.findById(reviewId);
        if (!review) {
            return next(respond.httpError('Review not found', 404));
        }

        // Check ownership
        if (review.userId.toString() !== req.user.id) {
            return next(respond.httpError('You can only delete your own reviews', 403));
        }

        await AppReviewDB.findByIdAndDelete(reviewId);

        res.status(200).json({
            success: true,
            message: 'Review deleted successfully'
        });
    } catch (error) {
        next(error);
    }
};
