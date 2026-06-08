import mongoose from 'mongoose';

import HotelDB from '../models/HotelDB.js';
import PlaceDB from '../models/PlaceDB.js';
import RestaurantDB from '../models/RestaurantDB.js';
import TourDB from '../models/TourDB.js';
import UserDB from '../models/UserDB.js';
import ReportDB from '../models/ReportDB.js';
import AppReviewDB from '../models/AppReviewDB.js';

import respond from '../utils/respond.js';

const targetModelByType = {
    RestaurantDB,
    HotelDB,
    PlaceDB,
    Tour: TourDB
};

const typeAliases = {
    restaurant: 'RestaurantDB',
    restaurants: 'RestaurantDB',

    hotel: 'HotelDB',
    hotels: 'HotelDB',

    place: 'PlaceDB',
    places: 'PlaceDB',

    tour: 'Tour'
};

const isObjectId = (value) =>
    mongoose.Types.ObjectId.isValid(String(value));

const parsePositiveInt = (value, fallback) => {
    const parsed = Number.parseInt(value, 10);

    return Number.isInteger(parsed) && parsed > 0
        ? parsed
        : fallback;
};

const normalizeType = (type) => {
    const value = String(type || '').trim();

    return typeAliases[value.toLowerCase()]
        || value;
};

const getTargetModel = (type) =>
    targetModelByType[normalizeType(type)];

const buildReportPayload = (body) => {
    const payload = {};

    if (body.category !== undefined)
        payload.category = body.category;

    if (body.title !== undefined)
        payload.title = body.title;

    if (body.text !== undefined)
        payload.text = body.text;

    if (body.attachments !== undefined)
        payload.attachments = body.attachments;

    return payload;
};

const toReportResponse = (report) => ({
    id: report._id,
    userId: report.userId,
    targetId: report.targetId,
    targetType: report.targetType,
    category: report.category,
    title: report.title,
    text: report.text,
    attachments: report.attachments,
    status: report.status,
    adminNote: report.adminNote,
    user: report.user,
    createdAt: report.createdAt,
    updatedAt: report.updatedAt
});

export const getMyReports = async (req, res, next) => {
    try {
        const page = parsePositiveInt(
            req.query.page,
            1
        );

        const limit = Math.min(
            parsePositiveInt(req.query.limit, 20),
            100
        );

        const skip = (page - 1) * limit;

        const [reports, total] =
            await Promise.all([
                ReportDB.find({
                    userId: req.user.id
                })
                    .sort({ createdAt: -1 })
                    .skip(skip)
                    .limit(limit),

                ReportDB.countDocuments({
                    userId: req.user.id
                })
            ]);

        res.status(200).json({
            success: true,
            count: reports.length,
            total,
            page,
            totalPages: Math.ceil(total / limit),
            data: reports.map(toReportResponse)
        });
    } catch (error) {
        next(error);
    }
};

export const createReport = async (req, res, next) => {
    try {
        const {
            targetId,
            targetType
        } = req.body;

        const normalizedType =
            normalizeType(targetType);

        const TargetModel =
            getTargetModel(normalizedType);

        if (!TargetModel) {
            return next(
                respond.httpError(
                    'Invalid targetType',
                    400
                )
            );
        }

        if (!isObjectId(targetId)) {
            return next(
                respond.httpError(
                    'Invalid targetId',
                    400
                )
            );
        }

        const [
            target,
            currentUser,
            existingReport
        ] = await Promise.all([
            TargetModel.findById(targetId),

            UserDB.findById(req.user.id),

            ReportDB.findOne({
                userId: req.user.id,
                targetId,
                targetType: normalizedType,
                status: {
                    $in: [
                        'pending',
                        'reviewing'
                    ]
                }
            })
        ]);

        if (!target) {
            return next(
                respond.httpError(
                    'Target not found',
                    404
                )
            );
        }

        if (!currentUser) {
            return next(
                respond.httpError(
                    'User not found',
                    404
                )
            );
        }

        if (existingReport) {
            return next(
                respond.httpError(
                    'You already submitted a report for this target',
                    409
                )
            );
        }

        const report =
            await ReportDB.create({
                ...buildReportPayload(req.body),

                userId: req.user.id,
                targetId,
                targetType: normalizedType,

                user: {
                    username:
                        currentUser.name,

                    avatar: {
                        url:
                            currentUser.avatar?.url || '',

                        public_id:
                            currentUser.avatar?.public_id || ''
                    }
                }
            });

        res.status(201).json({
            success: true,
            message:
                'Report submitted successfully!',
            data: toReportResponse(report)
        });
    } catch (error) {
        next(error);
    }
};

export const getReportsByTarget = async (
    req,
    res,
    next
) => {
    try {
        const {
            targetType,
            targetId
        } = req.params;

        const reports =
            await ReportDB.find({
                targetType:
                    normalizeType(targetType),
                targetId
            }).sort({
                createdAt: -1
            });

        res.status(200).json({
            success: true,
            count: reports.length,
            data: reports.map(
                toReportResponse
            )
        });
    } catch (error) {
        next(error);
    }
};

export const updateReport = async (
    req,
    res,
    next
) => {
    try {
        const { reportId } = req.params;

        const payload =
            buildReportPayload(req.body);

        const report =
            await ReportDB.findOne({
                _id: reportId,
                userId: req.user.id
            });

        if (!report) {
            return next(
                respond.httpError(
                    'Report not found',
                    404
                )
            );
        }

        if (
            report.status !== 'pending'
        ) {
            return next(
                respond.httpError(
                    'Report is already being processed',
                    400
                )
            );
        }

        Object.assign(
            report,
            payload
        );

        await report.save();

        res.status(200).json({
            success: true,
            message:
                'Report updated successfully!',
            data: toReportResponse(report)
        });
    } catch (error) {
        next(error);
    }
};

