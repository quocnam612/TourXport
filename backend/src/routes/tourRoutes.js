import express from 'express';

import { authenticate } from '../middlewares/authMiddleware.js';

const router = express.Router();

const notImplemented = (req, res) => {
    res.status(501).json({
        success: false,
        message: 'Tour endpoint is not implemented yet'
    });
};

router.route('/')
    .get(notImplemented) // Lấy danh sách tour public / lọc tour bằng query params
    .post(authenticate, notImplemented); // Tạo tour mới cho user hiện tại

router.route('/my-tours')
    .get(authenticate, notImplemented); // Lấy danh sách tour của user hiện tại

router.route('/search')
    .get(notImplemented); // Tìm / xem chi tiết tour theo query param id, title, destination

router.route('/:id')
    .get(notImplemented) // Xem chi tiết một tour theo id
    .put(authenticate, notImplemented) // Cập nhật tour của user hiện tại
    .delete(authenticate, notImplemented); // Xóa tour của user hiện tại

router.route('/:id/visibility')
    .put(authenticate, notImplemented); // Đổi trạng thái private / public

router.route('/:id/days')
    .post(authenticate, notImplemented); // Thêm một ngày vào lịch trình tour

router.route('/:id/days/:dayNumber')
    .put(authenticate, notImplemented) // Cập nhật một ngày trong lịch trình
    .delete(authenticate, notImplemented); // Xóa một ngày khỏi lịch trình

router.route('/:id/days/:dayNumber/items')
    .post(authenticate, notImplemented); // Thêm địa điểm / nhà hàng / khách sạn vào một ngày

router.route('/:id/days/:dayNumber/items/:order')
    .put(authenticate, notImplemented) // Cập nhật một item trong lịch trình
    .delete(authenticate, notImplemented); // Xóa một item khỏi lịch trình

export default router;
