import mongoose from 'mongoose';
import PlaceDB from '../models/PlaceDB.js';

// GET ALL LOCATIONS
export const getLocations = async (req, res) => {
    try {
        const {
            page = 1,
            limit = 10
        } = req.query;

        const skip = (page - 1) * limit;

        const data = await PlaceDB.find()
            .sort({
                totalScore: -1,
                reviewsCount: -1
            })
            .skip(skip)
            .limit(Number(limit));

        const total = await PlaceDB.countDocuments();

        res.status(200).json({
            success: true,
            total,
            currentPage: Number(page),
            totalPages: Math.ceil(total / limit),
            data
        });

    } catch (err) {
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
};

// GET LOCATION BY ID
export const getLocationById = async (req, res) => {
    try {
        const { id } = req.params;

        // Validate ObjectId
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                success: false,
                message: 'Invalid location ID'
            });
        }

        const location = await PlaceDB.findById(id);

        if (!location) {
            return res.status(404).json({
                success: false,
                message: 'Location not found'
            });
        }

        res.status(200).json({
            success: true,
            data: location
        });

    } catch (err) {
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
};

// SEARCH LOCATIONS
export const searchLocations = async (req, res) => {
    try {
        const {
            query,
            category,
            city,
            minRating,
            page = 1,
            limit = 10
        } = req.body;

        const filter = {};

        // Full-text search
        if (query) {
            filter.$text = {
                $search: query
            };
        }

        // Filter city
        if (city) {
            filter.city = {
                $regex: city,
                $options: 'i'
            };
        }

        // Filter category
        if (category) {
            filter.categories = category;
        }

        // Filter minimum rating
        if (minRating) {
            filter.totalScore = {
                $gte: minRating
            };
        }

        const skip = (page - 1) * limit;

        const data = await PlaceDB.find(filter)
            .sort({
                totalScore: -1,
                reviewsCount: -1
            })
            .skip(skip)
            .limit(Number(limit));

        const total = await PlaceDB.countDocuments(filter);

        res.status(200).json({
            success: true,
            total,
            currentPage: Number(page),
            totalPages: Math.ceil(total / limit),
            data
        });

    } catch (err) {
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
};

// GET NEARBY LOCATIONS
export const getNearbyLocations = async (req, res) => {
    try {
        const { city, category } = req.query;

        const filter = {};

        // Filter city
        if (city) {
            filter.city = {
                $regex: city,
                $options: 'i'
            };
        }

        // Filter category
        if (category) {
            filter.categories = category;
        }

        const data = await PlaceDB.find(filter)
            .sort({
                totalScore: -1,
                reviewsCount: -1
            })
            .limit(10);

        res.status(200).json({
            success: true,
            data
        });

    } catch (err) {
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
};