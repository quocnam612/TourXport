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

const exhaustedKeyIndexes = new Set();

const travelAdvisorKeys = () => {
    const keys = [
        config.travelAdvisor.apiKey,
        ...(Array.isArray(config.travelAdvisor.apiKeys) ? config.travelAdvisor.apiKeys : [])
    ].filter(Boolean);
    return [...new Set(keys)];
};

const isUsageLimitResponse = (status, data) => {
    if ([401, 403, 429].includes(status)) {
        return true;
    }

    const message = `${data?.message || ''} ${data?.error || ''}`.toLowerCase();
    return [
        'quota',
        'usage',
        'rate limit',
        'too many requests',
        'exceeded',
        'not subscribed'
    ].some((marker) => message.includes(marker));
};

const requestTravelAdvisor = async (endpoint, params = {}) => {
    const keys = travelAdvisorKeys();
    if (!keys.length) {
        throw travelAdvisorError('Travel Advisor API key is missing', 500);
    }

    let lastError = null;
    for (let index = 0; index < keys.length; index += 1) {
        if (exhaustedKeyIndexes.has(index)) {
            continue;
        }

        const response = await fetch(travelAdvisorUrl(endpoint, params), {
            headers: {
                'x-rapidapi-key': keys[index],
                'x-rapidapi-host': config.travelAdvisor.host,
                Accept: 'application/json'
            }
        });
        const data = await response.json().catch(() => null);

        if (response.ok) {
            return data;
        }

        const message = data?.message || data?.error || `Travel Advisor failed with status ${response.status}`;
        lastError = travelAdvisorError(message, response.status >= 500 ? 502 : response.status);
        if (isUsageLimitResponse(response.status, data)) {
            exhaustedKeyIndexes.add(index);
            console.warn(`Travel Advisor key ${index + 1}/${keys.length} exhausted; rotating to next key.`);
            continue;
        }

        throw lastError;
    }

    throw lastError || travelAdvisorError('All Travel Advisor API keys are exhausted', 429);
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

const normalizeImage = (url) => ({
    url,
    publicId: null,
    source: 'tripadvisor'
});

const imageUrlFromPhoto = (photo) => {
    const images = photo?.images || {};
    return images.original?.url || images.large?.url || images.medium?.url || '';
};

const photoPriority = (photo) => {
    const isBlessed = photo?.is_blessed === true;
    const noLinkedReviews = !photo?.linked_reviews || photo.linked_reviews.length === 0;
    if (isBlessed && noLinkedReviews) return 0;
    if (isBlessed || noLinkedReviews) return 1;
    return 2;
};

export const getReviewsBySourceLocationId = async (sourceLocationId, {
    locationId,
    type,
    limit = 20,
    offset = 0,
    currency = 'USD',
    lang = 'vi_VN',
    keyword
} = {}) => {
    if (!sourceLocationId) {
        return [];
    }

    const data = await requestTravelAdvisor('reviews/list', {
        location_id: sourceLocationId,
        limit,
        offset,
        currency,
        lang,
        keyword
    });

    const reviews = Array.isArray(data?.data) ? data.data : [];
    return reviews.map((review) => normalizeReview(review, { locationId, type }));
};

export const getHighQualityPhotosBySourceLocationId = async (sourceLocationId, {
    limit = 10,
    offset = 0,
    currency = 'VND',
    lang = 'vi_VN',
    excludeUrls = []
} = {}) => {
    if (!sourceLocationId) {
        return [];
    }

    const data = await requestTravelAdvisor('photos/list', {
        location_id: sourceLocationId,
        limit: 50,
        offset,
        currency,
        lang
    });

    const excluded = new Set(excludeUrls.filter(Boolean));
    const seen = new Set(excluded);
    const photos = Array.isArray(data?.data) ? data.data : [];

    return photos
        .map((photo) => ({
            priority: photoPriority(photo),
            url: imageUrlFromPhoto(photo)
        }))
        .filter((photo) => photo.url && !seen.has(photo.url))
        .sort((a, b) => a.priority - b.priority)
        .filter((photo) => {
            if (seen.has(photo.url)) return false;
            seen.add(photo.url);
            return true;
        })
        .slice(0, limit)
        .map((photo) => normalizeImage(photo.url));
};

export default {
    getReviewsBySourceLocationId,
    getHighQualityPhotosBySourceLocationId
};
