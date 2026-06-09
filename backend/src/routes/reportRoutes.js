import express from 'express';

import { authenticate } from '../middlewares/authMiddleware.js';
import { uploadReportImages } from '../middlewares/uploadMiddleware.js';
import * as reportController from '../controllers/reportController.js';

const router = express.Router();

router.get('/', reportController.getReports);
router.get('/upvote', authenticate, reportController.upvoteReport);

router.route('/my-reports')
    .get(authenticate, reportController.getMyReports)
    .post(authenticate, uploadReportImages.array('images', 5), reportController.createReport);

router.route('/my-reports/:reportId')
    .put(authenticate, uploadReportImages.array('images', 5), reportController.updateReport)
    .delete(authenticate, reportController.deleteReport);

export default router;
