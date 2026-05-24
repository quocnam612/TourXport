import { parseBoolean, parseDateToWeekday, parseNumber, parseTimeToMinutes } from './parser.js';

export const isValidEmail = (email) => {
    const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;

    return emailRegex.test(email);
};

export const isValidPhone = (phone) => {
    const phoneRegex = /^0\d{9}$/;

    return phoneRegex.test(phone);
};

export const isValidPassword = (password) => {
    return typeof password === "string" && password.length >= 8;
};

export const isValidGeoCoordinates = (coordinates) => {
    return coordinates == null || (
        Array.isArray(coordinates) &&
        coordinates.length === 2 &&
        coordinates.every((coordinate) => Number.isFinite(Number(coordinate)))
    );
};

export const validateLocationPayload = (payload, { partial = false } = {}) => {
    const requiredFields = ['title', 'city', 'category'];
    const missingFields = partial ? [] : requiredFields.filter((field) => !payload[field]);

    if (missingFields.length > 0) {
        return `Missing required fields: ${missingFields.join(', ')}`;
    }

    if (partial && !payload.location) {
        return null;
    }

    if (!isValidGeoCoordinates(payload.location?.coordinates)) {
        return 'Location coordinates must be [longitude, latitude]';
    }

    return null;
};

export const validateLocationLookupQuery = (query) => {
    const id = query.id || query._id;
    const sourceLocationId = query.sourceLocationId || query.sourceLocationID;

    if (!id && !sourceLocationId) {
        return 'Location id or sourceLocationId is required';
    }

    if (id && !/^[0-9a-fA-F]{24}$/.test(String(id))) {
        return 'Invalid location ID';
    }

    return null;
};

export const validateLocationListQuery = (query) => {
    const hasDate = query.date !== undefined && query.date !== null && query.date !== '';
    const hasTime = query.time !== undefined && query.time !== null && query.time !== '';

    if (hasDate && parseDateToWeekday(query.date) === null) {
        return 'date must use YYYY-MM-DD format or weekday number from 1 to 7';
    }

    if (hasTime && parseTimeToMinutes(query.time) === null) {
        return 'time must use HH:mm format or minutes from 0 to 1439';
    }

    if (query.price !== undefined && query.price !== null && query.price !== '' && parseNumber(query.price) === undefined) {
        return 'price must be a number';
    }

    if (
        query.nullPrice !== undefined
        && query.nullPrice !== null
        && query.nullPrice !== ''
        && parseBoolean(query.nullPrice) === undefined
    ) {
        return 'nullPrice must be true or false';
    }

    return null;
};

export default {
    isValidEmail,
    isValidPhone,
    isValidPassword,
    isValidGeoCoordinates,
    validateLocationPayload,
    validateLocationLookupQuery,
    validateLocationListQuery
};
