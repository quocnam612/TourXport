import bcrypt from 'bcrypt';

import UserDB from '../models/UserDB.js';
import PlaceDB from '../models/PlaceDB.js';
import RestaurantDB from '../models/RestaurantDB.js';
import HotelDB from '../models/HotelDB.js';
import TourDB from '../models/TourDB.js';

import respond from '../utils/respond.js';
import { generateToken } from '../utils/jwt.js';
import GoogleAuth from '../services/GoogleAuth.js';
import DiscordAuth from '../services/DiscordAuth.js';
import { deleteImage, uploadImageBuffer } from '../services/Cloudinary.js';
import AIBackend from '../services/AIBackend.js';

const locationPublicProjection = '-embedding -searchText';
const allowedAuthProviders = new Set(['local', 'google', 'discord']);

const normalizeAuthProviders = (providers = []) => {
    return [...new Set((providers || []).filter((provider) => allowedAuthProviders.has(provider)))];
};

const withAuthProvider = (providers, provider) => {
    return [...new Set([...normalizeAuthProviders(providers), provider])];
};

const warmUpAIBackend = () => {
    AIBackend.warmUp().catch((error) => {
        console.warn(`AI backend warm-up failed: ${error.message || error}`);
    });
};

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

        if (!user.password) {
            return next(respond.httpError('This account uses social login. Please continue with Google or Discord.', 401));
        }

        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return next(respond.httpError('Invalid login credentials!', 401));
        }

        const token = generateToken(user);
        warmUpAIBackend();

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

        const existingUser = await UserDB.findOne({ email }).select('+password');

        if (existingUser?.password) {
            return next(respond.httpError('User with this email already exists!', 409));
        }

        if (phone && await UserDB.findOne({
            phone,
            ...(existingUser ? { _id: { $ne: existingUser._id } } : {})
        })) {
            return next(respond.httpError('User with this phone number already exists!', 409));
        }

        const hashedPassword = await bcrypt.hash(password, 10);

        const user = existingUser || new UserDB({ email });
        user.name = user.name || name;
        user.phone = user.phone || phone || undefined;
        user.password = hashedPassword;
        user.authProvider = withAuthProvider(user.authProvider, 'local');
        await user.save();

        const token = generateToken(user);
        warmUpAIBackend();

        res.status(existingUser ? 200 : 201).json({
            success: true,
            message: existingUser
                ? 'Local login linked successfully!'
                : 'User registered successfully!',
            token,
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                authProvider: normalizeAuthProviders(user.authProvider)
            }
        });

    } catch (error) {
        next(error);
    }
};

export const googleLogin = async (req, res, next) => {
    try {
        const { idToken } = req.body;
        const googleProfile = await GoogleAuth.verifyGoogleIdToken(idToken);

        let user = await UserDB.findOne({
            $or: [
                { googleId: googleProfile.googleId },
                { email: googleProfile.email }
            ]
        });

        if (user) {
            user.googleId = user.googleId || googleProfile.googleId;
            user.authProvider = withAuthProvider(user.authProvider, 'google');

            if (!user.avatar?.url && googleProfile.avatarUrl) {
                user.avatar = {
                    url: googleProfile.avatarUrl,
                    public_id: ''
                };
            }

            await user.save();
        } else {
            user = await UserDB.create({
                name: googleProfile.name,
                email: googleProfile.email,
                googleId: googleProfile.googleId,
                authProvider: ['google'],
                avatar: googleProfile.avatarUrl
                    ? { url: googleProfile.avatarUrl, public_id: '' }
                    : undefined
            });
        }

        const token = generateToken(user);
        warmUpAIBackend();

        res.status(200).json({
            success: true,
            message: 'Google login successful!',
            token,
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                avatar: user.avatar?.url || '',
                authProvider: normalizeAuthProviders(user.authProvider)
            }
        });
    } catch (error) {
        next(respond.httpError(error.message || 'Google login failed', error.statusCode || 401));
    }
};

export const discordLogin = async (req, res, next) => {
    try {
        const { code, redirectUri } = req.body;
        const discordProfile = await DiscordAuth.verifyDiscordAuthorizationCode({ code, redirectUri });

        let user = await UserDB.findOne({
            $or: [
                { discordId: discordProfile.discordId },
                ...(discordProfile.email ? [{ email: discordProfile.email }] : [])
            ]
        });

        if (user) {
            user.discordId = user.discordId || discordProfile.discordId;
            user.authProvider = withAuthProvider(user.authProvider, 'discord');

            if (!user.avatar?.url && discordProfile.avatarUrl) {
                user.avatar = {
                    url: discordProfile.avatarUrl,
                    public_id: ''
                };
            }

            await user.save();
        } else {
            if (!discordProfile.email) {
                return next(respond.httpError('Discord email permission is required to create an account', 400));
            }

            user = await UserDB.create({
                name: discordProfile.name,
                email: discordProfile.email,
                discordId: discordProfile.discordId,
                authProvider: ['discord'],
                avatar: discordProfile.avatarUrl
                    ? { url: discordProfile.avatarUrl, public_id: '' }
                    : undefined
            });
        }

        const token = generateToken(user);
        warmUpAIBackend();

        res.status(200).json({
            success: true,
            message: 'Discord login successful!',
            token,
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                avatar: user.avatar?.url || '',
                authProvider: normalizeAuthProviders(user.authProvider)
            }
        });
    } catch (error) {
        next(respond.httpError(error.message || 'Discord login failed', error.statusCode || 401));
    }
};

