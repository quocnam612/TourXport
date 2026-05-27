import { parseBoolean, parseDateToWeekday, parseGps, parseNumber, parsePositiveInt, parseTimeToMinutes } from './parser.js';

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
    const hasGps = query.gps !== undefined && query.gps !== null && query.gps !== '';
    const hasRadius = query.radius !== undefined && query.radius !== null && query.radius !== '';

    if (hasDate && parseDateToWeekday(query.date) === null) {
        return 'date must use YYYY-MM-DD format or weekday number from 1 to 7';
    }

    if (hasTime && parseTimeToMinutes(query.time) === null) {
        return 'time must use HH:mm format or minutes from 0 to 1439';
    }

    if (query.price !== undefined && query.price !== null && query.price !== '' && parseNumber(query.price) === undefined) {
        return 'price must be a number';
    }

    if (hasGps !== hasRadius) {
        return 'gps and radius must be provided together';
    }

    if (hasGps && parseGps(query.gps) === null) {
        return 'gps must use longitude,latitude format';
    }

    if (hasRadius) {
        const radius = parseNumber(query.radius);
        if (radius === undefined || radius <= 0) {
            return 'radius must be a positive number in meters';
        }
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

export const validateTourListQuery = (query) => {
    if (query.totalDays !== undefined && query.totalDays !== null && query.totalDays !== '' && parsePositiveInt(query.totalDays) === undefined) {
        return 'totalDays must be a positive integer';
    }

    if (query.totalNights !== undefined && query.totalNights !== null && query.totalNights !== '') {
        const totalNights = parseNumber(query.totalNights);
        if (totalNights === undefined || totalNights < 0) {
            return 'totalNights must be a number greater than or equal to 0';
        }
    }

    if (query.visibility && !['private', 'public'].includes(query.visibility)) {
        return 'visibility must be private or public';
    }

    if (query.order && !['asc', 'desc'].includes(query.order)) {
        return 'order must be asc or desc';
    }

    return null;
};

export const validateTourUpdatePayload = (payload) => {
    if (!payload || Object.keys(payload).length === 0) {
        return 'No fields provided for update';
    }

    if (payload.visibility && !['private', 'public'].includes(payload.visibility)) {
        return 'visibility must be private or public';
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
    validateLocationListQuery,
    validateTourListQuery,
    validateTourUpdatePayload
};
