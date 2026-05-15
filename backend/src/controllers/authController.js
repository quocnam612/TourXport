import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';

import UserDB from '../models/UserDB.js';
import config from '../config/config.js';

export const login = async (req, res) => {
    try {
        const { phone, email, password } = req.body;
        const identifier = phone || email;

        if (!identifier || !password) { // Missing phone/email or password
            return res.status(400).json({ //400 Bad Request
                success: false,
                message: 'Please provide enough login credentials!'
            });
        }

        const user = await UserDB.findOne({$or: [{ phone: identifier }, { email: identifier }]}).select('+password');

        
        if (!user) { // No user found with the provided phone/email
            return res.status(401).json({ //401 Unauthorized
                success: false,
                message: 'Invalid login credentials!'
            });
        }

        if (!await bcrypt.compare(password, user.password)) { // Wrong password
            return res.status(401).json({
                success: false,
                message: 'Invalid login credentials!'
            });
        }

        const token = jwt.sign({ id: user._id }, config.jwt.key, { expiresIn: config.jwt.expiresIn });

        res.status(200).json({  // 200 OK
            success: true,
            token,
            user: {
                id: user._id,
                name: user.name
            }
        });

    } catch (error) {
        res.status(500).json({ //500 Internal Server Error
            success: false,
            message: 'Server error, please try again later!',
            error: error.message
        });
    }
};

export const register = async (req, res) => {
    try {
        const { name, phone, email, password } = req.body;

        if (!name || !email || !password) { // Missing required fields
            return res.status(400).json({ //400 Bad Request
                success: false,
                message: 'Please provide all required fields!'
            });
        }

        if (await UserDB.findOne({email: email})) { // User already exists
            return res.status(409).json({ //409 Conflict
                success: false,
                message: 'User with this email already exists!'
            });
        }

        if (phone && await UserDB.findOne({phone: phone})) { // User already exists with this phone
            return res.status(409).json({
                success: false,
                message: 'User with this phone number already exists!'
            });
        }

        const hashedPassword = await bcrypt.hash(password, 10);
        await UserDB.create({
            name: name,
            email: email,
            phone: phone || undefined,
            password: hashedPassword
        });

        res.status(201).json({ //201 Created
            success: true,
            message: 'User registered successfully!'
        });

    }
    catch (error) {
        res.status(500).json({
            success: false,
            message: 'Server error, please try again later!',
            error: error.message
        });
    }
};

export const getProfile = async (req, res) => {
    try {
        const user = await UserDB.findById(req.user.id);
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
                phone: user.phone,
                avatarUrl: user.avatarUrl || '',
                coverUrl: user.coverUrl || '',
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

export const getSavedPlaces = async (req, res) => {
    try {
        const user = await UserDB.findById(req.user.id);
        if (!user) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }
        res.json({ success: true, savedPlaces: user.savedPlaces || [] });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
};

export const addSavedPlace = async (req, res) => {
    try {
        const place = req.body;
        if (!place || !place.name) {
            return res.status(400).json({ success: false, message: 'Invalid place data' });
        }

        const user = await UserDB.findByIdAndUpdate(
            req.user.id,
            { $addToSet: { savedPlaces: place } },
            { new: true }
        );

        res.json({ success: true, savedPlaces: user.savedPlaces });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
};

export const removeSavedPlace = async (req, res) => {
    try {
        const { name } = req.body;
        if (!name) {
            return res.status(400).json({ success: false, message: 'Place name is required' });
        }

        const user = await UserDB.findByIdAndUpdate(
            req.user.id,
            { $pull: { savedPlaces: { name: name } } },
            { new: true }
        );

        res.json({ success: true, savedPlaces: user.savedPlaces });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
};

export const updateProfile = async (req, res) => {
    try {
        const { name, phone, email, avatarUrl, coverUrl } = req.body;
        const updates = {};
        if (name) updates.name = name;
        if (phone) updates.phone = phone;
        if (email) updates.email = email;
        if (avatarUrl !== undefined) updates.avatarUrl = avatarUrl;
        if (coverUrl !== undefined) updates.coverUrl = coverUrl;

        const user = await UserDB.findByIdAndUpdate(
            req.user.id,
            { $set: updates },
            { new: true }
        );

        if (!user) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }

        res.json({
            success: true,
            message: 'Profile updated successfully!',
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                phone: user.phone,
                avatarUrl: user.avatarUrl,
                coverUrl: user.coverUrl
            }
        });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
};