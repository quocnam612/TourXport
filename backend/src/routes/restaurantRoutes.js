import express from 'express';

import { authenticate } from '../middlewares/authMiddleware.js';
import * as restaurantController from '../controllers/restaurantController.js';

const router = express.Router();

router.route('/')
    .get(restaurantController.getRestaurants) // Trả về danh sách các nhà hàng, lọc bằng query params nếu có
    .post(authenticate, restaurantController.createRestaurant); // Tạo mới một nhà hàng
    
router.route('/search')
    .get(restaurantController.getRestaurant) // Trả về chi tiết một nhà hàng theo query param id hoặc sourceLocationId
    .put(authenticate, restaurantController.updateRestaurant) // Cập nhật thông tin một nhà hàng theo query param id hoặc sourceLocationId
    .delete(authenticate, restaurantController.deleteRestaurant); // Xóa một nhà hàng theo query param id hoặc sourceLocationId

export default router;
