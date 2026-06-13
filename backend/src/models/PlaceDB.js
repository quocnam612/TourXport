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
        required: true,
        trim: true
    },

    totalScore: {
        type: Number,
        default: 0,
        min: 0,
        max: 5
    },

    ranking: {
        type: String,
        default: null
    },

    reviewsCount: {
        type: Number,
        min: 0,
        default: 0
    },

    category: {
        type: String,
        required: true,
        trim: true
    },

    priceRange: {
        type: String,
        default: null,
        trim: true
    },

    description: {
        type: String,
        default: null,
        trim: true
    },

    embedding: {
        type: mongoose.Schema.Types.Mixed,
        default: null
    },

    searchText: {
        type: String,
        default: null,
        trim: true
    },

    tags: {
        type: [String],
        default: []
    },

    image: {
        url: {
            type: String,
            default: null
        },

        publicId: {
            type: String,
            default: null
        },

        source: {
            type: String,
            default: ''
        }
    },

    images: [{
        url: {
            type: String,
            required: true
        },

        publicId: {
            type: String,
            default: null
        },

        source: {
            type: String,
            default: 'tripadvisor'
        }
    }],

    location: {
        type: {
            type: String,
            enum: ['Point'],
            default: 'Point'
        },

        coordinates: {
            type: [Number],
            required: true
        }
    },

    openingHours: {
        type: mongoose.Schema.Types.Mixed,
        default: null
    }
}, {
    timestamps: true
});

placeSchema.index({ location: '2dsphere' });
placeSchema.index({ city: 1 });
placeSchema.index({ reviewsCount: -1 });

export default mongoose.model('PlaceDB', placeSchema, 'places');
