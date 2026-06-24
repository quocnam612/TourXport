# TourXport - Bách Khoa Toàn Thư (Wiki Hướng Dẫn Sử Dụng)

Tài liệu này cung cấp hướng dẫn chi tiết từng bước, từng nút bấm, và từng màn hình của ứng dụng TourXport. Trợ lý ảo AI phải bám sát tuyệt đối 100% vào tài liệu này để hướng dẫn người dùng, không được tự ý sáng tạo ra tính năng ngoài.

---

## 1. Màn Hình Đăng Nhập & Đăng Ký (Authentication)
*Nơi bắt đầu hành trình của người dùng. Việc đăng nhập là bắt buộc để ứng dụng lưu trữ và cá nhân hóa lịch trình.*

### 1.1. Đăng nhập (`sign_in.dart`)
- **Vị trí/Nút bấm:** Tại màn hình mở đầu (Landing Page), nhấn nút **"Đăng nhập"**.
- **Cách thức:**
  - Hỗ trợ đăng nhập qua 2 phương thức chính: **Email** hoặc **Số điện thoại**.
  - Nhập thông tin vào các ô tương ứng và nhập **Mật khẩu**.
  - Nếu quên mật khẩu, người dùng có thể nhấn nút **"Quên mật khẩu?"** để khôi phục.
- **Lưu ý:** Sau khi đăng nhập thành công, người dùng sẽ được chuyển thẳng vào **Màn hình chính (Dashboard)**.

### 1.2. Đăng ký tài khoản (`sign_up.dart`)
- **Vị trí/Nút bấm:** Từ màn hình Đăng nhập, kéo xuống dưới và chọn **"Chưa có tài khoản? Đăng ký ngay"**.
- **Cách thức:**
  - Cung cấp các thông tin: **Tên đầy đủ, Email, Số điện thoại, Mật khẩu**.
  - Người dùng bắt buộc phải đánh dấu tích vào ô **"Tôi đồng ý với Điều khoản và Chính sách bảo mật"**.
  - Nhấn nút **"Đăng ký"** để hoàn tất.

---

## 2. Màn Hình Chính & Thanh Điều Hướng (Dashboard)
*Trung tâm điều khiển của ứng dụng. Ở dưới cùng màn hình luôn có thanh điều hướng (Bottom Navigation Bar) chứa các Tab chính.*

### Các Tab ở thanh điều hướng dưới cùng:
1. **Trang Chủ (Home):** Hiển thị các địa điểm nổi bật, khách sạn, nhà hàng gợi ý, và thanh tìm kiếm.
2. **Bản Đồ (Map):** Khám phá địa điểm trực quan qua Google Maps.
3. **Tạo Lịch Trình (Trip / Survey):** Tính năng lõi giúp tạo tour tự động bằng AI (biểu tượng hình tia chớp hoặc cây đũa phép).
4. **Bộ Sưu Tập (Saved):** Nơi lưu giữ các địa điểm và các Tour đã lưu.
5. **Cá Nhân (Profile):** Cài đặt tài khoản, bảo mật, và hỗ trợ.

---

## 3. Tạo Lịch Trình Thông Minh (Tính Năng Cốt Lõi)
*Sử dụng AI để tự động tạo ra một chuyến đi hoàn chỉnh dựa trên sở thích người dùng.*

### 3.1. Làm Khảo Sát (`survey_screen.dart`)
- **Bước 1:** Từ thanh điều hướng dưới cùng, chọn Tab **Tạo Lịch Trình**.
- **Bước 2 (Điền thông tin):** Ứng dụng sẽ hiển thị một bài khảo sát (Survey) với các câu hỏi:
  - Chọn địa điểm muốn đến (Ví dụ: Đà Lạt, Phú Quốc...).
  - Số lượng người tham gia (Người lớn, Trẻ em). Mức tối đa thường là 5 người.
  - Tổng số ngày đi (Ví dụ: 3 ngày 2 đêm).
  - Ngân sách (Budget): Chọn mức chi tiêu dự kiến (Tiết kiệm, Trung bình, Cao cấp).
  - Sở thích: Chọn các thẻ tag như Nghỉ dưỡng, Ẩm thực, Văn hóa, Phiêu lưu...
- **Bước 3:** Nhấn nút **"Hoàn tất"** hoặc **"Tạo lịch trình"**.

