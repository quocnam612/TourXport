import RestaurantDB from '../models/RestaurantDB.js';
import config from '../config/config.js';
import parser from '../utils/parser.js';
import respond from '../utils/respond.js';
import validator from '../utils/validators.js';

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

        const restaurants = await RestaurantDB.find(filter).sort(sort);
        const filteredRestaurants = parser.filterByPriceRange(restaurants, req.query.price, req.query.nullPrice);
        const pagedRestaurants = filteredRestaurants.slice(skip, skip + limit);

        res.status(200).json({
            success: true,
            count: pagedRestaurants.length,
            total: filteredRestaurants.length,
            page,
            totalPages: Math.ceil(filteredRestaurants.length / limit),
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

        const restaurant = await RestaurantDB.findOne(parser.buildLocationLookupFilter(req.query));

        if (!restaurant) {
            return next(respond.httpError('Restaurant not found', 404));
        }

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

        res.status(201).json({
            success: true,
            message: 'Restaurant created successfully!',
            data: restaurant
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
        );

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
