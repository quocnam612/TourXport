import config from '../config/config.js';

const baseUrl = config.aiBackend.url;

const requestJson = async (path, payload, { timeoutMs = 120000 } = {}) => {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), timeoutMs);

    try {
        const response = await fetch(`${baseUrl}${path}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(payload),
            signal: controller.signal
        });

        const data = await response.json().catch(() => null);

        if (!response.ok) {
            const message = data?.detail || data?.message || `AI backend request failed with status ${response.status}`;
            throw new Error(message);
        }

        return data;
    } finally {
        clearTimeout(timeout);
    }
};

export const generateTrip = (payload) => {
    return requestJson('/api/trip/generate', payload);
};

export default {
    generateTrip
};
