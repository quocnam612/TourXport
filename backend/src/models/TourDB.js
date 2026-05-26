import mongoose from 'mongoose';

const bboxSchema = new mongoose.Schema({
    minLng: { type: Number, required: true },
    minLat: { type: Number, required: true },
    maxLng: { type: Number, required: true },
    maxLat: { type: Number, required: true }
}, { _id: false });

const costSchema = new mongoose.Schema({
    min: {
        type: Number,
        min: 0,
        default: null
    },

    max: {
        type: Number,
        min: 0,
        default: null
    },

    currency: {
        type: String,
        trim: true,
        default: 'VND'
    },

    note: {
        type: String,
        trim: true,
        default: null
    }
}, { _id: false });

const pointSchema = new mongoose.Schema({
    type: {
        type: String,
        enum: ['Point'],
        default: 'Point'
    },

    coordinates: {
        type: [Number],
        required: true,
        validate: {
            validator: value => Array.isArray(value) && value.length === 2,
            message: 'Point coordinates must contain [longitude, latitude]'
        }
    }
}, { _id: false });

const lineStringSchema = new mongoose.Schema({
    type: {
        type: String,
        enum: ['LineString'],
        required: true,
        default: 'LineString'
    },

    coordinates: {
        type: [[Number]],
        required: true,
        validate: {
            validator: value => Array.isArray(value)
                && value.length >= 2
                && value.every(point => Array.isArray(point) && point.length === 2),
            message: 'LineString coordinates must contain at least two [longitude, latitude] points'
        }
    }
}, { _id: false });

const sourceSchema = new mongoose.Schema({
    provider: {
        type: String,
        enum: ['database', 'websearch'],
        required: true
    },

    collection: {
        type: String,
        enum: ['places', 'restaurants', 'hotels'],
        default: null
    },

    id: {
        type: String,
        default: null
    }
}, { _id: false });

const itineraryItemSchema = new mongoose.Schema({
    order: {
        type: Number,
        required: true,
        min: 1
    },

    checked: {
        type: Boolean,
        default: false
    },

    type: {
        type: String,
        enum: ['place', 'restaurant', 'hotel'],
        required: true
    },

    title: {
        type: String,
        required: true,
        trim: true
    },

    category: {
        type: String,
        trim: true,
        default: null
    },

    startTime: {
        type: String,
        default: null,
        trim: true
    },

    endTime: {
        type: String,
        default: null,
        trim: true
    },

    notes: {
        type: String,
        default: null,
        trim: true
    },

    estimatedCost: {
        type: costSchema,
        default: null
    },

    location: {
        type: pointSchema,
        default: null
    },

    source: {
        type: sourceSchema,
        required: true
    }
}, { _id: false });

const routeStepSchema = new mongoose.Schema({
    instruction: {
        type: String,
        required: true,
        trim: true
    },

    name: {
        type: String,
        default: null,
        trim: true
    },

    distanceMeters: {
        type: Number,
        min: 0,
        default: 0
    },

    type: {
        type: Number,
        default: null
    },

    wayPoints: {
        type: [Number],
        default: []
    }
}, { _id: false });

const routeSchema = new mongoose.Schema({
    fromOrder: {
        type: Number,
        required: true,
        min: 1
    },

    toOrder: {
        type: Number,
        required: true,
        min: 1
    },

    provider: {
        type: String,
        required: true,
        trim: true
    },

    profile: {
        type: String,
        required: true,
        trim: true
    },

    distanceMeters: {
        type: Number,
        min: 0,
        default: 0
    },

    bbox: {
        type: bboxSchema,
        default: null
    },

    geometry: {
        type: lineStringSchema,
        required: true
    },

    steps: {
        type: [routeStepSchema],
        default: []
    }
}, { _id: false });

const daySchema = new mongoose.Schema({
    dayNumber: {
        type: Number,
        required: true,
        min: 1
    },

    date: {
        type: Date,
        default: null
    },

    title: {
        type: String,
        required: true,
        trim: true
    },

    summary: {
        type: String,
        default: null,
        trim: true
    },

    distanceMeters: {
        type: Number,
        min: 0,
        default: 0
    },

    bbox: {
        type: bboxSchema,
        default: null
    },

    items: {
        type: [itineraryItemSchema],
        default: []
    },

    routes: {
        type: [routeSchema],
        default: []
    }
}, { _id: false });

const tourSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'UserDB',
        required: true,
        index: true
    },

    title: {
        type: String,
        required: true,
        trim: true
    },

    destinations: {
        type: [String],
        default: []
    },

    visibility: {
        type: String,
        enum: ['private', 'public'],
        default: 'private',
        index: true
    },

    totalDays: {
        type: Number,
        required: true,
        min: 1
    },

    totalNights: {
        type: Number,
        min: 0,
        default: 0
    },

    totalDistanceMeters: {
        type: Number,
        min: 0,
        default: 0
    },

    bbox: {
        type: bboxSchema,
        default: null
    },

    travelers: {
        adults: {
            type: Number,
            min: 1,
            default: 1
        },

        children: {
            type: Number,
            min: 0,
            default: 0
        }
    },

    preferences: {
        budgetLevel: {
            type: String,
            default: 'medium'
        },

        interests: {
            type: [String],
            default: []
        },

        transportMode: {
            type: String,
            default: 'auto'
        },

        pace: {
            type: String,
            default: 'balanced'
        }
    },

    estimatedCost: {
        type: costSchema,
        default: null
    },

    days: {
        type: [daySchema],
        default: []
    },

    ai: {
        generatedBy: {
            type: String,
            default: null,
            trim: true
        },

        model: {
            type: String,
            default: null,
            trim: true
        },

        embeddingModel: {
            type: String,
            default: null,
            trim: true
        },

        retrieval: {
            strategy: {
                type: String,
                default: null,
                trim: true
            },

            index: {
                type: String,
                default: null,
                trim: true
            },

            topK: {
                type: Number,
                min: 0,
                default: null
            }
        }
    }
}, {
    timestamps: true
});

export default mongoose.model('TourDB', tourSchema, 'tours');
