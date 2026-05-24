const escapeRegex = (value) => String(value).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const regexVariants = (value) => {
    const text = String(value).trim();
    const variants = new Set([
        text,
        text.normalize('NFC'),
        text.normalize('NFD')
    ]);

    return [...variants].map((variant) => new RegExp(escapeRegex(variant), 'i'));
};

const textFilterForField = (field, value) => {
    const variants = regexVariants(value);
    return variants.length === 1 ? { [field]: variants[0] } : { [field]: { $in: variants } };
};

const addAndFilter = (filter, clause) => {
    if (!filter.$and) {
        filter.$and = [];
    }
    filter.$and.push(clause);
};

const keepUnknownHoursOr = (clause) => ({
    $or: [
        { 'openingHours.weekRanges': null },
        { 'openingHours.weekRanges': { $exists: false } },
        clause
    ]
});

export const parsePositiveInt = (value, fallback) => {
    const parsed = Number.parseInt(value, 10);
    return Number.isInteger(parsed) && parsed > 0 ? parsed : fallback;
};

export const parseNumber = (value, fallback = undefined) => {
    if (value === undefined || value === null || value === '') {
        return fallback;
    }

    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : fallback;
};

export const parseBoolean = (value, fallback = undefined) => {
    if (value === undefined || value === null || value === '') {
        return fallback;
    }

    if (value === true || String(value).toLowerCase() === 'true') {
        return true;
    }

    if (value === false || String(value).toLowerCase() === 'false') {
        return false;
    }

    return fallback;
};

export const parseGps = (value) => {
    if (value === undefined || value === null || value === '') {
        return null;
    }

    const coordinates = Array.isArray(value)
        ? value
        : String(value).split(',');

    if (coordinates.length !== 2) {
        return null;
    }

    const longitude = parseNumber(coordinates[0]);
    const latitude = parseNumber(coordinates[1]);

    if (
        longitude === undefined
        || latitude === undefined
        || longitude < -180
        || longitude > 180
        || latitude < -90
        || latitude > 90
    ) {
        return null;
    }

    return [longitude, latitude];
};

export const parsePriceRange = (priceRange) => {
    if (priceRange === undefined || priceRange === null || priceRange === '') {
        return null;
    }

    const numbers = String(priceRange)
        .match(/\d[\d.,]*/g)
        ?.map((value) => Number(value.replace(/[.,]/g, '')))
        .filter(Number.isFinite) || [];

    if (numbers.length === 0) {
        return null;
    }

    return {
        min: Math.min(...numbers),
        max: Math.max(...numbers)
    };
};

export const filterByPriceRange = (items, price, nullPrice = true) => {
    const parsedPrice = parseNumber(price);
    const includeNullPrice = parseBoolean(nullPrice, true);

    if (parsedPrice === undefined && includeNullPrice) {
        return items;
    }

    return items.filter((item) => {
        if (!item.priceRange) {
            return includeNullPrice;
        }

        if (parsedPrice === undefined) {
            return true;
        }

        const range = parsePriceRange(item.priceRange);
        return range !== null && range.min <= parsedPrice && parsedPrice <= range.max;
    });
};

export const parseTimeToMinutes = (value) => {
    if (value === undefined || value === null || value === '') {
        return null;
    }

    if (/^\d+$/.test(String(value))) {
        const minutes = Number(value);
        return minutes >= 0 && minutes <= 1439 ? minutes : null;
    }

    const match = String(value).trim().match(/^(\d{1,2}):(\d{2})$/);
    if (!match) {
        return null;
    }

    const hours = Number(match[1]);
    const minutes = Number(match[2]);
    if (hours < 0 || hours > 23 || minutes < 0 || minutes > 59) {
        return null;
    }

    return hours * 60 + minutes;
};

export const parseDateToWeekday = (value) => {
    if (!value) {
        return null;
    }

    if (/^[1-7]$/.test(String(value).trim())) {
        return Number(value) - 1;
    }

    const match = String(value).trim().match(/^(\d{4})-(\d{2})-(\d{2})$/);
    if (!match) {
        return null;
    }

    const year = Number(match[1]);
    const month = Number(match[2]);
    const day = Number(match[3]);
    const date = new Date(Date.UTC(year, month - 1, day));

    if (
        date.getUTCFullYear() !== year
        || date.getUTCMonth() !== month - 1
        || date.getUTCDate() !== day
    ) {
        return null;
    }

    return date.getUTCDay();
};

const hasOwn = (object, key) => Object.prototype.hasOwnProperty.call(object, key);

export const buildTextFilter = (query) => {
    if (!query) {
        return {};
    }

    const variants = regexVariants(query);
    return {
        $or: variants.flatMap((regex) => [
            { title: regex },
            { city: regex },
            { category: regex },
            { searchText: regex },
            { tags: regex }
        ])
    };
};

