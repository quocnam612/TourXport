import mongoose from 'mongoose';

const userSchema = new mongoose.Schema({
    authProvider: {
        type: String,
        enum: ['local', 'google', 'facebook'],
        default: 'local'
    },
    googleId: { 
        type: String, 
        unique: true, 
        sparse: true 
    },
    facebookId: {
        type: String,
        unique: true,
        sparse: true
    },
    email: {
        type: String,
        required: true,
        unique: true,
        lowercase: true
    },
    password: {
        type: String,
        select: false
    },
    name: {
        type: String,
        required: true,
        trim: true
    },
    phone: {
        type: String,
        unique: true,
        sparse: true
    },
    savedPlaces: {
        type: [{
            type: mongoose.Schema.Types.ObjectId,
            ref: 'PlaceDB'
        }],
        default: []
    },
    savedTours: {
        type: [{
            type: mongoose.Schema.Types.ObjectId,
            ref: 'TourDB'
        }],
        default: []
    },
    avatar: {
        url: { type: String, default: '' },
        public_id: { type: String, default: '' }
    }
}, { timestamps: true });

export default mongoose.model('UserDB', userSchema, 'users');