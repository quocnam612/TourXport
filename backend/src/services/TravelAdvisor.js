import config from '../config/config.js';

const travelAdvisorError = (message, statusCode = 502) => {
    return Object.assign(new Error(message), { statusCode });
};

const travelAdvisorUrl = (endpoint, params = {}) => {
    const url = new URL(`https://${config.travelAdvisor.host}/${endpoint}`);
    Object.entries(params).forEach(([key, value]) => {
        if (value !== undefined && value !== null && value !== '') {
            url.searchParams.set(key, value);
        }
    });
    return url;
};

const normalizeReview = (review, { locationId, type }) => ({
    userId: null,
    locationId,
    type,
    rating: Number(review.rating) || 0,
    helpful_votes: Number(review.helpful_votes) || 0,
    travel_date: review.travel_date || null,
    title: review.title || '',
    text: review.text || '',
    user: {
        username: review.user?.username || review.user?.name || 'Tripadvisor user',
        avatar: {
            url: review.user?.avatar?.large?.url
                || review.user?.avatar?.thumbnail?.url
                || review.user?.avatar?.url
                || '',
            public_id: ''
        }
    }
});

export const getReviewsBySourceLocationId = async (sourceLocationId, {
    locationId,
    type,
    limit = 20,
    offset = 0,
    currency = 'USD',
    lang = 'vi_VN',
    keyword
} = {}) => {
    if (!config.travelAdvisor.apiKey) {
        throw travelAdvisorError('Travel Advisor API key is missing', 500);
    }

    if (!sourceLocationId) {
        return [];
    }

    const response = await fetch(travelAdvisorUrl('reviews/list', {
        location_id: sourceLocationId,
        limit,
        offset,
        currency,
        lang,
        keyword
    }), {
        headers: {
            'x-rapidapi-key': config.travelAdvisor.apiKey,
            'x-rapidapi-host': config.travelAdvisor.host,
            Accept: 'application/json'
        }
    });

    const data = await response.json().catch(() => null);
    if (!response.ok) {
        const message = data?.message || data?.error || `Travel Advisor failed with status ${response.status}`;
        throw travelAdvisorError(message, response.status >= 500 ? 502 : response.status);
    }

    const reviews = Array.isArray(data?.data) ? data.data : [];
    return reviews.map((review) => normalizeReview(review, { locationId, type }));
};

export default {
    getReviewsBySourceLocationId
};