export const buildLocationFilter = (query) => {
    const filter = {
        ...buildTextFilter(query.query)
    };

    if (query.city) {
        Object.assign(filter, textFilterForField('city', query.city));
    }

    if (query.category) {
        Object.assign(filter, textFilterForField('category', query.category));
    }

    if (query.tag) {
        const tags = Array.isArray(query.tag) ? query.tag : [query.tag];
        filter.tags = {
            $all: tags
                .filter((tag) => String(tag).trim())
                .map((tag) => ({ $elemMatch: { $in: regexVariants(tag) } }))
        };
    }

    const minScore = parseNumber(query.minScore);
    if (minScore !== undefined) {
        filter.totalScore = { ...(filter.totalScore || {}), $gte: minScore };
    }

    const maxScore = parseNumber(query.maxScore);
    if (maxScore !== undefined) {
        filter.totalScore = { ...(filter.totalScore || {}), $lte: maxScore };
    }

    const gps = parseGps(query.gps);
    const radius = parseNumber(query.radius);
    if (gps && radius !== undefined) {
        filter.location = {
            $geoWithin: {
                $centerSphere: [gps, radius / 6378137]
            }
        };
    }

    const hasDate = query.date !== undefined && query.date !== null && query.date !== '';
    const hasTime = query.time !== undefined && query.time !== null && query.time !== '';
    const time = parseTimeToMinutes(query.time);
    const weekday = parseDateToWeekday(query.date);

    if (hasTime && hasDate) {
        addAndFilter(filter, keepUnknownHoursOr({
            [`openingHours.weekRanges.${weekday}`]: {
                $elemMatch: {
                    open_time: { $lt: time },
                    close_time: { $gt: time }
                }
            }
        }));
    } else if (hasTime) {
        addAndFilter(filter, keepUnknownHoursOr({
            'openingHours.weekRanges': {
                $elemMatch: {
                    $elemMatch: {
                        open_time: { $lt: time },
                        close_time: { $gt: time }
                    }
                }
            }
        }));
    } else if (hasDate) {
        addAndFilter(filter, keepUnknownHoursOr({
            [`openingHours.weekRanges.${weekday}`]: {
                $elemMatch: {
                    open_time: { $gte: 0, $lte: 1439 },
                    close_time: { $gte: 0, $lte: 1439 }
                }
            }
        }));
    }

    return filter;
};

export const buildSort = (sortBy = 'totalScore', order = 'desc') => {
    const allowedFields = new Set([
        'title',
        'city',
        'totalScore',
        'reviewsCount',
        'createdAt',
        'updatedAt'
    ]);

    const field = allowedFields.has(sortBy) ? sortBy : 'totalScore';
    const direction = order === 'asc' ? 1 : -1;
    return { [field]: direction, reviewsCount: -1, _id: 1 };
};

export const buildLocationLookupFilter = (query) => {
    const id = query.id || query._id;
    const sourceLocationId = query.sourceLocationId || query.sourceLocationID;

    if (id) {
        return { _id: id };
    }

    return { sourceLocationId };
};

export const normalizeLocationPayload = (payload, { partial = false } = {}) => {
    const location = payload.location || {};
    const normalized = {};

    const assign = (key, value) => {
        if (!partial || hasOwn(payload, key)) {
            normalized[key] = value;
        }
    };

    assign('sourceLocationId', payload.sourceLocationId ?? null);
    assign('title', payload.title);
    assign('city', payload.city);
    assign('totalScore', payload.totalScore ?? 0);
    assign('ranking', payload.ranking ?? null);
    assign('reviewsCount', payload.reviewsCount ?? 0);
    assign('category', payload.category);
    assign('priceRange', payload.priceRange ?? null);
    assign('description', payload.description ?? null);
    assign('embedding', payload.embedding ?? null);
    assign('searchText', payload.searchText ?? null);
    assign('tags', Array.isArray(payload.tags) ? payload.tags : []);
    assign('openingHours', payload.openingHours ?? null);

    if (!partial || hasOwn(payload, 'image')) {
        normalized.image = {
            url: payload.image?.url ?? null,
            publicId: payload.image?.publicId ?? null,
            source: payload.image?.source ?? ''
        };
    }

    if (
        !partial
        || hasOwn(payload, 'location')
        || hasOwn(payload, 'longitude')
        || hasOwn(payload, 'latitude')
    ) {
        const coordinates = Array.isArray(location.coordinates)
            ? location.coordinates
            : [
                parseNumber(payload.longitude),
                parseNumber(payload.latitude)
            ];

        normalized.location = {
            type: location.type || 'Point',
            coordinates
        };
    }

    return normalized;
};

export default {
    parsePositiveInt,
    parseNumber,
    parseBoolean,
    parseGps,
    parsePriceRange,
    filterByPriceRange,
    parseTimeToMinutes,
    parseDateToWeekday,
    buildTextFilter,
    buildLocationFilter,
    buildLocationLookupFilter,
    buildSort,
    normalizeLocationPayload
};
