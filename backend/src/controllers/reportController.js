import mongoose from 'mongoose';

import ReportDB from '../models/ReportDB.js';
import UserDB from '../models/UserDB.js';
import { deleteImage, uploadImageBuffer } from '../services/Cloudinary.js';
import respond from '../utils/respond.js';

const reportTypeOptions = new Set([
    'bug',
    'suggestion',
    'inaccuracy',
    'review',
    'other'
]);

const reportFilter = {
    targetId: { $exists: false },
    reportType: { $in: Array.from(reportTypeOptions) }
};

const isObjectId = (value) =>
    mongoose.Types.ObjectId.isValid(String(value));

const parsePositiveInt = (value, fallback) => {
    const parsed = Number.parseInt(value, 10);

    return Number.isInteger(parsed) && parsed > 0
        ? parsed
        : fallback;
};

const toReportResponse = (doc, currentUserId = null) => ({
    id: doc._id,
    reportType: doc.reportType,
    userId: doc.userId,
    title: doc.title,
    text: doc.text,
    user: doc.user,
    helpful_votes: doc.helpful_votes || 0,
    upvotedBy: (doc.upvotedBy || []).map((userId) => userId.toString()),
    isUpvoted: currentUserId
        ? (doc.upvotedBy || []).some((userId) => userId.toString() === currentUserId)
        : false,
    adminReply: doc.adminReply || '',
    images: doc.images || [],
    createdAt: doc.createdAt,
    updatedAt: doc.updatedAt
});

const uploadReportImageFiles = async (files = []) => {
    if (!files.length) return [];

    const uploadResults = await Promise.all(
        files.map((file) =>
            uploadImageBuffer(file.buffer, { folder: 'tourxport/reports' })
        )
    );

    return uploadResults.map((result) => ({
        url: result.secure_url,
        public_id: result.public_id
    }));
};

const deleteReportImages = (images = []) => {
    const deletePromises = images
        .filter((img) => img.public_id)
        .map((img) => deleteImage(img.public_id));

    if (deletePromises.length > 0) {
        Promise.all(deletePromises).catch((error) => {
            console.error('Failed to delete report images:', error.message || error);
        });
    }
};

const validateReportInput = ({ reportType, title, text }, { partial = false } = {}) => {
    if (!partial || reportType !== undefined) {
        if (!reportTypeOptions.has(reportType)) {
            return 'Loại phản ánh không hợp lệ';
        }
    }

    if (!partial || title !== undefined) {
        if (!title || title.trim().length === 0 || title.trim().length > 100) {
            return 'Tiêu đề phải từ 1 đến 100 ký tự';
        }
    }

    if (!partial || text !== undefined) {
        if (!text || text.trim().length === 0 || text.trim().length > 1000) {
            return 'Nội dung phải từ 1 đến 1000 ký tự';
        }
    }

    return null;
};

// GET /reports
export const getReports = async (req, res, next) => {
    try {
        const page = parsePositiveInt(req.query.page, 1);
        const limit = Math.min(parsePositiveInt(req.query.limit, 20), 100);
        const skip = (page - 1) * limit;

        const [docs, total] = await Promise.all([
            ReportDB.find(reportFilter)
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(limit),
            ReportDB.countDocuments(reportFilter)
        ]);

        res.status(200).json({
            success: true,
            count: docs.length,
            total,
            page,
            totalPages: Math.ceil(total / limit),
            data: docs.map((doc) => toReportResponse(doc))
        });
    } catch (error) {
        next(error);
    }
};

// GET /reports/my-reports
export const getMyReports = async (req, res, next) => {
    try {
        const page = parsePositiveInt(req.query.page, 1);
        const limit = Math.min(parsePositiveInt(req.query.limit, 20), 100);
        const skip = (page - 1) * limit;

        const query = {
            ...reportFilter,
            userId: req.user.id
        };

        const [docs, total] = await Promise.all([
            ReportDB.find(query)
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(limit),
            ReportDB.countDocuments(query)
        ]);

        res.status(200).json({
            success: true,
            count: docs.length,
            total,
            page,
            totalPages: Math.ceil(total / limit),
            data: docs.map((doc) => toReportResponse(doc, req.user.id))
        });
    } catch (error) {
        next(error);
    }
};

