import jwt from 'jsonwebtoken';
import config from '../config/config.js';

export const generateToken = (user) => {
    const payload = {
        id: user._id,
        name: user.name,
        email: user.email
    };

    return jwt.sign(
        payload,
        config.jwt.key,
        { 
            expiresIn: config.jwt.expiresIn,
            algorithm: config.jwt.algorithm
        }
    );
};