export const deleteReport = async (
    req,
    res,
    next
) => {
    try {
        const { reportId } = req.params;

        const report =
            await ReportDB.findOne({
                _id: reportId,
                userId: req.user.id
            });

        if (!report) {
            return next(
                respond.httpError(
                    'Report not found',
                    404
                )
            );
        }

        if (
            report.status !== 'pending'
        ) {
            return next(
                respond.httpError(
                    'Processed reports cannot be deleted',
                    400
                )
            );
        }

        await report.deleteOne();

        res.status(200).json({
            success: true,
            message:
                'Report deleted successfully!',
            deletedId: report._id
        });
    } catch (error) {
        next(error);
    }
};

// ═══════════════════════════════════════════════════════════════════════════
// PHẢN ÁNH ỨNG DỤNG (App Feedback) – tái dùng AppReviewDB / app_reviews
// ═══════════════════════════════════════════════════════════════════════════

const toFeedbackResponse = (doc) => ({
    id: doc._id,
    userId: doc.userId,
    rating: doc.rating,
    title: doc.title,
    text: doc.text,
    user: doc.user,
    helpful_votes: doc.helpful_votes,
    createdAt: doc.createdAt,
    updatedAt: doc.updatedAt
});

// GET /reports/app-feedback  (public)
export const getAllAppFeedback = async (req, res, next) => {
    try {
        const page  = parsePositiveInt(req.query.page, 1);
        const limit = Math.min(parsePositiveInt(req.query.limit, 20), 100);
        const skip  = (page - 1) * limit;

        const [docs, total] = await Promise.all([
            AppReviewDB.find().sort({ createdAt: -1 }).skip(skip).limit(limit),
            AppReviewDB.countDocuments()
        ]);

        res.status(200).json({
            success: true,
            count: docs.length,
            total,
            page,
            totalPages: Math.ceil(total / limit),
            data: docs.map(toFeedbackResponse)
        });
    } catch (error) {
        next(error);
    }
};

// GET /reports/app-feedback/my  (authenticated)
export const getMyAppFeedback = async (req, res, next) => {
    try {
        const page  = parsePositiveInt(req.query.page, 1);
        const limit = Math.min(parsePositiveInt(req.query.limit, 20), 100);
        const skip  = (page - 1) * limit;

        const [docs, total] = await Promise.all([
            AppReviewDB.find({ userId: req.user.id }).sort({ createdAt: -1 }).skip(skip).limit(limit),
            AppReviewDB.countDocuments({ userId: req.user.id })
        ]);

        res.status(200).json({
            success: true,
            count: docs.length,
            total,
            page,
            totalPages: Math.ceil(total / limit),
            data: docs.map(toFeedbackResponse)
        });
    } catch (error) {
        next(error);
    }
};

// POST /reports/app-feedback  (authenticated)
export const createAppFeedback = async (req, res, next) => {
    try {
        const { rating, title, text } = req.body;

        if (!rating || !title || !text) {
            return next(respond.httpError('Rating, title và nội dung là bắt buộc', 400));
        }

        if (rating < 1 || rating > 5) {
            return next(respond.httpError('Rating phải từ 1 đến 5', 400));
        }

        if (title.trim().length === 0 || title.trim().length > 100) {
            return next(respond.httpError('Tiêu đề phải từ 1 đến 100 ký tự', 400));
        }

        if (text.trim().length === 0 || text.trim().length > 1000) {
            return next(respond.httpError('Nội dung phải từ 1 đến 1000 ký tự', 400));
        }

        const user = await UserDB.findById(req.user.id);
        if (!user) {
            return next(respond.httpError('Không tìm thấy người dùng', 404));
        }

        const doc = new AppReviewDB({
            userId: req.user.id,
            rating: Math.round(rating),
            title: title.trim(),
            text: text.trim(),
            user: {
                username: user.name || user.email,
                avatar: user.avatar || { url: '', public_id: '' }
            }
        });

        await doc.save();

        res.status(201).json({
            success: true,
            message: 'Phản ánh đã được gửi thành công!',
            data: toFeedbackResponse(doc)
        });
    } catch (error) {
        next(error);
    }
};

// PUT /reports/app-feedback/:feedbackId  (authenticated)
export const updateAppFeedback = async (req, res, next) => {
    try {
        const { feedbackId } = req.params;
        const { rating, title, text } = req.body;

        const doc = await AppReviewDB.findOne({ _id: feedbackId, userId: req.user.id });
        if (!doc) {
            return next(respond.httpError('Không tìm thấy phản ánh', 404));
        }

        if (rating && (rating < 1 || rating > 5)) {
            return next(respond.httpError('Rating phải từ 1 đến 5', 400));
        }

        if (rating) doc.rating = Math.round(rating);
        if (title)  doc.title  = title.trim();
        if (text)   doc.text   = text.trim();

        await doc.save();

        res.status(200).json({
            success: true,
            message: 'Phản ánh đã được cập nhật!',
            data: toFeedbackResponse(doc)
        });
    } catch (error) {
        next(error);
    }
};

// DELETE /reports/app-feedback/:feedbackId  (authenticated)
export const deleteAppFeedback = async (req, res, next) => {
    try {
        const { feedbackId } = req.params;

        const doc = await AppReviewDB.findOne({ _id: feedbackId, userId: req.user.id });
        if (!doc) {
            return next(respond.httpError('Không tìm thấy phản ánh', 404));
        }

        await doc.deleteOne();

        res.status(200).json({
            success: true,
            message: 'Phản ánh đã được xoá!',
            deletedId: doc._id
        });
    } catch (error) {
        next(error);
    }
};