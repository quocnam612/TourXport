export const httpError = (message, statusCode) => Object.assign(new Error(message), { statusCode });

export default {
    httpError
};
