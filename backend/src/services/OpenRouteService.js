import config from '../config/config.js';

const ORS_BASE_URL = 'https://api.openrouteservice.org';
const EARTH_RADIUS_METERS = 6371000;

const toRadians = (degrees) => degrees * Math.PI / 180;

const isCoordinate = (value) => {
    return Array.isArray(value)
        && value.length === 2
        && value.every((coordinate) => Number.isFinite(Number(coordinate)));
};

const haversineDistance = ([lng1, lat1], [lng2, lat2]) => {
    const deltaLat = toRadians(lat2 - lat1);
    const deltaLng = toRadians(lng2 - lng1);
    const a = Math.sin(deltaLat / 2) ** 2
        + Math.cos(toRadians(lat1)) * Math.cos(toRadians(lat2)) * Math.sin(deltaLng / 2) ** 2;
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return Math.round(EARTH_RADIUS_METERS * c);
};

const bboxFromCoordinates = (coordinates) => {
    const validCoordinates = coordinates.filter(isCoordinate);
    if (validCoordinates.length === 0) {
        return null;
    }

    const lngs = validCoordinates.map(([lng]) => lng);
    const lats = validCoordinates.map(([, lat]) => lat);

    return {
        minLng: Math.min(...lngs),
        minLat: Math.min(...lats),
        maxLng: Math.max(...lngs),
        maxLat: Math.max(...lats)
    };
};

const normalizeProfile = (transportMode = 'auto') => {
    const profiles = {
        auto: 'driving-car',
        car: 'driving-car',
        motorbike: 'driving-car',
        walking: 'foot-walking',
        public_transport: 'driving-car',
        public: 'driving-car'
    };

    return profiles[transportMode] || 'driving-car';
};

const normalizeStep = (step) => ({
    instruction: step.instruction || '',
    name: step.name || null,
    distanceMeters: step.distance || 0,
    type: step.type ?? null,
    wayPoints: step.way_points || step.wayPoints || []
});

const openRouteServiceError = (message, statusCode = 502) => {
    return Object.assign(new Error(message), { statusCode });
};

const routeContext = (fromItem, toItem) => {
    const fromCoordinates = fromItem.location.coordinates;
    const toCoordinates = toItem.location.coordinates;
    const straightDistance = haversineDistance(fromCoordinates, toCoordinates);

    return `${fromItem.title} ${fromCoordinates.join(',')} -> ${toItem.title} ${toCoordinates.join(',')} (${straightDistance}m straight-line)`;
};

const shouldSkipRouteError = (message) => {
    return /approximated route distance must not be greater than/i.test(message)
        || /could not find routable point/i.test(message)
        || /within a radius of/i.test(message);
};

export const getDirections = async (fromItem, toItem, { transportMode = 'auto' } = {}) => {
    if (!isCoordinate(fromItem?.location?.coordinates) || !isCoordinate(toItem?.location?.coordinates)) {
        return null;
    }

    const profile = normalizeProfile(transportMode);

    if (!config.openRouteService.apiKey) {
        console.warn('WARNING: OPENROUTESERVICE_API_KEY is not defined in .env file! Skipping day routes generation.');
        return null;
    }

    try {
        const response = await fetch(`${ORS_BASE_URL}/v2/directions/${profile}/geojson`, {
            method: 'POST',
            headers: {
                Authorization: config.openRouteService.apiKey,
                'Content-Type': 'application/json',
                Accept: 'application/json, application/geo+json'
            },
            body: JSON.stringify({
                coordinates: [
                    fromItem.location.coordinates,
                    toItem.location.coordinates
                ],
                options: {
                    avoid_borders: 'all'
                }
            })
        });

        const data = await response.json().catch(() => null);
        if (!response.ok) {
            const message = typeof data?.error === 'string'
                ? data.error
                : data?.error?.message || data?.message || `OpenRouteService failed with status ${response.status}`;
            const detailedMessage = `${message}. Segment: ${routeContext(fromItem, toItem)}`;

            if (shouldSkipRouteError(message)) {
                console.warn(`Skipping route segment: ${detailedMessage}`);
                return null;
            }

            throw openRouteServiceError(detailedMessage, 502);
        }

        const feature = data?.features?.[0];
        const coordinates = feature?.geometry?.coordinates;
        if (!Array.isArray(coordinates) || coordinates.length < 2) {
            return null;
        }

        const segment = feature.properties?.segments?.[0] || {};

        return {
            fromOrder: fromItem.order,
            toOrder: toItem.order,
            provider: 'openrouteservice',
            profile,
            distanceMeters: segment.distance || feature.properties?.summary?.distance || 0,
            bbox: bboxFromCoordinates(coordinates),
            geometry: {
                type: 'LineString',
                coordinates
            },
            steps: (segment.steps || []).map(normalizeStep)
        };
    } catch (error) {
        if (error.statusCode) {
            throw error;
        }

        throw openRouteServiceError(`OpenRouteService request failed: ${error.message}. Segment: ${routeContext(fromItem, toItem)}`);
    }
};

export const buildDayRoutes = async (items, options = {}) => {
    const routes = [];
    const routableItems = items.filter((item) => isCoordinate(item?.location?.coordinates));

    for (let index = 0; index < routableItems.length - 1; index += 1) {
        const route = await getDirections(routableItems[index], routableItems[index + 1], options);
        if (route) {
            routes.push(route);
        }
    }

    return routes;
};

export const calculateBbox = bboxFromCoordinates;

export default {
    getDirections,
    buildDayRoutes,
    calculateBbox
};
