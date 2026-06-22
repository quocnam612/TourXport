import mongoose from 'mongoose';

import HotelDB from '../models/HotelDB.js';
import PlaceDB from '../models/PlaceDB.js';
import RestaurantDB from '../models/RestaurantDB.js';
import ReviewDB from '../models/ReviewDB.js';
import UserDB from '../models/UserDB.js';

import respond from '../utils/respond.js';
import TravelAdvisor from '../services/TravelAdvisor.js';
import { deleteImage, uploadImageBuffer } from '../services/Cloudinary.js';

const locationModelByType = {
    RestaurantDB,
    HotelDB,
    PlaceDB
};

const typeAliases = {
    restaurant: 'RestaurantDB',
    restaurants: 'RestaurantDB',
    hotel: 'HotelDB',
    hotels: 'HotelDB',
    place: 'PlaceDB',
    places: 'PlaceDB'
};

const isObjectId = (value) => mongoose.Types.ObjectId.isValid(String(value));

const parsePositiveInt = (value, fallback) => {
    const parsed = Number.parseInt(value, 10);
    return Number.isInteger(parsed) && parsed > 0 ? parsed : fallback;
};

const parseNonNegativeInt = (value, fallback) => {
    const parsed = Number.parseInt(value, 10);
    return Number.isInteger(parsed) && parsed >= 0 ? parsed : fallback;
};

const normalizeType = (type) => {
    const typeValue = String(type || '').trim();
    return typeAliases[typeValue.toLowerCase()] || typeValue;
};

const getLocationModel = (type) => {
    return locationModelByType[normalizeType(type)];
};

const buildReviewPayload = (body) => {
    const payload = {};

    if (body.rating !== undefined) payload.rating = Number(body.rating);
    if (body.helpful_votes !== undefined) payload.helpful_votes = Number(body.helpful_votes);
    if (body.travel_date !== undefined) payload.travel_date = body.travel_date || null;
    if (body.title !== undefined) payload.title = body.title;
    if (body.text !== undefined) payload.text = body.text;

    return payload;
};

const toReviewResponse = (review) => ({
    id: review._id,
    userId: review.userId,
    locationId: review.locationId,
    type: review.type,
    rating: review.rating,
    helpful_votes: review.helpful_votes,
    travel_date: review.travel_date,
    title: review.title,
    text: review.text,
    user: review.user,
    images: review.images || [],
    createdAt: review.createdAt,
    updatedAt: review.updatedAt
});

export const getMyReviews = async (req, res, next) => {
    try {
        const page = parsePositiveInt(req.query.page, 1);
        const limit = Math.min(parsePositiveInt(req.query.limit, 20), 100);
        const skip = (page - 1) * limit;

        const [reviews, total] = await Promise.all([
            ReviewDB.find({ userId: req.user.id }).sort({ createdAt: -1 }).skip(skip).limit(limit),
            ReviewDB.countDocuments({ userId: req.user.id })
        ]);

        res.status(200).json({
            success: true,
            count: reviews.length,
            total,
            page,
            totalPages: Math.ceil(total / limit),
            data: reviews.map(toReviewResponse)
        });
    } catch (error) {
        next(error);
    }
};

export const createReview = async (req, res, next) => {
    try {
        const { locationId, type } = req.body;
        const normalizedType = normalizeType(type);
        const LocationModel = getLocationModel(normalizedType);

        if (!LocationModel) {
            return next(respond.httpError('type must be RestaurantDB, HotelDB, or PlaceDB', 400));
        }

        if (!isObjectId(locationId)) {
            return next(respond.httpError('locationId must be a valid MongoDB ObjectId', 400));
        }

        const [location, currentUser, existingReview] = await Promise.all([
            LocationModel.findById(locationId),
            UserDB.findById(req.user.id),
            ReviewDB.findOne({ userId: req.user.id, locationId, type: normalizedType })
        ]);

        if (!location) {
            return next(respond.httpError('Location not found', 404));
        }

        if (!currentUser) {
            return next(respond.httpError('User not found', 404));
        }

        if (existingReview) {
            return next(respond.httpError('You already reviewed this location', 409));
        }

        // Upload images to Cloudinary if provided
        let images = [];
        if (req.files && req.files.length > 0) {
            const uploadPromises = req.files.map(file => 
                uploadImageBuffer(file.buffer, { folder: 'tourxport/reviews' })
            );
            const uploadResults = await Promise.all(uploadPromises);
            images = uploadResults.map(result => ({
                url: result.secure_url,
                public_id: result.public_id
            }));
        }

        const review = await ReviewDB.create({
            ...buildReviewPayload(req.body),
            userId: req.user.id,
            locationId,
            type: normalizedType,
            images,
            user: {
                username: currentUser.name,
                avatar: {
                    url: currentUser.avatar?.url || '',
                    public_id: currentUser.avatar?.public_id || ''
                }
            }
        });

        await LocationModel.findByIdAndUpdate(locationId, { $inc: { reviewsCount: 1 } });

        res.status(201).json({
            success: true,
            message: 'Review created successfully!',
            data: toReviewResponse(review)
        });
    } catch (error) {
        next(error);
    }
};

