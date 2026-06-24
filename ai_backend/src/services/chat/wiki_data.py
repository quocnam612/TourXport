WIKI_KNOWLEDGE_BASE = {
    "auth": """
## 1. Màn Hình Đăng Nhập & Đăng Ký (Authentication)
*Nơi bắt đầu hành trình của người dùng. Việc đăng nhập là bắt buộc để ứng dụng lưu trữ và cá nhân hóa lịch trình.*

### 1.1. Đăng nhập (`sign_in.dart`)
- **Vị trí/Nút bấm:** Tại màn hình mở đầu (Landing Page), nhấn nút **"Đăng nhập"**.
- **Cách thức:** Hỗ trợ đăng nhập qua 2 phương thức chính: **Email** hoặc **Số điện thoại**. Nhập thông tin vào các ô tương ứng và nhập **Mật khẩu**. Nếu quên mật khẩu, người dùng có thể nhấn nút **"Quên mật khẩu?"** để khôi phục.
- **Lưu ý:** Sau khi đăng nhập thành công, người dùng sẽ được chuyển thẳng vào **Màn hình chính (Dashboard)**.

### 1.2. Đăng ký tài khoản (`sign_up.dart`)
- **Vị trí/Nút bấm:** Từ màn hình Đăng nhập, kéo xuống dưới và chọn **"Chưa có tài khoản? Đăng ký ngay"**.
- **Cách thức:** Cung cấp các thông tin: **Tên đầy đủ, Email, Số điện thoại, Mật khẩu**. Người dùng bắt buộc phải đánh dấu tích vào ô **"Tôi đồng ý với Điều khoản và Chính sách bảo mật"**. Nhấn nút **"Đăng ký"** để hoàn tất.
""",
    "dashboard": """
## 2. Màn Hình Chính & Thanh Điều Hướng (Dashboard)
*Trung tâm điều khiển của ứng dụng. Ở dưới cùng màn hình luôn có thanh điều hướng (Bottom Navigation Bar) chứa các Tab chính.*

### Các Tab ở thanh điều hướng dưới cùng:
1. **Trang Chủ (Home):** Hiển thị các địa điểm nổi bật, khách sạn, nhà hàng gợi ý, và thanh tìm kiếm.
2. **Bản Đồ (Map):** Khám phá địa điểm trực quan qua Google Maps.
3. **Tạo Lịch Trình (Trip / Survey):** Tính năng lõi giúp tạo tour tự động bằng AI (biểu tượng hình tia chớp hoặc cây đũa phép).
4. **Bộ Sưu Tập (Saved):** Nơi lưu giữ các địa điểm và các Tour đã lưu.
5. **Cá Nhân (Profile):** Cài đặt tài khoản, bảo mật, và hỗ trợ.
""",
    "tour_generation": """
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
- Sau vài giây xử lý, AI sẽ trả về **Kết quả lịch trình**. Màn hình này hiển thị thông tin phân bổ theo từng ngày (Day 1, Day 2...), buổi sáng đi đâu, trưa ăn gì, tối ngủ khách sạn nào.
- **Các nút chức năng quan trọng trên màn hình này:**
  - Nút **"Bản đồ"**: Chuyển sang màn hình `tour_route_map_screen.dart` để xem lộ trình di chuyển các điểm trên bản đồ.
  - Nút **"Lưu lại" (Save):** Cực kỳ quan trọng. Nhấn nút này để lưu trữ lịch trình này vào tài khoản, nếu không sẽ bị mất khi thoát ra.
""",
    "explore": """
## 4. Khám Phá & Bộ Sưu Tập

### 4.1. Tìm kiếm và Xem Chi Tiết
- **Tìm kiếm:** Tại Trang chủ, có một thanh tìm kiếm (Search Bar) ở trên cùng. Người dùng có thể gõ tên địa danh, khách sạn hoặc nhà hàng.
- **Chi tiết địa điểm (`place_detail.dart`):** Khi bấm vào một địa điểm bất kỳ, người dùng có thể xem hình ảnh, mô tả, nút xem thời tiết (nếu có), và nút **Đánh giá (Review)**.
- **Chi tiết Tỉnh/Thành (`province_detail_screen.dart`):** Hiển thị tổng quan văn hóa, đặc sản và các địa điểm nổi tiếng thuộc tỉnh đó.

### 4.2. Bộ Sưu Tập (`saved_place.dart`, `saved_tour_detail.dart`)
- Chuyển sang Tab **Bộ Sưu Tập** ở thanh điều hướng. Tại đây chia làm 2 mục chính:
  - **Địa điểm đã lưu:** Các khách sạn, nhà hàng, danh lam thắng cảnh mà người dùng đã thả tim (Save).
  - **Tour đã lưu:** Các lịch trình người dùng đã tạo từ AI và bấm "Lưu lại". Khi bấm vào sẽ xem lại chi tiết lộ trình.
""",
    "community": """
## 5. Tương Tác Cộng Đồng & Kỷ Niệm

### 5.1. Viết Đánh Giá (Review)
- Người dùng có thể viết đánh giá cho các địa điểm (`create_review_screen.dart`).
- Hệ thống cho phép chấm điểm số sao (1 đến 5 sao) và để lại bình luận văn bản. Các đánh giá này hiển thị tại `app_reviews_screen.dart`.

### 5.2. Nhật Ký Du Lịch (`travel_memory_screen.dart`)
- Một tính năng đặc biệt giúp người dùng lưu trữ lại kỷ niệm. Cung cấp không gian để viết lại cảm nghĩ và up ảnh sau chuyến đi.
""",
    "profile_settings": """
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
- **Trò chuyện với AI (Guide Chat):** Tại màn hình Trợ giúp này, có một nút bấm **"Bắt đầu trò chuyện"** (hoặc "Start chat" kèm icon hình bong bóng chat). Nhấn vào đây, người dùng sẽ được kết nối trực tiếp với Trợ lý ảo AI để được giải đáp mọi thắc mắc.
"""
}

TOPIC_DESCRIPTIONS = {
    "auth": "Liên quan đến việc đăng nhập, đăng ký tài khoản, quên mật khẩu, email, số điện thoại, điều khoản.",
    "dashboard": "Liên quan đến thanh điều hướng (các tab dưới cùng), màn hình chính, giao diện tổng quan, trang chủ, bản đồ, map.",
    "tour_generation": "Liên quan đến tính năng cốt lõi: Làm khảo sát (survey) tạo lịch trình tour bằng AI, số người, ngân sách, sở thích, xem và lưu lộ trình, bản đồ tour, chi phí.",
    "explore": "Liên quan đến việc tìm kiếm địa điểm, xem chi tiết nhà hàng/khách sạn/tỉnh thành, xem bộ sưu tập đã lưu, thời tiết (weather), thả tim, văn hóa, đặc sản.",
    "community": "Liên quan đến viết đánh giá (review), chấm sao địa điểm, viết nhật ký kỷ niệm (Travel Memory), chia sẻ.",
    "profile_settings": "Liên quan đến đổi ngôn ngữ, cài đặt thông báo, mã PIN bảo mật, chỉnh sửa hồ sơ, trợ giúp AI (chatbot), FAQ, câu hỏi thường gặp, đăng xuất, xóa tài khoản, trợ lý ảo."
}
