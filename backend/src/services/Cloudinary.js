import { v2 as cloudinary } from 'cloudinary';

import config from '../config/config.js';

cloudinary.config({
    cloud_name: config.cloudinary.cloudName,
    api_key: config.cloudinary.apiKey,
    api_secret: config.cloudinary.apiSecret,
    secure: true
});

export const uploadImageBuffer = (buffer, options = {}) => {
    if (!buffer) {
        throw new Error('Image buffer is required');
    }

    const uploadOptions = {
        folder: options.folder || 'tourxport/users/avatars',
        resource_type: 'image',
        unique_filename: true,
        overwrite: false
    };

    return new Promise((resolve, reject) => {
        const uploadStream = cloudinary.uploader.upload_stream(uploadOptions, (error, result) => {
            if (error) {
                return reject(error);
            }

            resolve(result);
        });

        uploadStream.end(buffer);
    });
};

export const deleteImage = async (publicId) => {
    if (!publicId) {
        return null;
    }

    return cloudinary.uploader.destroy(publicId, { resource_type: 'image' });
};

export default {
    uploadImageBuffer,
    deleteImage
};
