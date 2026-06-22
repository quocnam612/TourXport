import config from '../config/config.js';
import parser from '../utils/parser.js';
import respond from '../utils/respond.js';
import validator from '../utils/validators.js';

import TourDB from '../models/TourDB.js';
import AIBackend from '../services/AIBackend.js';
import OpenRouteService from '../services/OpenRouteService.js';

const isTourId = (id) => /^[0-9a-fA-F]{24}$/.test(String(id));
const tourListProjection = '-ai -bbox -days';

const listTours = async (req, res, next, baseFilter = {}) => {
    try {
        const queryError = validator.validateTourListQuery(req.query);
        if (queryError) {
            return next(respond.httpError(queryError, 400));
        }

        const page = parser.parsePositiveInt(req.query.page, 1);
        const limit = Math.min(
            parser.parsePositiveInt(req.query.limit, config.search.defaultLimit),
            config.search.maxLimit
        );
        const skip = (page - 1) * limit;
        const filter = {
            ...parser.buildTourListFilter(req.query),
            ...baseFilter
        };
        const sort = parser.buildTourSort(req.query.sortBy, req.query.order);

        const [tours, total] = await Promise.all([
            TourDB.find(filter).select(tourListProjection).sort(sort).skip(skip).limit(limit),
            TourDB.countDocuments(filter)
        ]);

        res.status(200).json({
            success: true,
            count: tours.length,
            total,
            page,
            totalPages: Math.ceil(total / limit),
            data: tours
        });
    } catch (error) {
        next(error);
    }
};

export const getTours = (req, res, next) => {
    return listTours(req, res, next, { visibility: 'public' });
};

export const createTour = async (req, res, next) => {
    try {
        const validationError = validator.validateTourCreatePayload(req.body);
        if (validationError) {
            return next(respond.httpError(validationError, 400));
        }

        const aiTour = await AIBackend.generateTrip(req.body);
        const tourPayload = await parser.normalizeTourPayloadFromAI(aiTour, req.user.id, OpenRouteService);
        const tour = await TourDB.create(tourPayload);

        res.status(201).json({
            success: true,
            message: 'Tour created successfully!',
            data: tour
        });
    } catch (error) {
        next(error);
    }
};

export const createManualTour = async (req, res, next) => {
    try {
        const validationError = validator.validateManualTourCreatePayload(req.body);
        if (validationError) {
            return next(respond.httpError(validationError, 400));
        }

        const tourPayload = await parser.normalizeTourPayloadFromManual(req.body, req.user.id, OpenRouteService);
        const tour = await TourDB.create(tourPayload);

        res.status(201).json({
            success: true,
            message: 'Manual tour created successfully!',
            data: tour
        });
    } catch (error) {
        next(error);
    }
};

export const getTourById = async (req, res, next) => {
    try {
        if (!isTourId(req.params.id)) {
            return next(respond.httpError('Invalid tour ID', 400));
        }

        const tour = await TourDB.findOne({
            _id: req.params.id,
            visibility: 'public'
        });

        if (!tour) {
            return next(respond.httpError('Tour not found', 404));
        }

        res.status(200).json({
            success: true,
            data: tour
        });
    } catch (error) {
        next(error);
    }
};

export const getMyTours = (req, res, next) => {
    return listTours(req, res, next, { userId: req.user.id });
};

export const getMyTourDetail = async (req, res, next) => {
    try {
        if (!isTourId(req.params.id)) {
            return next(respond.httpError('Invalid tour ID', 400));
        }

        const tour = await TourDB.findOne({
            _id: req.params.id,
            userId: req.user.id
        });

        if (!tour) {
            return next(respond.httpError('Tour not found', 404));
        }

        res.status(200).json({
            success: true,
            data: tour
        });
    } catch (error) {
        next(error);
    }
};

export const updateMyTour = async (req, res, next) => {
    try {
        if (!isTourId(req.params.id)) {
            return next(respond.httpError('Invalid tour ID', 400));
        }

        const updates = parser.removeProtectedTourFields(req.body);
        const validationError = validator.validateTourUpdatePayload(updates);
        if (validationError) {
            return next(respond.httpError(validationError, 400));
        }

        const tour = await TourDB.findOneAndUpdate(
            {
                _id: req.params.id,
                userId: req.user.id
            },
            { $set: updates },
            { new: true, runValidators: true }
        );

        if (!tour) {
            return next(respond.httpError('Tour not found', 404));
        }

        res.status(200).json({
            success: true,
            message: 'Tour updated successfully!',
            data: tour
        });
    } catch (error) {
        next(error);
    }
};

export const deleteMyTour = async (req, res, next) => {
    try {
        if (!isTourId(req.params.id)) {
            return next(respond.httpError('Invalid tour ID', 400));
        }

        const tour = await TourDB.findOneAndDelete({
            _id: req.params.id,
            userId: req.user.id
        });

        if (!tour) {
            return next(respond.httpError('Tour not found', 404));
        }

        res.status(200).json({
            success: true,
            message: 'Tour deleted successfully!',
            deletedId: tour._id
        });
    } catch (error) {
        next(error);
    }
};
