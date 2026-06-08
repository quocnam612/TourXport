import express from 'express';

import { authenticate } from '../middlewares/authMiddleware.js';

import * as reportController from '../controllers/reportController.js';

const router = express.Router();

// ── Phản ánh về ứng dụng (app feedback) ───────────────────────────────────
// Public: Lấy tất cả phản ánh ứng dụng (để hiển thị cộng đồng)
router.get('/app-feedback', reportController.getAllAppFeedback);

// Authenticated: Lấy phản ánh ứng dụng của tôi
router.get('/app-feedback/my', authenticate, reportController.getMyAppFeedback);

// Authenticated: Gửi phản ánh ứng dụng
router.post('/app-feedback', authenticate, reportController.createAppFeedback);

// Authenticated: Cập nhật / xoá phản ánh ứng dụng của tôi
router.put('/app-feedback/:feedbackId', authenticate, reportController.updateAppFeedback);
router.delete('/app-feedback/:feedbackId', authenticate, reportController.deleteAppFeedback);

// ── Báo cáo địa điểm / khách sạn / ... ────────────────────────────────────
router.route('/my-reports')
    .get(authenticate, reportController.getMyReports)
    .post(authenticate, reportController.createReport);

router.route('/my-reports/:reportId')
    .put(authenticate, reportController.updateReport)
    .delete(authenticate, reportController.deleteReport);

router.get('/:targetType/:targetId', reportController.getReportsByTarget);

export default router;