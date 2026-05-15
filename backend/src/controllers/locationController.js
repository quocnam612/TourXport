import mongoose from 'mongoose';
import PlaceDB from '../models/PlaceDB.js';

export const getLocations = async (req, res) => {
    try {
        const data = await PlaceDB.find().limit(50);

        res.json({ success: true, data });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
};

export const getLocationById = async (req, res) => {
    try {
        const { id } = req.params;

        // ✅ Validate ObjectId
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

        res.json({
            success: true,
            data: location
        });

    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
};

export const searchLocations = async (req, res) => {
    try {
        const { query, category, city, limit = 10 } = req.body;

        const filter = {};

        // 🔍 search theo tên
        if (query) {
            filter.title = { $regex: query, $options: 'i' };
        }

        // 📍 filter city
        if (city) {
            filter.city = { $regex: city, $options: 'i' };
        }

        // 🏷️ filter category
        if (category) {
            filter.categories = category;
        }

        const data = await PlaceDB.find(filter)
            .sort({ totalScore: -1 }) // ưu tiên rating cao
            .limit(limit);

        res.json({ success: true, data });

    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
};

export const getNearbyLocations = async (req, res) => {
    try {
        const { city, category } = req.query;

        const filter = {};

        if (city) filter.city = city;
        if (category) filter.categories = category;

        const data = await PlaceDB.find(filter)
            .sort({ totalScore: -1 })
            .limit(10);

        res.json({ success: true, data });

    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
};