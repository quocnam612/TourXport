import bcrypt from 'bcrypt';

import UserDB from '../models/UserDB.js';
import PlaceDB from '../models/PlaceDB.js';
import config from '../config/config.js';
import validate from '../utils/validators.js';
import { generateToken } from '../utils/jwt.js';

export const login = async (req, res) => {
    try {
        const { phone, email, password } = req.body;
        const identifier = phone || email;

        if (!identifier || !password) {
            return res.status(400).json({
                success: false,
                message: 'Please provide enough login credentials!'
            });
        }

        const user = await UserDB.findOne({
            $or: [{ phone: identifier }, { email: identifier }]
        }).select('+password');

        if (!user) {
            return res.status(401).json({
                success: false,
                message: 'Invalid login credentials!'
            });
        }

        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(401).json({
                success: false,
                message: 'Invalid login credentials!'
            });
        }

        const token = generateToken(user);

        res.status(200).json({
            success: true,
            token,
            user: {
                id: user._id,
                name: user.name,
                avatar: user.avatar?.url || ''
            }
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Server error, please try again later!',
            error: error.message
        });
    }
};

export const register = async (req, res) => {
    try {
        const { name, phone, email, password } = req.body;

        if (!name || !email || !password) {
            return res.status(400).json({
                success: false,
                message: 'Please provide all required fields!'
            });
        }

        if (await UserDB.findOne({ email })) {
            return res.status(409).json({
                success: false,
                message: 'User with this email already exists!'
            });
        }

        if (phone && await UserDB.findOne({ phone })) {
            return res.status(409).json({
                success: false,
                message: 'User with this phone number already exists!'
            });
        }

        const hashedPassword = await bcrypt.hash(password, 10);

        const user = await UserDB.create({
            name,
            email,
            phone: phone || undefined,
            password: hashedPassword
        });

        const token = generateToken(user);

        res.status(201).json({
            success: true,
            message: 'User registered successfully!',
            token,
            user: {
                id: user._id,
                name: user.name,
                email: user.email
            }
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Server error, please try again later!',
            error: error.message
        });
    }
};

export const getProfile = async (req, res) => {
    try {
        const user = await UserDB.findById(req.user.id)
            .select('-savedPlaces -savedTours -password');

        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found!'
            });
        }

        res.status(200).json({
            success: true,
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                phone: user.phone || '',
                avatar: user.avatar?.url || '',
                createdAt: user.createdAt
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Server error, please try again later!',
            error: error.message
        });
    }
};

export const updateProfile = async (req, res) => {
    try {
        const { name, phone, email } = req.body;
        const userId = req.user.id;
        const updates = {};

        if (name) updates.name = name;
        
        if (phone) {
            const existingPhone = await UserDB.findOne({ phone, _id: { $ne: userId } });
            if (existingPhone) {
                return res.status(409).json({ success: false, message: 'Phone number is already in use!' });
            }
            updates.phone = phone;
        }

        if (email) {
            const existingEmail = await UserDB.findOne({ email, _id: { $ne: userId } });
            if (existingEmail) {
                return res.status(409).json({ success: false, message: 'Email is already in use!' });
            }
            updates.email = email;
        }

        const user = await UserDB.findByIdAndUpdate(
            userId,
            { $set: updates },
            { new: true, runValidators: true }
        );

        if (!user) {
            return res.status(404).json({ success: false, message: 'User not found!' });
        }

        res.status(200).json({
            success: true,
            message: 'Profile updated successfully!',
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                phone: user.phone || '',
                avatar: user.avatar?.url || ''
            }
        });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
};

export const changePassword = async (req, res) => {
    try {
        const { oldPassword, newPassword } = req.body;
        const user = await UserDB.findById(req.user.id).select('+password');

        const isMatch = await bcrypt.compare(oldPassword, user.password);
        if (!isMatch) {
            return res.status(401).json({ success: false, message: 'Old password is incorrect!' });
        }

        user.password = await bcrypt.hash(newPassword, 10);
        await user.save();

        res.status(200).json({ success: true, message: 'Password changed successfully!' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

export const getSavedPlaces = async (req, res) => {
    try {
        const user = await UserDB.findById(req.user.id).populate('savedPlaces');

        if (!user) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }

        res.status(200).json({ 
            success: true, 
            savedPlaces: user.savedPlaces || [] 
        });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
};

export const addSavedPlace = async (req, res) => {
    try {
        const { placeId } = req.body;

        if (!placeId) {
            return res.status(400).json({ success: false, message: 'Place ID is required' });
        }

        const user = await UserDB.findByIdAndUpdate(
            req.user.id,
            { $addToSet: { savedPlaces: placeId } },
        );

        if (!user) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }

        const newSavedPlace = await PlaceDB.findById(placeId);

        res.status(200).json({ 
            success: true, 
            message: 'Place added to favorites successfully!',
            newPlace: newSavedPlace 
        });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
};

export const removeSavedPlace = async (req, res) => {
    try {
        const { placeId } = req.params; 

        if (!placeId) {
            return res.status(400).json({ success: false, message: 'Place ID is required' });
        }

        await UserDB.findByIdAndUpdate(
            req.user.id,
            { $pull: { savedPlaces: placeId } }
        );

        res.status(200).json({ 
            success: true, 
            message: 'Removed from favorites successfully!',
            removedId: placeId
        });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
};

export const getSavedTours = async (req, res) => {
    try {
        const user = await UserDB.findById(req.user.id).populate('savedTours');

        if (!user) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }

        res.status(200).json({ 
            success: true, 
            savedTours: user.savedTours || [] 
        });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
};

export const addSavedTour = async (req, res) => {
    try {
        const { tourId } = req.body;

        if (!tourId) {
            return res.status(400).json({ success: false, message: 'Tour ID is required' });
        }

        const user = await UserDB.findByIdAndUpdate(
            req.user.id,
            { $addToSet: { savedTours: tourId } },
        );

        if (!user) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }

        const newSavedTour = await TourDB.findById(tourId);

        res.status(200).json({ 
            success: true, 
            message: 'Tour added to favorites successfully!',
            newTour: newSavedTour 
        });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
};

export const removeSavedTour = async (req, res) => {
    try {
        const { tourId } = req.params; 

        if (!tourId) {
            return res.status(400).json({ success: false, message: 'Tour ID is required' });
        }

        await UserDB.findByIdAndUpdate(
            req.user.id,
            { $pull: { savedTours: tourId } }
        );

        res.status(200).json({ 
            success: true, 
            message: 'Removed from favorites successfully!',
            removedId: tourId
        });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
};