### 3.2. Xem Kết Quả Lịch Trình (`survey_result_screen.dart`)
- Sau vài giây xử lý, AI sẽ trả về **Kết quả lịch trình**.
- Màn hình này hiển thị:
  - Thông tin phân bổ theo từng ngày (Day 1, Day 2...).
  - Buổi sáng đi đâu, trưa ăn gì, tối ngủ khách sạn nào.
- **Các nút chức năng quan trọng trên màn hình này:**
  - Nút **"Bản đồ"**: Chuyển sang màn hình `tour_route_map_screen.dart` để xem lộ trình di chuyển các điểm trên bản đồ.
  - Nút **"Lưu lại" (Save):** Cực kỳ quan trọng. Nhấn nút này để lưu trữ lịch trình này vào tài khoản, nếu không sẽ bị mất khi thoát ra.

---

## 4. Khám Phá & Bộ Sưu Tập

### 4.1. Tìm kiếm và Xem Chi Tiết
- **Tìm kiếm:** Tại Trang chủ, có một thanh tìm kiếm (Search Bar) ở trên cùng. Người dùng có thể gõ tên địa danh, khách sạn hoặc nhà hàng.
- **Chi tiết địa điểm (`place_detail.dart`):** Khi bấm vào một địa điểm bất kỳ, người dùng có thể xem hình ảnh, mô tả, nút xem thời tiết (nếu có), và nút **Đánh giá (Review)**.
- **Chi tiết Tỉnh/Thành (`province_detail_screen.dart`):** Hiển thị tổng quan văn hóa, đặc sản và các địa điểm nổi tiếng thuộc tỉnh đó.

### 4.2. Bộ Sưu Tập (`saved_place.dart`, `saved_tour_detail.dart`)
- Chuyển sang Tab **Bộ Sưu Tập** ở thanh điều hướng.
- Tại đây chia làm 2 mục chính:
  - **Địa điểm đã lưu:** Các khách sạn, nhà hàng, danh lam thắng cảnh mà người dùng đã thả tim (Save).
  - **Tour đã lưu:** Các lịch trình người dùng đã tạo từ AI và bấm "Lưu lại". Khi bấm vào sẽ xem lại chi tiết lộ trình.

---

## 5. Tương Tác Cộng Đồng & Kỷ Niệm

### 5.1. Viết Đánh Giá (Review)
- Người dùng có thể viết đánh giá cho các địa điểm (`create_review_screen.dart`).
- Hệ thống cho phép chấm điểm số sao (1 đến 5 sao) và để lại bình luận văn bản. Các đánh giá này hiển thị tại `app_reviews_screen.dart`.

### 5.2. Nhật Ký Du Lịch (`travel_memory_screen.dart`)
- Một tính năng đặc biệt giúp người dùng lưu trữ lại kỷ niệm.
- Cung cấp không gian để viết lại cảm nghĩ và up ảnh sau chuyến đi.

---

## 6. Cài Đặt Cá Nhân & Hỗ Trợ (Profile & Settings)
*Chuyển sang Tab Cá Nhân (Profile) ở góc phải dưới cùng màn hình.*

### 6.1. Cài Đặt Chung
- **Chỉnh sửa hồ sơ (`edit_profile_screen.dart`):** Thay đổi ảnh đại diện, tên, số điện thoại.
- **Ngôn ngữ (`language_settings_screen.dart`):** Hỗ trợ đổi ngôn ngữ giao diện (Tiếng Việt / English).
- **Thông báo (`notification_settings_screen.dart`):** Bật/tắt các loại thông báo (thông báo tin nhắn, khuyến mãi...).

### 6.2. Bảo Mật (`security_settings_screen.dart`, `pin_lock_screen.dart`)
- Người dùng có thể thiết lập **Mã PIN** để khóa ứng dụng, tăng cường tính riêng tư cho các lịch trình cá nhân.

### 6.3. Trợ Giúp & Hỗ Trợ (`help_support_screen.dart`)
- **FAQ:** Các câu hỏi thường gặp.
- **Trò chuyện với AI (Guide Chat):** Tại màn hình Trợ giúp này, có một nút bấm **"Bắt đầu trò chuyện"** (hoặc "Start chat" kèm icon hình bong bóng chat). Nhấn vào đây, người dùng sẽ được kết nối trực tiếp với Trợ lý ảo AI (chính là bạn) để được giải đáp mọi thắc mắc.

---
*(End of Wiki)*
