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
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'UserDB',
        required: true,
        index: true
    },

    targetId: {
        type: mongoose.Schema.Types.ObjectId,
        required: true,
        index: true
    },

    targetType: {
        type: String,
        required: true,
        enum: [
            'PlaceDB',
            'RestaurantDB',
            'HotelDB',
            'Tour'
        ]
    },

    category: {
        type: String,
        required: true,
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

    adminNote: {
        type: String,
        default: ''
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