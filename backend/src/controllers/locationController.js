import PlaceDB from '../models/PlaceDB.js';
import config from '../config/config.js';
import parser from '../utils/parser.js';
import respond from '../utils/respond.js';
import validator from '../utils/validators.js';
import TravelAdvisor from '../services/TravelAdvisor.js';

const locationPublicProjection = '-embedding -searchText';

const hydrateLocationImages = async (location) => {
    if (!location || !location.sourceLocationId || (Array.isArray(location.images) && location.images.length > 0)) {
        return location;
    }

    try {
        const images = await TravelAdvisor.getHighQualityPhotosBySourceLocationId(location.sourceLocationId, {
            excludeUrls: [location.image?.url],
            limit: 10
        });

        if (!images.length) {
            return location;
        }

        return await PlaceDB.findByIdAndUpdate(
            location._id,
            { $set: { images } },
            { new: true, runValidators: true }
        ).select(locationPublicProjection);
    } catch (error) {
        console.warn(`Failed to hydrate images for place ${location.sourceLocationId}:`, error.message || error);
        return location;
    }
};

export const getLocations = async (req, res, next) => {
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
        let [locations, total] = await Promise.all([
            PlaceDB.find(filter).select(locationPublicProjection).sort(sort).skip(skip).limit(poolLimit),
            PlaceDB.countDocuments(filter)
        ]);

        // Regular expression for Vietnamese characters
        const vietnameseRegex = /[àáảãạăắằẳẵặâấầẩẫậèéẻẽẹêếềểễệđìíỉĩịòóỏõọôốồổỗộơớờởỡợùúủũụưứừửữựỳýỷỹỵ]/i;

        const reqSortBy = req.query.sortBy || 'totalScore';
        const reqOrder = req.query.order || 'desc';
        const isDesc = reqOrder === 'desc';

        locations.sort((a, b) => {
            const aIsVietnamese = vietnameseRegex.test(a.title);
            const bIsVietnamese = vietnameseRegex.test(b.title);

            if (aIsVietnamese && !bIsVietnamese) return -1;
            if (!aIsVietnamese && bIsVietnamese) return 1;

            // Sort by the requested field
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

            // Fallback secondary sort: reviewsCount (descending)
            if ((b.reviewsCount || 0) !== (a.reviewsCount || 0)) {
                return (b.reviewsCount || 0) - (a.reviewsCount || 0);
            }
            return 0;
        });

        locations = locations.slice(0, limit);

        res.status(200).json({
            success: true,
            count: locations.length,
            total,
            page,
            totalPages: Math.ceil(total / limit),
            data: locations
        });
    } catch (error) {
        next(error);
    }
};

export const getLocation = async (req, res, next) => {
    try {
        const lookupError = validator.validateLocationLookupQuery(req.query);
        if (lookupError) {
            return next(respond.httpError(lookupError, 400));
        }

        let location = await PlaceDB.findOne(parser.buildLocationLookupFilter(req.query)).select(locationPublicProjection);

        if (!location) {
            return next(respond.httpError('Location not found', 404));
        }

        location = await hydrateLocationImages(location);

        res.status(200).json({
            success: true,
            data: location
        });
    } catch (error) {
        next(error);
    }
};

export const createLocation = async (req, res, next) => {
    try {
        const payload = parser.normalizeLocationPayload(req.body);
        const validationError = validator.validateLocationPayload(payload);

        if (validationError) {
            return next(respond.httpError(validationError, 400));
        }

        const location = await PlaceDB.create(payload);
        const publicLocation = location.toObject();
        delete publicLocation.embedding;
        delete publicLocation.searchText;

        res.status(201).json({
            success: true,
            message: 'Location created successfully!',
            data: publicLocation
        });
    } catch (error) {
        next(error);
    }
};

export const updateLocation = async (req, res, next) => {
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

        const location = await PlaceDB.findOneAndUpdate(
            parser.buildLocationLookupFilter(req.query),
            { $set: payload },
            { new: true, runValidators: true }
        ).select(locationPublicProjection);

        if (!location) {
            return next(respond.httpError('Location not found', 404));
        }

        res.status(200).json({
            success: true,
            message: 'Location updated successfully!',
            data: location
        });
    } catch (error) {
        next(error);
    }
};

export const deleteLocation = async (req, res, next) => {
    try {
        const lookupError = validator.validateLocationLookupQuery(req.query);
        if (lookupError) {
            return next(respond.httpError(lookupError, 400));
        }

        const location = await PlaceDB.findOneAndDelete(parser.buildLocationLookupFilter(req.query));

        if (!location) {
            return next(respond.httpError('Location not found', 404));
        }

        res.status(200).json({
            success: true,
            message: 'Location deleted successfully!',
            deletedId: location._id,
            deletedSourceLocationId: location.sourceLocationId
        });
    } catch (error) {
        next(error);
    }
};