export const getReviewsByLocation = async (req, res, next) => {
    try {
        const { locationId } = req.params;
        const type = normalizeType(req.params.type);
        const LocationModel = getLocationModel(type);

        if (!LocationModel) {
            return next(respond.httpError('type must be RestaurantDB, HotelDB, or PlaceDB', 400));
        }

        if (!isObjectId(locationId)) {
            return next(respond.httpError('locationId must be a valid MongoDB ObjectId', 400));
        }

        const page = parsePositiveInt(req.query.page, 1);
        const limit = Math.min(parsePositiveInt(req.query.limit, 20), 100);
        const skip = (page - 1) * limit;
        const apiLimit = Math.min(parsePositiveInt(req.query.apiLimit, limit), 20);
        const apiOffset = parseNonNegativeInt(req.query.apiOffset, 0);

        const [location, dbReviews] = await Promise.all([
            LocationModel.findById(locationId).select('sourceLocationId title'),
            ReviewDB.find({ locationId, type }).sort({ createdAt: -1 }).skip(skip).limit(limit)
        ]);

        if (!location) {
            return next(respond.httpError('Location not found', 404));
        }

        const apiReviews = await TravelAdvisor.getReviewsBySourceLocationId(location.sourceLocationId, {
            locationId,
            type,
            limit: apiLimit,
            offset: apiOffset,
            currency: req.query.currency || 'USD',
            lang: req.query.lang || 'vi_VN',
            keyword: req.query.keyword
        }).catch((error) => {
            console.warn(`Travel Advisor reviews skipped: ${error.message}`);
            return [];
        });

        res.status(200).json({
            success: true,
            location: {
                id: location._id,
                type,
                title: location.title,
                sourceLocationId: location.sourceLocationId || null
            },
            count: dbReviews.length + apiReviews.length,
            data: [
                ...dbReviews.map(toReviewResponse),
                ...apiReviews
            ]
        });
    } catch (error) {
        next(error);
    }
};

export const updateReview = async (req, res, next) => {
    try {
        const { reviewId } = req.params;

        if (!isObjectId(reviewId)) {
            return next(respond.httpError('reviewId must be a valid MongoDB ObjectId', 400));
        }

        const payload = buildReviewPayload(req.body);
        if (Object.keys(payload).length === 0 && (!req.files || req.files.length === 0)) {
            return next(respond.httpError('No fields provided for update', 400));
        }

        const oldReview = await ReviewDB.findOne({ _id: reviewId, userId: req.user.id });
        if (!oldReview) {
            return next(respond.httpError('Review not found', 404));
        }

        let newImages = undefined;
        if (req.files && req.files.length > 0) {
            const uploadPromises = req.files.map(file => 
                uploadImageBuffer(file.buffer, { folder: 'tourxport/reviews' })
            );
            const uploadResults = await Promise.all(uploadPromises);
            newImages = uploadResults.map(result => ({
                url: result.secure_url,
                public_id: result.public_id
            }));
            payload.images = newImages;
        }

        const review = await ReviewDB.findOneAndUpdate(
            { _id: reviewId, userId: req.user.id },
            { $set: payload },
            { new: true, runValidators: true }
        );

        if (newImages && oldReview.images && oldReview.images.length > 0) {
            const deletePromises = oldReview.images
                .filter(img => img.public_id)
                .map(img => deleteImage(img.public_id));
            Promise.all(deletePromises).catch((error) => {
                console.error('Failed to delete old review images on update:', error.message || error);
            });
        }

        res.status(200).json({
            success: true,
            message: 'Review updated successfully!',
            data: toReviewResponse(review)
        });
    } catch (error) {
        next(error);
    }
};

export const deleteReview = async (req, res, next) => {
    try {
        const { reviewId } = req.params;

        if (!isObjectId(reviewId)) {
            return next(respond.httpError('reviewId must be a valid MongoDB ObjectId', 400));
        }

        const review = await ReviewDB.findOneAndDelete({
            _id: reviewId,
            userId: req.user.id
        });

        if (!review) {
            return next(respond.httpError('Review not found', 404));
        }

        if (review.images && review.images.length > 0) {
            const deletePromises = review.images
                .filter(img => img.public_id)
                .map(img => deleteImage(img.public_id));
            Promise.all(deletePromises).catch((error) => {
                console.error('Failed to delete review images:', error.message || error);
            });
        }

        const LocationModel = getLocationModel(review.type);
        if (LocationModel) {
            await LocationModel.findByIdAndUpdate(review.locationId, { $inc: { reviewsCount: -1 } });
        }

        res.status(200).json({
            success: true,
            message: 'Review deleted successfully!',
            deletedId: review._id
        });
    } catch (error) {
        next(error);
    }
};