export const getProfile = async (req, res, next) => {
    try {
        const user = await UserDB.findById(req.user.id).select('-savedPlaces -savedRestaurants -savedHotels -savedTours -password');

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
                avatarPublicId: user.avatar?.public_id || '',
                authProvider: normalizeAuthProviders(user.authProvider),
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
                avatar: user.avatar?.url || '',
                avatarPublicId: user.avatar?.public_id || ''
            }
        });
    } catch (err) {
        next(err);
    }
};

export const updateAvatar = async (req, res, next) => {
    try {
        if (!req.file) {
            return next(respond.httpError('Avatar image is required', 400));
        }

        const user = await UserDB.findById(req.user.id);
        if (!user) {
            return next(respond.httpError('User not found!', 404));
        }

        const oldAvatarPublicId = user.avatar?.public_id;
        const uploadedAvatar = await uploadImageBuffer(req.file.buffer);

        user.avatar = {
            url: uploadedAvatar.secure_url,
            public_id: uploadedAvatar.public_id
        };
        await user.save();

        if (oldAvatarPublicId) {
            deleteImage(oldAvatarPublicId).catch((error) => {
                console.error(`Failed to delete old avatar ${oldAvatarPublicId}:`, error.message || error);
            });
        }

        res.status(200).json({
            success: true,
            message: 'Avatar updated successfully!',
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                phone: user.phone || '',
                avatar: user.avatar?.url || '',
                avatarPublicId: user.avatar?.public_id || ''
            }
        });
    } catch (error) {
        next(error);
    }
};

export const changePassword = async (req, res, next) => {
    try {
        const { oldPassword, newPassword } = req.body;
        const user = await UserDB.findById(req.user.id).select('+password');

        if (!user) {
            return next(respond.httpError('User not found!', 404));
        }

        if (!newPassword || typeof newPassword !== 'string' || newPassword.length < 8) {
            return next(respond.httpError('New password must be at least 8 characters', 400));
        }

        const hadLocalPassword = Boolean(user.password);

        if (hadLocalPassword) {
            if (!oldPassword || typeof oldPassword !== 'string') {
                return next(respond.httpError('Old password is required', 400));
            }

            const isMatch = await bcrypt.compare(oldPassword, user.password);
            if (!isMatch) {
                return next(respond.httpError('Old password is incorrect!', 401));
            }
        }

        const changedAt = new Date();
        user.password = await bcrypt.hash(newPassword, 10);
        user.authProvider = withAuthProvider(user.authProvider, 'local');
        user.lastPasswordChange = changedAt;
        await user.save();

        res.status(200).json({
            success: true,
            message: hadLocalPassword ? 'Password changed successfully!' : 'Local login added successfully!',
            lastPasswordChange: changedAt,
            authProvider: normalizeAuthProviders(user.authProvider)
        });
    } catch (error) {
        next(error);
    }
};

export const addLoginMethod = async (req, res, next) => {
    try {
        const { provider, password, idToken, code, redirectUri } = req.body;

        if (!['local', 'google', 'discord'].includes(provider)) {
            return next(respond.httpError('provider must be local, google, or discord', 400));
        }

        const user = await UserDB.findById(req.user.id).select('+password');
        if (!user) {
            return next(respond.httpError('User not found!', 404));
        }

        if (normalizeAuthProviders(user.authProvider).includes(provider)) {
            return next(respond.httpError(`${provider} login is already linked`, 409));
        }

        if (provider === 'local') {
            if (!password || typeof password !== 'string' || password.length < 8) {
                return next(respond.httpError('password must be at least 8 characters', 400));
            }

            user.password = await bcrypt.hash(password, 10);
        }

        if (provider === 'google') {
            const googleProfile = await GoogleAuth.verifyGoogleIdToken(idToken);

            if (googleProfile.email !== user.email) {
                return next(respond.httpError('Google account email must match your current account email', 409));
            }

            const existingGoogleUser = await UserDB.findOne({
                googleId: googleProfile.googleId,
                _id: { $ne: user._id }
            });
            if (existingGoogleUser) {
                return next(respond.httpError('This Google account is already linked to another user', 409));
            }

            user.googleId = googleProfile.googleId;

            if (!user.avatar?.url && googleProfile.avatarUrl) {
                user.avatar = {
                    url: googleProfile.avatarUrl,
                    public_id: ''
                };
            }
        }

        if (provider === 'discord') {
            const discordProfile = await DiscordAuth.verifyDiscordAuthorizationCode({ code, redirectUri });

            if (discordProfile.email && discordProfile.email !== user.email) {
                return next(respond.httpError('Discord account email must match your current account email', 409));
            }

            const existingDiscordUser = await UserDB.findOne({
                discordId: discordProfile.discordId,
                _id: { $ne: user._id }
            });
            if (existingDiscordUser) {
                return next(respond.httpError('This Discord account is already linked to another user', 409));
            }

            user.discordId = discordProfile.discordId;

            if (!user.avatar?.url && discordProfile.avatarUrl) {
                user.avatar = {
                    url: discordProfile.avatarUrl,
                    public_id: ''
                };
            }
        }

        user.authProvider = withAuthProvider(user.authProvider, provider);
        await user.save();

        res.status(200).json({
            success: true,
            message: `${provider} login linked successfully!`,
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                avatar: user.avatar?.url || '',
                authProvider: normalizeAuthProviders(user.authProvider)
            }
        });
    } catch (error) {
        next(respond.httpError(error.message || 'Failed to link login method', error.statusCode || 400));
    }
};

