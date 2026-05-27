import config from '../config/config.js';

const facebookAuthError = (message, statusCode = 401) => {
    return Object.assign(new Error(message), { statusCode });
};

const graphUrl = (path, params = {}) => {
    const url = new URL(`https://graph.facebook.com/${config.facebook.graphVersion}${path}`);
    Object.entries(params).forEach(([key, value]) => {
        if (value !== undefined && value !== null) {
            url.searchParams.set(key, value);
        }
    });
    return url;
};

const readFacebookJson = async (response) => {
    const data = await response.json().catch(() => null);
    if (!response.ok) {
        const message = data?.error?.message || `Facebook request failed with status ${response.status}`;
        throw facebookAuthError(message, response.status >= 500 ? 502 : 401);
    }
    return data;
};

export const verifyFacebookAccessToken = async (accessToken) => {
    if (!config.facebook.appId || !config.facebook.appSecret) {
        throw facebookAuthError('Facebook login is not configured on the server', 500);
    }

    if (!accessToken || typeof accessToken !== 'string') {
        throw facebookAuthError('Facebook access token is required', 400);
    }

    const appAccessToken = `${config.facebook.appId}|${config.facebook.appSecret}`;
    const debugResponse = await fetch(graphUrl('/debug_token', {
        input_token: accessToken,
        access_token: appAccessToken
    }));
    const debugData = await readFacebookJson(debugResponse);
    const tokenData = debugData?.data;

    if (!tokenData?.is_valid || tokenData.app_id !== config.facebook.appId || !tokenData.user_id) {
        throw facebookAuthError('Invalid Facebook access token');
    }

    const profileResponse = await fetch(graphUrl(`/${tokenData.user_id}`, {
        fields: 'id,name,email,picture.type(large)',
        access_token: accessToken
    }));
    const profile = await readFacebookJson(profileResponse);

    if (!profile?.id || profile.id !== tokenData.user_id) {
        throw facebookAuthError('Invalid Facebook account payload');
    }

    return {
        facebookId: profile.id,
        email: profile.email?.toLowerCase() || null,
        name: profile.name || 'Facebook User',
        avatarUrl: profile.picture?.data?.url || ''
    };
};

export default {
    verifyFacebookAccessToken
};
