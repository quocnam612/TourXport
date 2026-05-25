import express from 'express';

import { authenticate } from '../middlewares/authMiddleware.js';
import * as hotelController from '../controllers/hotelController.js';

const router = express.Router();

router.route('/')
    .get(hotelController.getHotels) // Trả về danh sách các khách sạn, lọc bằng query params nếu có
    .post(authenticate, hotelController.createHotel); // Tạo mới một khách sạn
    
router.route('/search')
    .get(hotelController.getHotel) // Trả về chi tiết một khách sạn theo query param id hoặc sourceLocationId
    .put(authenticate, hotelController.updateHotel) // Cập nhật thông tin một khách sạn theo query param id hoặc sourceLocationId
    .delete(authenticate, hotelController.deleteHotel); // Xóa một khách sạn theo query param id hoặc sourceLocationId

export default router;
