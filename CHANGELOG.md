<!-- markdownlint-disable MD024 -->
# Changelog

## [1.0.2] - 2026-06-06

### Added

- **Frontend (Bảo mật)**: Thêm tính năng "Khóa ứng dụng" (App Lock) cho phép người dùng thiết lập mã PIN 4 số trong phần Cài đặt bảo mật để tăng cường quyền riêng tư.
- **Frontend (Đăng nhập)**: Bổ sung tính năng "Ghi nhớ đăng nhập của tôi" và hỗ trợ thả xuống danh sách các tài khoản đã lưu, giúp người dùng đăng nhập nhanh hơn trong những lần tiếp theo mà không cần gõ lại.
- **Frontend (Trải nghiệm người dùng)**: Thêm hiệu ứng rung lắc (shake animation) trực quan khi người dùng nhập thiếu hoặc sai thông tin đăng nhập, đồng thời tự động nhận diện và phản hồi trạng thái phím Caps Lock.

### Changed

- **Frontend (Kiến trúc Đăng nhập)**: Tái cấu trúc mạnh mẽ mã nguồn màn hình Đăng nhập (Sign In). Tách các thành phần giao diện thành các module nhỏ, độc lập (`AuthTextField`, `AuthContinueButton`, `SocialLoginButton`, `SavedAccountsDropdown`) giúp hệ thống dễ bảo trì và mở rộng.
- **Frontend (Điều hướng)**: Thay đổi luồng chuyển hướng phiên làm việc bằng cách tích hợp `AppLockWrapper` ở tầng cao nhất của ứng dụng (`main.dart`), thay thế cho logic chuyển trang tự động cũ ở màn hình Landing Page để tương thích với tính năng khóa mã PIN.

## [1.0.1] - 2026-06-04

### Added

- **Crawler**: Thêm tính năng trích xuất hình ảnh chất lượng cao (`high_quality_photos`). Tính năng này tự động ưu tiên các hình ảnh đạt chuẩn (blessed) và lọc bỏ các ảnh không có đánh giá, giúp nâng cao chất lượng dữ liệu hình ảnh địa điểm cung cấp cho người dùng.
- **Frontend (Bản đồ)**: Bổ sung các phím tắt điều hướng nhanh trên màn hình bản đồ lộ trình (Tour Route Map), cho phép người dùng dễ dàng thu phóng camera về vị trí hiện tại hoặc điểm đến tiếp theo chỉ với một thao tác chạm.
- **Frontend (Hiệu năng)**: Tích hợp thư viện `flutter_map_cancellable_tile_provider` để quản lý các phiên tải bản đồ. Ứng dụng giờ đây có thể tự động hủy các yêu cầu tải hình ảnh bản đồ cũ khi người dùng trượt/kéo nhanh, giúp tránh tình trạng nghẽn mạng và giật lag.
- **Frontend (Tiện ích)**: Thêm các hàm tiện ích (`formatDuration`, `formatCurrency`, `formatDistance`) để chuẩn hóa định dạng hiển thị thời gian, khoảng cách, và chi phí trên toàn bộ ứng dụng, mang lại trải nghiệm xem thông tin đồng nhất.
- **Frontend (Dependencies)**: Tích hợp thêm các plugin mới bao gồm `intl` (định dạng tiền tệ), `shimmer` (hiệu ứng loading) và `url_launcher` (mở liên kết ngoài) phục vụ cho các cải tiến giao diện.

### Changed

- **Frontend (Định vị & Dẫn đường)**: Cải tiến thuật toán giám sát lộ trình di chuyển (thay thế cơ chế Debounce bằng Throttling). Việc này giúp hệ thống cập nhật vị trí và phát hiện người dùng đi lệch hướng chính xác và tức thời hơn, ngay cả khi người dùng đang di chuyển liên tục.
- **Frontend (Hiệu năng API)**: Áp dụng cơ chế lưu trữ đệm (Caching) cho các đoạn đường đã được tính toán trên màn hình Tour Route Map. Điều này giúp giảm thiểu đáng kể số lượng lệnh gọi API OSRM, tiết kiệm dữ liệu mạng và tăng tốc độ hiển thị đường đi khi người dùng chuyển đổi qua lại giữa các ngày trong lịch trình.
- **Frontend (Kiến trúc)**: Tái cấu trúc toàn diện mã nguồn màn hình bản đồ theo nguyên lý SOLID. Phân tách logic xử lý tọa độ địa lý (`GeocodingService`), cấp quyền vị trí (`MapLocationService`), và chia nhỏ giao diện thành các module chuyên biệt (Loading, Error, Timeline, Danh sách). Hệ thống mã nguồn trở nên gọn gàng, dễ bảo trì và mở rộng hơn cho các lập trình viên.

### Fixed

- **Frontend (Giao diện Bản đồ)**: Khắc phục lỗi thuật toán tính toán khung hiển thị bản đồ (Fit Bounds). Đảm bảo toàn bộ tuyến đường và tất cả các điểm dừng chân luôn được thu phóng vừa vặn và hiển thị đầy đủ trên màn hình, không còn tình trạng bị khuất khỏi góc nhìn.

## [1.0.0] - 2026-05-24

### Added

- **Guest Mode Support**: Added initial support for unregistered (guest) users, allowing them to browse the application without immediately signing in.
- **Personalized Header in Landing Page**: Displays a greeting (`XIN CHÀO, <USER>!`) and a quick-access `"VÀO TRANG CHỦ"` (Go to Home) button for authenticated users in the desktop header.
- **Login Call-to-Action Card**: Created a sleek, glassmorphic CTA card on the Profile tab prompting guest users to log in or sign up to save places and access personalized AI planning.

### Changed

- **Navigation Flow Redirection**: Reordered the app entry sequence to follow `HomeScreen (Guest)` -> `Login / Signup` -> `Landing Page (Registered)` -> `HomeScreen (Registered)`.
- **Successful Authentication Callback**: Pushes users to the updated `LandingPage` instead of directly launching the homepage dashboard after logging in or signing up.
- **Sidebar Integration**: Replaced the red `"Đăng xuất"` (Log Out) drawer item with a gold-highlighted `"Tài khoản"` button for guest mode.
- **Profile Tab Customizations**:
  - Hides personal/authenticated sections ("Thông tin cá nhân", "Email", "Số điện thoại", "Thông báo", "Bảo mật") for guest users to prevent cluttered disabled actions.
  - Replaces the red `"Đăng xuất"` menu option at the bottom with a gold `"Đăng nhập / Đăng ký"` redirect button.
  - Hides visual avatar edit badges for guests.
- **Saved Tab Customizations**: Updated the description and layout of the saved tab to show a localized sign-in prompt for guest users.

### Removed

- **Unused Buttons**: Removed the default `"ĐĂNG NHẬP"` and `"ĐĂNG KÝ"` buttons from the web/desktop navbar for users who are already authenticated.

### Fixed

- **Saved Tab Compilation Issue**: Fixed a Flutter compilation error in `saved_place.dart` where `widget.authToken` was queried inside a `StatelessWidget` (which has no `widget` property). Resolved by passing down an explicit `isGuest` property from `dashboard.dart`.
