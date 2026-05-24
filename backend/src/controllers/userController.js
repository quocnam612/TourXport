import bcrypt from 'bcrypt';

import UserDB from '../models/UserDB.js';
import PlaceDB from '../models/PlaceDB.js';
import TourDB from '../models/TourDB.js';

import respond from '../utils/respond.js';
import { generateToken } from '../utils/jwt.js';

export const login = async (req, res, next) => {
    try {
        const { phone, email, password } = req.body;
        const identifier = phone || email;

        if (!identifier || !password) {
            return next(respond.httpError('Please provide enough login credentials!', 400));
        }

        const user = await UserDB.findOne({
            $or: [{ phone: identifier }, { email: identifier }]
        }).select('+password');

        if (!user) {
            return next(respond.httpError('Invalid login credentials!', 401));
        }

        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return next(respond.httpError('Invalid login credentials!', 401));
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
        next(error);
    }
};

export const register = async (req, res, next) => {
    try {
        const { name, phone, email, password } = req.body;

        if (!name || !email || !password) {
            return next(respond.httpError('Please provide all required fields!', 400));
        }

        if (await UserDB.findOne({ email })) {
            return next(respond.httpError('User with this email already exists!', 409));
        }

        if (phone && await UserDB.findOne({ phone })) {
            return next(respond.httpError('User with this phone number already exists!', 409));
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
        next(error);
    }
};

export const getProfile = async (req, res, next) => {
    try {
        const user = await UserDB.findById(req.user.id).select('-savedPlaces -savedTours -password');

        if (!user) {
            return next(respond.httpError('User not found!', 404));
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
        next(error);
    }
};

export const updateProfile = async (req, res, next) => {
    try {
        const { name, phone, email } = req.body;
        const userId = req.user.id;
        const updates = {};

        if (name) updates.name = name;
        
        if (phone) {
            const existingPhone = await UserDB.findOne({ phone, _id: { $ne: userId } });
            if (existingPhone) {
                return next(respond.httpError('Phone number is already in use!', 409));
            }
            updates.phone = phone;
        }

        if (email) {
            const existingEmail = await UserDB.findOne({ email, _id: { $ne: userId } });
            if (existingEmail) {
                return next(respond.httpError('Email is already in use!', 409));
            }
            updates.email = email;
        }

        const user = await UserDB.findByIdAndUpdate(
            userId,
            { $set: updates },
            { new: true, runValidators: true }
        );

        if (!user) {
            return next(respond.httpError('User not found!', 404));
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
        next(err);
    }
};

export const changePassword = async (req, res, next) => {
    try {
        const { oldPassword, newPassword } = req.body;
        const user = await UserDB.findById(req.user.id).select('+password');

        const isMatch = await bcrypt.compare(oldPassword, user.password);
        if (!isMatch) {
            return next(respond.httpError('Old password is incorrect!', 401));
        }

        user.password = await bcrypt.hash(newPassword, 10);
        await user.save();

        res.status(200).json({ success: true, message: 'Password changed successfully!' });
    } catch (error) {
        next(error);
    }
};

export const getSavedPlaces = async (req, res, next) => {
    try {
        const user = await UserDB.findById(req.user.id).populate('savedPlaces');

        if (!user) {
            return next(respond.httpError('User not found', 404));
        }

        res.status(200).json({ 
            success: true, 
            savedPlaces: user.savedPlaces || [] 
        });
    } catch (err) {
        next(err);
    }
};

export const addSavedPlace = async (req, res, next) => {
    try {
        const { placeId } = req.body;

        if (!placeId) {
            return next(respond.httpError('Place ID is required', 400));
        }

        const user = await UserDB.findByIdAndUpdate(
            req.user.id,
            { $addToSet: { savedPlaces: placeId } },
        );

        if (!user) {
            return next(respond.httpError('User not found', 404));
        }

        const newSavedPlace = await PlaceDB.findById(placeId);

        res.status(200).json({ 
            success: true, 
            message: 'Place added to favorites successfully!',
            newPlace: newSavedPlace 
        });
    } catch (err) {
        next(err);
    }
};

export const removeSavedPlace = async (req, res, next) => {
    try {
        const { id } = req.params; 

        if (!id) {
            return next(respond.httpError('Place ID is required', 400));
        }

        await UserDB.findByIdAndUpdate(
            req.user.id,
            { $pull: { savedPlaces: id } }
        );

        res.status(200).json({ 
            success: true, 
            message: 'Removed from favorites successfully!',
            removedId: id
        });
    } catch (err) {
        next(err);
    }
};

export const getSavedTours = async (req, res, next) => {
    try {
        const user = await UserDB.findById(req.user.id).populate('savedTours');

        if (!user) {
            return next(respond.httpError('User not found', 404));
        }

        res.status(200).json({ 
            success: true, 
            savedTours: user.savedTours || [] 
        });
    } catch (err) {
        next(err);
    }
};

export const addSavedTour = async (req, res, next) => {
    try {
        const { tourId } = req.body;

        if (!tourId) {
            return next(respond.httpError('Tour ID is required', 400));
        }

        const user = await UserDB.findByIdAndUpdate(
            req.user.id,
            { $addToSet: { savedTours: tourId } },
        );

        if (!user) {
            return next(respond.httpError('User not found', 404));
        }

        const newSavedTour = await TourDB.findById(tourId);

        res.status(200).json({ 
            success: true, 
            message: 'Tour added to favorites successfully!',
            newTour: newSavedTour 
        });
    } catch (err) {
        next(err);
    }
};

export const removeSavedTour = async (req, res, next) => {
    try {
        const { id } = req.params; 

        if (!id) {
            return next(respond.httpError('Tour ID is required', 400));
        }

        await UserDB.findByIdAndUpdate(
            req.user.id,
            { $pull: { savedTours: id } }
        );

        res.status(200).json({ 
            success: true, 
            message: 'Removed from favorites successfully!',
            removedId: id
        });
    } catch (err) {
        next(err);
    }
};
