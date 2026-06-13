import HotelDB from '../models/HotelDB.js';
import config from '../config/config.js';
import parser from '../utils/parser.js';
import respond from '../utils/respond.js';
import validator from '../utils/validators.js';
import TravelAdvisor from '../services/TravelAdvisor.js';

const locationPublicProjection = '-embedding -searchText';

const hydrateHotelImages = async (hotel) => {
    if (!hotel || !hotel.sourceLocationId || (Array.isArray(hotel.images) && hotel.images.length > 0)) {
        return hotel;
    }

    try {
        const images = await TravelAdvisor.getHighQualityPhotosBySourceLocationId(hotel.sourceLocationId, {
            excludeUrls: [hotel.image?.url],
            limit: 10
        });

        if (!images.length) {
            return hotel;
        }

        return await HotelDB.findByIdAndUpdate(
            hotel._id,
            { $set: { images } },
            { new: true, runValidators: true }
        ).select(locationPublicProjection);
    } catch (error) {
        console.warn(`Failed to hydrate images for hotel ${hotel.sourceLocationId}:`, error.message || error);
        return hotel;
    }
};

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

        const poolLimit = Math.min(limit * 3, 150);
        let [hotels, total] = await Promise.all([
            HotelDB.find(filter).select(locationPublicProjection).skip(skip).limit(poolLimit),
            HotelDB.countDocuments(filter)
        ]);

        // Sort in-memory in JS to completely bypass MongoDB's sort memory limit
        const reqSortBy = req.query.sortBy || 'totalScore';
        const reqOrder = req.query.order || 'desc';
        const isDesc = reqOrder === 'desc';

        hotels.sort((a, b) => {
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

        const filteredHotels = parser.filterByPriceRange(hotels, req.query.price, req.query.nullPrice);
        const pagedHotels = filteredHotels.slice(0, limit);

        res.status(200).json({
            success: true,
            count: pagedHotels.length,
            total,
            page,
            totalPages: Math.ceil(total / limit),
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

        let hotel = await HotelDB.findOne(parser.buildLocationLookupFilter(req.query)).select(locationPublicProjection);

        if (!hotel) {
            return next(respond.httpError('Hotel not found', 404));
        }

        hotel = await hydrateHotelImages(hotel);

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
        const publicHotel = hotel.toObject();
        delete publicHotel.embedding;
        delete publicHotel.searchText;

        res.status(201).json({
            success: true,
            message: 'Hotel created successfully!',
            data: publicHotel
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
        ).select(locationPublicProjection);

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
