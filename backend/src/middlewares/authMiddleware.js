import jwt from 'jsonwebtoken';
import config from '../config/config.js';

export const authenticate = (req, res, next) => {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({
            success: false,
            message: 'Unauthorized: No token provided'
        });
    }

    const token = authHeader.split(' ')[1];

    try {
        const decoded = jwt.verify(token, config.jwt.key);
        req.user = decoded; // { id: user._id }
        next();
    } catch (err) {
        return res.status(401).json({
            success: false,
            message: 'Unauthorized: Invalid or expired token'
        });
    }
};
