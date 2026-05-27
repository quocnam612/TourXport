import multer from 'multer';

const imageMimeTypes = new Set([
    'image/jpeg',
    'image/png',
    'image/webp'
]);

export const uploadAvatar = multer({
    storage: multer.memoryStorage(),
    limits: {
        fileSize: 5 * 1024 * 1024
    },
    fileFilter: (req, file, cb) => {
        if (!imageMimeTypes.has(file.mimetype)) {
            const error = new Error('Avatar must be a JPG, PNG, or WEBP image');
            error.statusCode = 400;
            return cb(error);
        }

        cb(null, true);
    }
});
