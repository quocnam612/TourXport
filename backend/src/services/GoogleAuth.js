import { OAuth2Client } from 'google-auth-library';

import config from '../config/config.js';

const googleClient = new OAuth2Client(config.google.clientId);

const googleAuthError = (message, statusCode = 401) => {
    return Object.assign(new Error(message), { statusCode });
};

export const verifyGoogleIdToken = async (idToken) => {
    if (!config.google.clientId) {
        throw googleAuthError('Google login is not configured on the server', 500);
    }

    if (!idToken || typeof idToken !== 'string') {
        throw googleAuthError('Google ID token is required', 400);
    }

    const ticket = await googleClient.verifyIdToken({
        idToken,
        audience: config.google.clientId
    });

    const payload = ticket.getPayload();
    if (!payload?.sub || !payload?.email) {
        throw googleAuthError('Invalid Google account payload');
    }

    if (payload.email_verified !== true) {
        throw googleAuthError('Google email is not verified');
    }

    return {
        googleId: payload.sub,
        email: payload.email.toLowerCase(),
        name: payload.name || payload.email.split('@')[0],
        avatarUrl: payload.picture || ''
    };
};

export default {
    verifyGoogleIdToken
};
