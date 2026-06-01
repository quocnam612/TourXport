import config from '../config/config.js';

const baseUrl = config.aiBackend.url;

const sleep = (ms) => new Promise((resolve) => {
    setTimeout(resolve, ms);
});

const buildUrl = (path) => new URL(path, baseUrl).toString();

const aiBackendError = (message, statusCode = 502) => Object.assign(new Error(message), { statusCode });

const fetchWithTimeout = async (url, options = {}, timeoutMs) => {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), timeoutMs);

    try {
        return await fetch(url, {
            ...options,
            signal: controller.signal
        });
    } finally {
        clearTimeout(timeout);
    }
};

const ping = async () => {
    try {
        const response = await fetchWithTimeout(
            buildUrl('/'),
            { method: 'GET' },
            config.aiBackend.pingTimeoutMs
        );

        return response.ok;
    } catch (error) {
        return false;
    }
};

const waitUntilReady = async () => {
    for (let attempt = 1; attempt <= config.aiBackend.pingAttempts; attempt += 1) {
        const isReady = await ping();
        if (isReady) {
            return;
        }

        if (attempt < config.aiBackend.pingAttempts) {
            console.warn(
                `AI backend is not ready. Retrying in ${config.aiBackend.pingDelayMs}ms `
                + `(${attempt}/${config.aiBackend.pingAttempts})...`
            );
            await sleep(config.aiBackend.pingDelayMs);
        }
    }

    throw aiBackendError('Unable to connect to AI backend after multiple attempts', 503);
};

const requestJson = async (path, payload, { timeoutMs = config.aiBackend.requestTimeoutMs } = {}) => {
    const response = await fetchWithTimeout(
        buildUrl(path),
        {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(payload)
        },
        timeoutMs
    );

    const data = await response.json().catch(() => null);

    if (!response.ok) {
        const message = data?.detail || data?.message || `AI backend request failed with status ${response.status}`;
        throw aiBackendError(message, response.status);
    }

    return data;
};

export const generateTrip = async (payload) => {
    await waitUntilReady();
    return requestJson('/api/trip/generate', payload);
};

export default {
    generateTrip
};
