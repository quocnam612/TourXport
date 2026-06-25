# Phân Tích Chức Năng và Luồng Thực Thi TourXport

Dựa vào việc quét mã nguồn dự án, tôi xin tóm tắt lại các chức năng chính của app và trả lời các thắc mắc của bạn:

## 1. Module Chat Guide đang được sử dụng ở đâu?
Hiện tại, theo mã nguồn Frontend, chức năng chat với AI đang được đặt duy nhất tại:
- **File:** `frontend/lib/screens/help_support_screen.dart`
- **Vị trí:** Nút bấm "Bắt đầu trò chuyện" (hoặc "Start chat") bên trong màn hình Trợ Giúp & Hỗ Trợ.

=> **Kết luận về nhận biết ngữ cảnh:** Vì chức năng chat không phải là một bong bóng chat (Floating Button) xuyên suốt toàn app, mà chỉ nằm ở màn hình Help & Support, nên việc truyền `current_screen` là **không cần thiết**. Người dùng chỉ vào đây khi họ có thắc mắc chung.

## 2. Giải pháp thay thế RAG và Function Calling
Như bạn đã chia sẻ:
- Không muốn đụng vào code Frontend/Backend (không có quyền).
- Không muốn triển khai thêm RAG nếu nó quá nhỏ và tốn kém.

=> **Giải pháp tối ưu nhất:** 
Chúng ta sẽ **không** dùng Function Calling và **không** dùng RAG. Thay vào đó, chúng ta sẽ áp dụng kỹ thuật **Prompt Injection trực tiếp**. 
Bởi vì số lượng tính năng của app TourXport không quá đồ sộ, ta hoàn toàn có thể gom toàn bộ "Tài liệu hướng dẫn sử dụng" (khoảng 1-2 trang A4) nhét thẳng vào `System Prompt` của model `gpt-4o-mini`. Model này hỗ trợ đến 128k token context, nên việc nhét 1 file text nhỏ vào system prompt là **hoàn toàn miễn phí, siêu nhanh và cực kỳ hiệu quả** mà không cần tới Vector Database.

## 3. Tổng hợp danh sách chức năng chính của App (Feature List)

Thông qua quét `backend/src/routes` và `frontend/lib/screens`, ứng dụng TourXport có các luồng nghiệp vụ (User Flow) chính sau:

### A. Xác thực & Hồ sơ (Auth & Profile)
- Đăng ký, Đăng nhập (`sign_in.dart`, `sign_up.dart`).
- Cài đặt tài khoản: Chỉnh sửa thông tin cá nhân, cài đặt bảo mật (mã PIN), ngôn ngữ, thông báo (`security_settings_screen.dart`, `language_settings_screen.dart`...).

### B. Khám Phá Địa Điểm (Khách sạn, Nhà hàng, Tỉnh thành)
- Xem danh sách tỉnh thành và chi tiết (`province_detail_screen.dart`).
- Xem chi tiết địa điểm, khách sạn, nhà hàng (`place_detail.dart`).
- Bản đồ tương tác (`map_screen.dart`).
- Xem thời tiết tại các địa điểm (`weatherRoutes.js`).

### C. Quản Lý & Lên Lịch Trình (Tours)
- Tạo và làm khảo sát để sinh lịch trình (`survey_screen.dart`, `survey_result_screen.dart`).
- Xem chi tiết tour và lộ trình trên bản đồ (`tour_route_map_screen.dart`).
- Lưu trữ tour và địa điểm yêu thích (`saved_place.dart`, `saved_tour_detail.dart`).

### D. Tương tác cộng đồng
- Đánh giá (Review) các địa điểm, tour (`create_review_screen.dart`, `app_reviews_screen.dart`).
- Nhật ký du lịch / Kỷ niệm (`travel_memory_screen.dart`).

---
**Đề xuất tiếp theo:**
Mình sẽ lấy danh sách chức năng ở mục 3, viết thành một đoạn "Hướng dẫn sử dụng" dạng text ngắn gọn, và dán trực tiếp vào file `manager.py` (biến `_system_prompt`). Như vậy con AI của bạn sẽ bỗng nhiên "hiểu biết mọi thứ về app" mà không tốn kém thêm 1 đồng nào cho hạ tầng RAG! Bạn có đồng ý với hướng đi này không?
