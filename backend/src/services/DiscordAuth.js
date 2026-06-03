import config from '../config/config.js';

const discordAuthError = (message, statusCode = 401) => {
    return Object.assign(new Error(message), { statusCode });
};

const readDiscordJson = async (response) => {
    const data = await response.json().catch(() => null);
    if (!response.ok) {
        const message = data?.message || data?.error_description || `Discord request failed with status ${response.status}`;
        throw discordAuthError(message, response.status >= 500 ? 502 : 401);
    }
    return data;
};

const exchangeDiscordCode = async ({ code, redirectUri }) => {
    if (!config.discord.clientId || !config.discord.clientSecret) {
        throw discordAuthError('Discord login is not configured on the server', 500);
    }

    if (!code || typeof code !== 'string') {
        throw discordAuthError('Discord authorization code is required', 400);
    }

    if (!redirectUri || typeof redirectUri !== 'string') {
        throw discordAuthError('Discord redirect URI is required', 400);
    }

    const body = new URLSearchParams({
        client_id: config.discord.clientId,
        client_secret: config.discord.clientSecret,
        grant_type: 'authorization_code',
        code,
        redirect_uri: redirectUri
    });

    const response = await fetch('https://discord.com/api/oauth2/token', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/x-www-form-urlencoded'
        },
        body
    });

    const tokenData = await readDiscordJson(response);
    if (!tokenData?.access_token) {
        throw discordAuthError('Discord did not return an access token');
    }

    return tokenData.access_token;
};

const verifyDiscordAccessToken = async (accessToken) => {
    if (!accessToken || typeof accessToken !== 'string') {
        throw discordAuthError('Discord access token is required', 400);
    }

    const response = await fetch('https://discord.com/api/users/@me', {
        headers: {
            Authorization: `Bearer ${accessToken}`
        }
    });
    const profile = await readDiscordJson(response);

    if (!profile?.id) {
        throw discordAuthError('Invalid Discord account payload');
    }

    const avatarUrl = profile.avatar
        ? `https://cdn.discordapp.com/avatars/${profile.id}/${profile.avatar}.png?size=256`
        : '';

    return {
        discordId: profile.id,
        email: profile.email?.toLowerCase() || null,
        name: profile.global_name || profile.username || 'Discord User',
        avatarUrl
    };
};

export const verifyDiscordAuthorizationCode = async ({ code, redirectUri }) => {
    const accessToken = await exchangeDiscordCode({ code, redirectUri });
    return verifyDiscordAccessToken(accessToken);
};

export default {
    verifyDiscordAuthorizationCode
};
