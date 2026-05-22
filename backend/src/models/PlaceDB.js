import mongoose from 'mongoose';

const placeSchema = new mongoose.Schema({
    title: {
        type: String,
        required: true,
        trim: true
    },

    description: {
        type: String,
        default: ''
    },

    imageUrl: {
        type: String,
        default: ''
    },

    totalScore: {
        type: Number,
        default: 0
    },

    reviewsCount: {
        type: Number,
        default: 0
    },

    city: {
        type: String,
        default: ''
    },

    state: {
        type: String,
        default: ''
    },

    countryCode: {
        type: String,
        default: 'VN'
    },

    categories: {
        type: [String],
        default: []
    },

    categoryName: {
        type: String,
        default: ''
    },

    priceRange: {
        type: String,
        default: ''
    }

}, {
    timestamps: true
});

// Full-text search index
placeSchema.index({
    title: 'text',
    description: 'text',
    city: 'text',
    state: 'text',
    categories: 'text'
});

export default mongoose.model('PlaceDB', placeSchema, 'places');