export const getSavedPlaces = async (req, res, next) => {
    try {
        const user = await UserDB.findById(req.user.id).populate('savedPlaces', locationPublicProjection);

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

        const newSavedPlace = await PlaceDB.findById(placeId).select(locationPublicProjection);
        if (!newSavedPlace) {
            return next(respond.httpError('Place not found', 404));
        }

        const user = await UserDB.findByIdAndUpdate(
            req.user.id,
            { $addToSet: { savedPlaces: placeId } },
        );

        if (!user) {
            return next(respond.httpError('User not found', 404));
        }

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

export const getSavedRestaurants = async (req, res, next) => {
    try {
        const user = await UserDB.findById(req.user.id).populate('savedRestaurants', locationPublicProjection);

        if (!user) {
            return next(respond.httpError('User not found', 404));
        }

        res.status(200).json({
            success: true,
            savedRestaurants: user.savedRestaurants || []
        });
    } catch (err) {
        next(err);
    }
};

export const addSavedRestaurant = async (req, res, next) => {
    try {
        const { restaurantId } = req.body;

        if (!restaurantId) {
            return next(respond.httpError('Restaurant ID is required', 400));
        }

        const newSavedRestaurant = await RestaurantDB.findById(restaurantId).select(locationPublicProjection);
        if (!newSavedRestaurant) {
            return next(respond.httpError('Restaurant not found', 404));
        }

        const user = await UserDB.findByIdAndUpdate(
            req.user.id,
            { $addToSet: { savedRestaurants: restaurantId } },
        );

        if (!user) {
            return next(respond.httpError('User not found', 404));
        }

        res.status(200).json({
            success: true,
            message: 'Restaurant added to favorites successfully!',
            newRestaurant: newSavedRestaurant
        });
    } catch (err) {
        next(err);
    }
};

export const removeSavedRestaurant = async (req, res, next) => {
    try {
        const { id } = req.params;

        if (!id) {
            return next(respond.httpError('Restaurant ID is required', 400));
        }

        await UserDB.findByIdAndUpdate(
            req.user.id,
            { $pull: { savedRestaurants: id } }
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

export const getSavedHotels = async (req, res, next) => {
    try {
        const user = await UserDB.findById(req.user.id).populate('savedHotels', locationPublicProjection);

        if (!user) {
            return next(respond.httpError('User not found', 404));
        }

        res.status(200).json({
            success: true,
            savedHotels: user.savedHotels || []
        });
    } catch (err) {
        next(err);
    }
};

export const addSavedHotel = async (req, res, next) => {
    try {
        const { hotelId } = req.body;

        if (!hotelId) {
            return next(respond.httpError('Hotel ID is required', 400));
        }

        const newSavedHotel = await HotelDB.findById(hotelId).select(locationPublicProjection);
        if (!newSavedHotel) {
            return next(respond.httpError('Hotel not found', 404));
        }

        const user = await UserDB.findByIdAndUpdate(
            req.user.id,
            { $addToSet: { savedHotels: hotelId } },
        );

        if (!user) {
            return next(respond.httpError('User not found', 404));
        }

        res.status(200).json({
            success: true,
            message: 'Hotel added to favorites successfully!',
            newHotel: newSavedHotel
        });
    } catch (err) {
        next(err);
    }
};

export const removeSavedHotel = async (req, res, next) => {
    try {
        const { id } = req.params;

        if (!id) {
            return next(respond.httpError('Hotel ID is required', 400));
        }

        await UserDB.findByIdAndUpdate(
            req.user.id,
            { $pull: { savedHotels: id } }
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
