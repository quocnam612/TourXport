import express from 'express';

import { authenticate } from '../middlewares/authMiddleware.js';

import * as reportController from '../controllers/reportController.js';

const router = express.Router();

router.route('/my-reports')
    .get(authenticate, reportController.getMyReports)
    .post(authenticate, reportController.createReport);

router.route('/my-reports/:reportId')
    .put(authenticate, reportController.updateReport)
    .delete(authenticate, reportController.deleteReport);

router.get('/:targetType/:targetId', reportController.getReportsByTarget);

export default router;