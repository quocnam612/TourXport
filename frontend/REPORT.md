# Báo cáo Thành phần Front-end - TourXport

## 1. Vai trò và Nhiệm vụ của Front-end
Trong đồ án TourXport, thành phần Front-end đóng vai trò là giao diện tương tác trực tiếp giữa người dùng và hệ thống. Nhiệm vụ chính bao gồm:

*   **Xây dựng Trải nghiệm Người dùng (UX):** Thiết kế luồng đi từ lúc người dùng đăng ký/đăng nhập cho đến khi nhận được lịch trình du lịch cá nhân hóa.
*   **Phát triển Giao diện (UI):** Hiện thực hóa phong cách thiết kế "Premium Dark Glassmorphism", sử dụng các hiệu ứng làm mờ (blur) và độ trong suốt để tạo cảm giác hiện đại và sang trọng.
*   **Thu thập Dữ liệu Người dùng:** Triển khai các màn hình khảo sát (Survey) để thu thập thông tin về sở thích, ngân sách và mục tiêu chuyến đi của người dùng.
*   **Xử lý và Hiển thị Dữ liệu:** Gửi dữ liệu khảo sát lên Backend, nhận phản hồi từ AI và trình bày lại dưới dạng lịch trình du lịch trực quan và dễ hiểu.
*   **Quản lý Tài khoản:** Cung cấp các chức năng thay đổi thông tin cá nhân, cài đặt bảo mật và thông báo.

## 2. Tech Stack & Thư viện Sử dụng
Front-end của TourXport được xây dựng trên nền tảng công nghệ hiện đại nhằm đảm bảo hiệu năng và tính thẩm mỹ cao:

*   **Framework chính:** [Flutter](https://flutter.dev/) (phiên bản SDK >= 3.0.0) - Cho phép xây dựng ứng dụng đa nền tảng (Android, iOS, Web, Windows) từ một codebase duy nhất.
*   **Ngôn ngữ lập trình:** [Dart](https://dart.dev/) - Ngôn ngữ tối ưu cho việc xây dựng UI và các tác vụ bất đồng bộ.
*   **Thư viện và Công cụ:**
    *   **http:** Xử lý các yêu cầu mạng (RESTful API) tới Backend và AI Service.
    *   **google_fonts:** Tích hợp bộ font chữ Montserrat chuyên nghiệp.
    *   **image_picker:** Hỗ trợ người dùng chọn ảnh từ thư viện hoặc máy ảnh để cập nhật hồ sơ.
    *   **Material Design:** Sử dụng các thành phần UI chuẩn hóa nhưng đã được tùy chỉnh theo phong cách riêng của dự án.
*   **Hệ thống Thiết kế (Design System):**
    *   Màu sắc: Bảng màu tối (Dark Mode) kết hợp với các hiệu ứng Gradient xanh lá/vàng.
    *   Typography: Sử dụng họ font Montserrat với nhiều trọng số (Weight) khác nhau.
    *   Aesthetics: Áp dụng kỹ thuật Glassmorphism cho các thành phần Card và Overlay.

## 3. Quy trình Xử lý của Front-end
Quy trình hoạt động cốt lõi của ứng dụng được mô tả qua các bước sau:

1.  **Bước 1: Xác thực (Authentication):** Người dùng thực hiện đăng nhập hoặc đăng ký thông qua màn hình `sign_in.dart` và `sign_up.dart`.
2.  **Bước 2: Khảo sát (Surveying):** Người dùng nhập thông tin sở thích tại `survey_screen.dart`. Dữ liệu này được đóng gói thành đối tượng `SurveyAnswer`.
3.  **Bước 3: Tích hợp API (API Integration):** Front-end gọi API tới Backend (hoặc trực tiếp tới AI Backend) thông qua lớp dịch vụ trong thư mục `lib/api`.
4.  **Bước 4: Xử lý Kết quả (Result Processing):** Sau khi nhận được kết quả (JSON) từ AI, hệ thống sẽ phân tách dữ liệu và chuyển đổi thành các Model tương ứng trong `lib/models`.
5.  **Bước 5: Trình bày (Visualization):** Kết quả cuối cùng được hiển thị tại `survey_result_screen.dart`, nơi người dùng có thể xem chi tiết lịch trình và các địa điểm được đề xuất.
6.  **Bước 6: Tương tác Địa điểm (Interaction):** Người dùng có thể xem chi tiết từng địa điểm tại `place_detail.dart` và sử dụng tính năng điều hướng (Đường đi).

## 4. Nguồn Tham khảo
1.  *Flutter Documentation:* [https://docs.flutter.dev/](https://docs.flutter.dev/)
2.  *Material Design 3 Guidelines:* [https://m3.material.io/](https://m3.material.io/)
3.  *Dart Language Guide:* [https://dart.dev/guides](https://dart.dev/guides)
4.  *Glassmorphism Design Patterns:* [UX Collective - Glassmorphism in User Interfaces](https://uxdesign.cc/glassmorphism-in-user-interfaces-1f510ef39818)
5.  *Flutter packages:* [https://pub.dev/](https://pub.dev/)
