import express from 'express';

import { authenticate } from '../middlewares/authMiddleware.js';
import * as tourController from '../controllers/tourController.js';

const router = express.Router();

router.route('/')
    .get(tourController.getTours) // Lấy danh sách tour public / lọc tour bằng query params
    .post(authenticate, tourController.createTour); // Tạo tour mới cho user hiện tại

router.route('/my-tours')
    .get(authenticate, tourController.getMyTours); // Lấy danh sách tour của user hiện tại
router.route('/my-tours/:id')
    .get(authenticate, tourController.getMyTourDetail) // Xem chi tiết một tour của user hiện tại theo id
    .put(authenticate, tourController.updateMyTour) // Cập nhật tour của user hiện tại theo id
    .delete(authenticate, tourController.deleteMyTour); // Xóa tour của user hiện tại theo id

router.route('/manual')
    .post(authenticate, tourController.createManualTour); // Tạo tour thủ công cho user hiện tại

router.route('/:id')
    .get(tourController.getTourById); // Xem chi tiết một tour public theo id

export default router;
