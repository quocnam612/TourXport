import mongoose from 'mongoose';

const appReviewUserSchema = new mongoose.Schema({
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

const appReviewSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'UserDB',
        default: null
    },

    rating: {
        type: Number,
        required: true,
        min: 1,
        max: 5
    },

    title: {
        type: String,
        required: true,
        trim: true,
        maxlength: 100
    },

    text: {
        type: String,
        required: true,
        trim: true,
        maxlength: 1000
    },

    user: {
        type: appReviewUserSchema,
        required: true
    },

    helpful_votes: {
        type: Number,
        min: 0,
        default: 0
    }
}, {
    timestamps: true
});

// Index for efficient queries
appReviewSchema.index({ createdAt: -1 });
appReviewSchema.index({ rating: -1 });

export default mongoose.model('AppReviewDB', appReviewSchema, 'app_reviews');
