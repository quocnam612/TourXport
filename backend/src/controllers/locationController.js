import mongoose from 'mongoose';
import PlaceDB from '../models/PlaceDB.js';

// GET ALL LOCATIONS
export const getLocations = async (req, res) => {
    try {
        const data = await PlaceDB.find()
            .sort({ totalScore: -1 })
            .limit(50);

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

// GET LOCATION BY ID
export const getLocationById = async (req, res) => {
    try {
        const { id } = req.params;

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
        const { query, city, category, limit = 10 } = req.body;

        const filter = {};

        if (query) {
            filter.$or = [
                {
                    title: {
                        $regex: query,
                        $options: 'i'
                    }
                },
                {
                    description: {
                        $regex: query,
                        $options: 'i'
                    }
                }
            ];
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

        const data = await PlaceDB.find(filter)
            .sort({
                totalScore: -1,
                reviewsCount: -1
            })
            .limit(limit);

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

// GET NEARBY LOCATIONS
export const getNearbyLocations = async (req, res) => {
    try {
        const { city, category } = req.query;

        const filter = {};

        if (city) {
            filter.city = {
                $regex: city,
                $options: 'i'
            };
        }

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