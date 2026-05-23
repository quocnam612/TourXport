import mongoose from 'mongoose';
import PlaceDB from '../models/PlaceDB.js';


// GET ALL LOCATIONS
export const getLocations = async (req, res) => {
    try {
        const data = await PlaceDB.find()
            .sort({
                totalScore: -1,
                reviewsCount: -1
            })
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
        const {
            query,
            city,
            category,
            tags,
            limit = 10
        } = req.body;

        const filter = {};

        // SEARCH QUERY
        if (query) {
            filter.$or = [
                {
                    title: {
                        $regex: query,
                        $options: 'i'
                    }
                },
                {
                    searchText: {
                        $regex: query,
                        $options: 'i'
                    }
                },
                {
                    tags: {
                        $regex: query,
                        $options: 'i'
                    }
                }
            ];
        }

        // FILTER CITY
        if (city) {
            filter.city = {
                $regex: city,
                $options: 'i'
            };
        }

        // FILTER CATEGORY
        if (category) {
            filter.category = {
                $regex: category,
                $options: 'i'
            };
        }

        // FILTER TAGS
        if (tags) {
            filter.tags = {
                $in: Array.isArray(tags) ? tags : [tags]
            };
        }

        const data = await PlaceDB.find(filter)
            .sort({
                totalScore: -1,
                reviewsCount: -1
            })
            .limit(Number(limit));

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

        const {
            lng,
            lat,
            maxDistance = 10000,
            limit = 20
        } = req.query;


        // VALIDATION
        if (!lng || !lat) {
            return res.status(400).json({
                success: false,
                message: 'Longitude and latitude are required'
            });
        }


        const longitude = Number(lng);
        const latitude = Number(lat);


        // GEO QUERY
        const places = await PlaceDB.find({
            location: {
                $near: {
                    $geometry: {
                        type: 'Point',

                        coordinates: [
                            longitude,
                            latitude
                        ]
                    },
                    $maxDistance: Number(maxDistance)
                }
            }
        })
        .limit(Number(limit));


        res.status(200).json({
            success: true,
            total: places.length,
            data: places
        });

    } catch (err) {
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
};

// CREATE PLACE
export const createLocation = async (req, res) => {
    try {
        const {
            sourceLocationId,
            title,
            city,
            totalScore,
            ranking,
            reviewsCount,
            category,
            priceRange,
            description,
            embedding,
            tags,
            imageUrl,
            imageSource,
            lng,
            lat,
            openingHours,
            highlights
        } = req.body;

        // VALIDATION
        if (!title) {
            return res.status(400).json({
                success: false,
                message: 'Title is required'
            });
        }

        // CREATE SEARCH TEXT
        const searchText = `
            ${title}
            ${city}
            ${category}
            ${description}
            ${(tags || []).join(' ')}
        `;

        // CREATE PLACE
        const place = await PlaceDB.create({
            sourceLocationId: sourceLocationId || null,

            title,

            city: city || '',

            totalScore: Number(totalScore || 0),

            ranking: ranking || '',

            reviewsCount: Number(reviewsCount || 0),

            category: category || '',

            priceRange: priceRange || '',

            description: description || '',

            embedding: embedding || null,

            searchText,

            tags: tags || [],

            image: {
                url: imageUrl || '',
                publicId: '',
                source: imageSource || 'manual'
            },

            location: {
                type: 'Point',
                coordinates: [
                    Number(lng || 0),
                    Number(lat || 0)
                ]
            },

            openingHours: openingHours || null,

            highlights: highlights || []

        });


        res.status(201).json({
            success: true,
            message: 'Place created successfully',
            data: place
        });

    } catch (err) {
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
};