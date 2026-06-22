import mongoose from 'mongoose';

const reviewUserSchema = new mongoose.Schema({
    username: {
        type: String,
        required: true,
        trim: true
    },

    avatar: {
        url: {
            type: String,
            default: ''
        },

        public_id: {
            type: String,
            default: ''
        }
    }
}, { _id: false });

const reviewLocationModels = ['RestaurantDB', 'HotelDB', 'PlaceDB'];

const reviewSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'UserDB',
        default: null
    },

    locationId: {
        type: mongoose.Schema.Types.ObjectId,
        refPath: 'type',
        required: true,
        index: true
    },

    type: {
        type: String,
        enum: reviewLocationModels,
        required: true
    },

    rating: {
        type: Number,
        required: true,
        min: 1,
        max: 5
    },

    helpful_votes: {
        type: Number,
        min: 0,
        default: 0
    },

    travel_date: {
        type: String,
        default: null,
        trim: true,
        match: /^\d{4}-(0[1-9]|1[0-2])$/
    },

    title: {
        type: String,
        required: true,
        trim: true
    },

    text: {
        type: String,
        required: true,
        trim: true
    },

    user: {
        type: reviewUserSchema,
        required: true
    },

    images: {
        type: [{
            url: {
                type: String,
                required: true
            },
            public_id: {
                type: String,
                default: ''
            }
        }],
        default: []
    }
}, {
    timestamps: true
});

export default mongoose.model('ReviewDB', reviewSchema, 'reviews');
