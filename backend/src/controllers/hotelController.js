import HotelDB from '../models/HotelDB.js';
import config from '../config/config.js';
import parser from '../utils/parser.js';
import respond from '../utils/respond.js';
import validator from '../utils/validators.js';

export const getHotels = async (req, res, next) => {
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

        const hotels = await HotelDB.find(filter).sort(sort);
        const filteredHotels = parser.filterByPriceRange(hotels, req.query.price, req.query.nullPrice);
        const pagedHotels = filteredHotels.slice(skip, skip + limit);

        res.status(200).json({
            success: true,
            count: pagedHotels.length,
            total: filteredHotels.length,
            page,
            totalPages: Math.ceil(filteredHotels.length / limit),
            data: pagedHotels
        });
    } catch (error) {
        next(error);
    }
};

export const getHotel = async (req, res, next) => {
    try {
        const lookupError = validator.validateLocationLookupQuery(req.query);
        if (lookupError) {
            return next(respond.httpError(lookupError, 400));
        }

        const hotel = await HotelDB.findOne(parser.buildLocationLookupFilter(req.query));

        if (!hotel) {
            return next(respond.httpError('Hotel not found', 404));
        }

        res.status(200).json({
            success: true,
            data: hotel
        });
    } catch (error) {
        next(error);
    }
};

export const createHotel = async (req, res, next) => {
    try {
        const payload = parser.normalizeLocationPayload(req.body);
        const validationError = validator.validateLocationPayload(payload);

        if (validationError) {
            return next(respond.httpError(validationError, 400));
        }

        const hotel = await HotelDB.create(payload);

        res.status(201).json({
            success: true,
            message: 'Hotel created successfully!',
            data: hotel
        });
    } catch (error) {
        next(error);
    }
};

export const updateHotel = async (req, res, next) => {
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

        const hotel = await HotelDB.findOneAndUpdate(
            parser.buildLocationLookupFilter(req.query),
            { $set: payload },
            { new: true, runValidators: true }
        );

        if (!hotel) {
            return next(respond.httpError('Hotel not found', 404));
        }

        res.status(200).json({
            success: true,
            message: 'Hotel updated successfully!',
            data: hotel
        });
    } catch (error) {
        next(error);
    }
};

export const deleteHotel = async (req, res, next) => {
    try {
        const lookupError = validator.validateLocationLookupQuery(req.query);
        if (lookupError) {
            return next(respond.httpError(lookupError, 400));
        }

        const hotel = await HotelDB.findOneAndDelete(parser.buildLocationLookupFilter(req.query));

        if (!hotel) {
            return next(respond.httpError('Hotel not found', 404));
        }

        res.status(200).json({
            success: true,
            message: 'Hotel deleted successfully!',
            deletedId: hotel._id,
            deletedSourceLocationId: hotel.sourceLocationId
        });
    } catch (error) {
        next(error);
    }
};