// POST /reports/my-reports
export const createReport = async (req, res, next) => {
    try {
        const { reportType = 'other', title, text } = req.body;
        const validationError = validateReportInput({ reportType, title, text });

        if (validationError) {
            return next(respond.httpError(validationError, 400));
        }

        const user = await UserDB.findById(req.user.id);
        if (!user) {
            return next(respond.httpError('Không tìm thấy người dùng', 404));
        }

        const images = await uploadReportImageFiles(req.files || []);

        const doc = await ReportDB.create({
            reportType,
            userId: req.user.id,
            title: title.trim(),
            text: text.trim(),
            helpful_votes: 0,
            adminReply: '',
            images,
            user: {
                username: user.name || user.email,
                avatar: user.avatar || { url: '', public_id: '' }
            }
        });

        res.status(201).json({
            success: true,
            message: 'Phản ánh đã được gửi thành công!',
            data: toReportResponse(doc, req.user.id)
        });
    } catch (error) {
        next(error);
    }
};

// PUT /reports/my-reports/:reportId
export const updateReport = async (req, res, next) => {
    try {
        const { reportId } = req.params;
        const { reportType, title, text } = req.body;

        if (!isObjectId(reportId)) {
            return next(respond.httpError('reportId không hợp lệ', 400));
        }

        const validationError = validateReportInput(
            { reportType, title, text },
            { partial: true }
        );

        if (validationError) {
            return next(respond.httpError(validationError, 400));
        }

        const doc = await ReportDB.findOne({
            _id: reportId,
            userId: req.user.id,
            ...reportFilter
        });

        if (!doc) {
            return next(respond.httpError('Không tìm thấy phản ánh', 404));
        }

        if (reportType) doc.reportType = reportType;
        if (title) doc.title = title.trim();
        if (text) doc.text = text.trim();

        if (req.files && req.files.length > 0) {
            const oldImages = doc.images || [];
            doc.images = await uploadReportImageFiles(req.files);
            deleteReportImages(oldImages);
        }

        await doc.save();

        res.status(200).json({
            success: true,
            message: 'Phản ánh đã được cập nhật!',
            data: toReportResponse(doc, req.user.id)
        });
    } catch (error) {
        next(error);
    }
};

// GET /reports/upvote?reportId=...
export const upvoteReport = async (req, res, next) => {
    try {
        const reportId = req.query.reportId || req.query.id;

        if (!isObjectId(reportId)) {
            return next(respond.httpError('reportId không hợp lệ', 400));
        }

        const doc = await ReportDB.findOne({
            _id: reportId,
            ...reportFilter
        });

        if (!doc) {
            return next(respond.httpError('Không tìm thấy phản ánh', 404));
        }

        const upvotedBy = doc.upvotedBy || [];
        const hasUpvoted = upvotedBy.some(
            (userId) => userId.toString() === req.user.id
        );

        if (hasUpvoted) {
            doc.upvotedBy = upvotedBy.filter(
                (userId) => userId.toString() !== req.user.id
            );
            doc.helpful_votes = Math.max((doc.helpful_votes || 0) - 1, 0);
        } else {
            doc.upvotedBy.push(req.user.id);
            doc.helpful_votes = (doc.helpful_votes || 0) + 1;
        }

        await doc.save();

        res.status(200).json({
            success: true,
            message: hasUpvoted
                ? 'Đã bỏ upvote phản ánh!'
                : 'Đã upvote phản ánh!',
            data: toReportResponse(doc, req.user.id)
        });
    } catch (error) {
        next(error);
    }
};

// DELETE /reports/my-reports/:reportId
export const deleteReport = async (req, res, next) => {
    try {
        const { reportId } = req.params;

        if (!isObjectId(reportId)) {
            return next(respond.httpError('reportId không hợp lệ', 400));
        }

        const doc = await ReportDB.findOne({
            _id: reportId,
            userId: req.user.id,
            ...reportFilter
        });

        if (!doc) {
            return next(respond.httpError('Không tìm thấy phản ánh', 404));
        }

        await doc.deleteOne();
        deleteReportImages(doc.images || []);

        res.status(200).json({
            success: true,
            message: 'Phản ánh đã được xoá!',
            deletedId: doc._id
        });
    } catch (error) {
        next(error);
    }
};
