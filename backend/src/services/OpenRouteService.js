import config from '../config/config.js';

const ORS_BASE_URL = 'https://api.openrouteservice.org';

const isCoordinate = (value) => {
    return Array.isArray(value)
        && value.length === 2
        && value.every((coordinate) => Number.isFinite(Number(coordinate)));
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

export const getDirections = async (fromItem, toItem, { transportMode = 'auto' } = {}) => {
    if (!isCoordinate(fromItem?.location?.coordinates) || !isCoordinate(toItem?.location?.coordinates)) {
        return null;
    }

    const profile = normalizeProfile(transportMode);

    if (!config.openRouteService.apiKey) {
        throw openRouteServiceError('OpenRouteService API key is missing');
    }

    try {
        const params = new URLSearchParams({
            api_key: config.openRouteService.apiKey,
            start: fromItem.location.coordinates.join(','),
            end: toItem.location.coordinates.join(',')
        });
        const response = await fetch(`${ORS_BASE_URL}/v2/directions/${profile}?${params.toString()}`);

        const data = await response.json().catch(() => null);
        if (!response.ok) {
            const message = typeof data?.error === 'string'
                ? data.error
                : data?.error?.message || data?.message || `OpenRouteService failed with status ${response.status}`;
            throw openRouteServiceError(message, 502);
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

        throw openRouteServiceError(`OpenRouteService request failed: ${error.message}`);
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
