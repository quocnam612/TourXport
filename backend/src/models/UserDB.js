import mongoose from 'mongoose';

const userSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
        trim: true
    },
    phone: {
        type: String,
        required: false,
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
        required: true,
        select: false
    },
    savedPlaces: {
        type: Array,
        default: []
    }
}, { timestamps: true });

export default mongoose.model('UserDB', userSchema, 'users');