import RestaurantDB from '../models/RestaurantDB.js';
import config from '../config/config.js';
import parser from '../utils/parser.js';
import respond from '../utils/respond.js';
import validator from '../utils/validators.js';
import TravelAdvisor from '../services/TravelAdvisor.js';

const locationPublicProjection = '-embedding -searchText';

const hydrateRestaurantImages = async (restaurant) => {
    if (!restaurant || !restaurant.sourceLocationId || (Array.isArray(restaurant.images) && restaurant.images.length > 0)) {
        return restaurant;
    }

    try {
        const images = await TravelAdvisor.getHighQualityPhotosBySourceLocationId(restaurant.sourceLocationId, {
            excludeUrls: [restaurant.image?.url],
            limit: 10
        });

        if (!images.length) {
            return restaurant;
        }

        return await RestaurantDB.findByIdAndUpdate(
            restaurant._id,
            { $set: { images } },
            { new: true, runValidators: true }
        ).select(locationPublicProjection);
    } catch (error) {
        console.warn(`Failed to hydrate images for restaurant ${restaurant.sourceLocationId}:`, error.message || error);
        return restaurant;
    }
};

export const getRestaurants = async (req, res, next) => {
    try {
        const queryError = validator.validateLocationListQuery(req.query);
        if (queryError) {
            return next(respond.httpError(queryError, 400));
        }

        const page = parser.parsePositiveInt(req.query.page, 1);
        const limit = Math.min(parser.parsePositiveInt(req.query.limit, config.search.defaultLimit), config.search.maxLimit);
        const skip = (page - 1) * limit;
        const filter = parser.buildLocationFilter(req.query);
        const sort = parser.buildSort(req.query.sortBy, req.query.order);

        const poolLimit = Math.min(limit * 3, 150);
        let [restaurants, total] = await Promise.all([
            RestaurantDB.find(filter).select(locationPublicProjection).skip(skip).limit(poolLimit),
            RestaurantDB.countDocuments(filter)
        ]);

        // Sort in-memory in JS to completely bypass MongoDB's sort memory limit
        const reqSortBy = req.query.sortBy || 'totalScore';
        const reqOrder = req.query.order || 'desc';
        const isDesc = reqOrder === 'desc';

        restaurants.sort((a, b) => {
            const valA = a[reqSortBy] !== undefined ? a[reqSortBy] : 0;
            const valB = b[reqSortBy] !== undefined ? b[reqSortBy] : 0;
            if (valA !== valB) {
                if (typeof valA === 'number' && typeof valB === 'number') {
                    return isDesc ? valB - valA : valA - valB;
                }
                return isDesc
                    ? String(valB).localeCompare(String(valA))
                    : String(valA).localeCompare(String(valB));
            }
            return (b.reviewsCount || 0) - (a.reviewsCount || 0);
        });

        const filteredRestaurants = parser.filterByPriceRange(restaurants, req.query.price, req.query.nullPrice);
        const pagedRestaurants = filteredRestaurants.slice(0, limit);

        res.status(200).json({
            success: true,
            count: pagedRestaurants.length,
            total,
            page,
            totalPages: Math.ceil(total / limit),
            data: pagedRestaurants
        });
    } catch (error) {
        next(error);
    }
};

export const getRestaurant = async (req, res, next) => {
    try {
        const lookupError = validator.validateLocationLookupQuery(req.query);
        if (lookupError) {
            return next(respond.httpError(lookupError, 400));
        }

        let restaurant = await RestaurantDB.findOne(parser.buildLocationLookupFilter(req.query)).select(locationPublicProjection);

        if (!restaurant) {
            return next(respond.httpError('Restaurant not found', 404));
        }

        restaurant = await hydrateRestaurantImages(restaurant);

        res.status(200).json({
            success: true,
            data: restaurant
        });
    } catch (error) {
        next(error);
    }
};

export const createRestaurant = async (req, res, next) => {
    try {
        const payload = parser.normalizeLocationPayload(req.body);
        const validationError = validator.validateLocationPayload(payload);

        if (validationError) {
            return next(respond.httpError(validationError, 400));
        }

        const restaurant = await RestaurantDB.create(payload);
        const publicRestaurant = restaurant.toObject();
        delete publicRestaurant.embedding;
        delete publicRestaurant.searchText;

        res.status(201).json({
            success: true,
            message: 'Restaurant created successfully!',
            data: publicRestaurant
        });
    } catch (error) {
        next(error);
    }
};

export const updateRestaurant = async (req, res, next) => {
    try {
        const lookupError = validator.validateLocationLookupQuery(req.query);
        if (lookupError) {
            return next(respond.httpError(lookupError, 400));
        }

        const payload = parser.normalizeLocationPayload(req.body, { partial: true });
        const validationError = validator.validateLocationPayload(payload, { partial: true });

        if (validationError) {
            return next(respond.httpError(validationError, 400));
        }

        if (Object.keys(payload).length === 0) {
            return next(respond.httpError('No fields provided for update', 400));
        }

        const restaurant = await RestaurantDB.findOneAndUpdate(
            parser.buildLocationLookupFilter(req.query),
            { $set: payload },
            { new: true, runValidators: true }
        ).select(locationPublicProjection);

        if (!restaurant) {
            return next(respond.httpError('Restaurant not found', 404));
        }

        res.status(200).json({
            success: true,
            message: 'Restaurant updated successfully!',
            data: restaurant
        });
    } catch (error) {
        next(error);
    }
};

export const deleteRestaurant = async (req, res, next) => {
    try {
        const lookupError = validator.validateLocationLookupQuery(req.query);
        if (lookupError) {
            return next(respond.httpError(lookupError, 400));
        }

        const restaurant = await RestaurantDB.findOneAndDelete(parser.buildLocationLookupFilter(req.query));

        if (!restaurant) {
            return next(respond.httpError('Restaurant not found', 404));
        }

        res.status(200).json({
            success: true,
            message: 'Restaurant deleted successfully!',
            deletedId: restaurant._id,
            deletedSourceLocationId: restaurant.sourceLocationId
        });
    } catch (error) {
        next(error);
    }
};
