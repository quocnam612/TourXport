import mongoose from 'mongoose';

const placeSchema = new mongoose.Schema({
    title: {
        type: String,
        required: true,
        trim: true
    },

    totalScore: {
        type: Number,
        default: 0
    },

    reviewsCount: {
        type: Number,
        default: 0
    },

    street: String,
    city: String,
    state: String,
    countryCode: String,

    website: String,
    phone: String,

    categories: [String],
    categoryName: String,

    url: String

}, { timestamps: true });

export default mongoose.model('PlaceDB', placeSchema, 'places');