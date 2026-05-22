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

export default {
    isValidEmail,
    isValidPhone,
    isValidPassword
};