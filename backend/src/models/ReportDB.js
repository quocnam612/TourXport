import mongoose from 'mongoose';

const reportUserSchema = new mongoose.Schema({
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

const reportSchema = new mongoose.Schema({
    reportType: {
        type: String,
        enum: [
            'bug',
            'suggestion',
            'inaccuracy',
            'review',
            'other'
        ],
        default: 'other',
        index: true
    },

    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'UserDB',
        required: true,
        index: true
    },

    targetId: {
        type: mongoose.Schema.Types.ObjectId,
        index: true
    },

    targetType: {
        type: String,
        enum: [
            'PlaceDB',
            'RestaurantDB',
            'HotelDB',
            'Tour'
        ]
    },

    category: {
        type: String,
        enum: [
            'wrong_information',
            'wrong_address',
            'wrong_price',
            'closed_location',
            'duplicate_location',
            'fake_review',
            'inappropriate_content',
            'other'
        ]
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

    attachments: [{
        url: String,
        public_id: String
    }],

    helpful_votes: {
        type: Number,
        min: 0,
        default: 0
    },

    upvotedBy: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'UserDB'
    }],

    adminReply: {
        type: String,
        default: '',
        trim: true,
        maxlength: 1000
    },

    images: [{
        url: String,
        public_id: String
    }],

    status: {
        type: String,
        enum: [
            'pending',
            'reviewing',
            'resolved',
            'rejected'
        ],
        default: 'pending'
    },

    user: {
        type: reportUserSchema,
        required: true
    }
}, {
    timestamps: true
});

export default mongoose.model(
    'ReportDB',
    reportSchema,
    'reports'
);
