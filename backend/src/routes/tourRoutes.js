import express from 'express';

import { authenticate } from '../middlewares/authMiddleware.js';
import * as tourController from '../controllers/tourController.js';

const router = express.Router();

router.route('/')
    .get(tourController.getTours) // Lấy danh sách tour public / lọc tour bằng query params
    .post(authenticate, tourController.createTour); // Tạo tour mới cho user hiện tại

router.route('/my-tours')
    .get(authenticate, tourController.getMyTours); // Lấy danh sách tour của user hiện tại

router.route('/:id')
    .get(tourController.getTourById) // Xem chi tiết một tour theo id
    .put(authenticate, tourController.updateTour) // Cập nhật tour của user hiện tại
    .delete(authenticate, tourController.deleteTour); // Xóa tour của user hiện tại

export default router;
