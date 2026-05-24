import express from 'express';

import { authenticate } from '../middlewares/authMiddleware.js';
import * as locationController from '../controllers/locationController.js';

const router = express.Router();

router.route('/')
    .get(locationController.getLocations) // Trả về danh sách các địa điểm, lọc bằng query params nếu có
    .post(authenticate, locationController.createLocation); // Tạo mới một địa điểm
    
router.route('/search')
    .get(locationController.getLocation) // Trả về chi tiết một địa điểm theo query param id hoặc sourceLocationId
    .put(authenticate, locationController.updateLocation) // Cập nhật thông tin một địa điểm theo query param id hoặc sourceLocationId
    .delete(authenticate, locationController.deleteLocation); // Xóa một địa điểm theo query param id hoặc sourceLocationId

export default router;
