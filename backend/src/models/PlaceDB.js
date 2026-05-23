import mongoose from 'mongoose';

const placeSchema = new mongoose.Schema({
    sourceLocationId: {
        type: String,
        default: null
    },

    title: {
        type: String,
        required: true,
        trim: true
    },

    city: {
        type: String,
        default: ''
    },

    totalScore: {
        type: Number,
        default: 0
    },

    ranking: {
        type: String,
        default: ''
    },

    reviewsCount: {
        type: Number,
        default: 0
    },

    category: {
        type: String,
        default: ''
    },

    priceRange: {
        type: String,
        default: ''
    },

    description: {
        type: String,
        default: ''
    },

    embedding: {
        type: mongoose.Schema.Types.Mixed,
        default: null
    },

    searchText: {
        type: String,
        default: ''
    },

    tags: {
        type: [String],
        default: []
    },

    image: {
        url: {
            type: String,
            default: ''
        },

        publicId: {
            type: String,
            default: ''
        },

        source: {
            type: String,
            default: ''
        }
    },

    location: {
        type: {
            type: String,
            enum: ['Point'],
            default: 'Point'
        },

        coordinates: {
            type: [Number],
            default: [0, 0]
        }
    },

    openingHours: {
        type: mongoose.Schema.Types.Mixed,
        default: null
    },

    highlights: {
        type: [String],
        default: []
    }

}, {
    timestamps: true
});


// TEXT SEARCH INDEX
placeSchema.index({
    title: 'text',
    city: 'text',
    category: 'text',
    searchText: 'text',
    tags: 'text'
});


// GEO INDEX
placeSchema.index({
    location: '2dsphere'
});

export default mongoose.model('PlaceDB', placeSchema, 'places');