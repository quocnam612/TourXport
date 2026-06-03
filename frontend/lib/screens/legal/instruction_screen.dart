import 'package:flutter/material.dart';

import 'legal_scaffold.dart';

class InstructionScreen extends StatelessWidget {
  const InstructionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isVi = Localizations.localeOf(context).languageCode == 'vi';

    return LegalScaffold(
      title: isVi ? 'Hướng Dẫn Sử Dụng' : 'User Guide',
      subtitle: isVi
          ? 'Các bước cơ bản để sử dụng TourXport: khám phá địa điểm, lưu nội dung yêu thích, tạo lịch trình và quản lý tài khoản.'
          : 'Basic steps for using TourXport: discover places, save favorites, create itineraries, and manage your account.',
      activeRoute: '/intruction',
      children: [
        LegalNotice(
          icon: Icons.menu_book_rounded,
          title: isVi ? 'Hướng dẫn TourXport' : 'TourXport user guide',
          body: isVi
              ? 'Trang này tóm tắt các thao tác chính để người dùng bắt đầu nhanh với TourXport.'
              : 'This page summarizes the main actions users need to get started quickly with TourXport.',
        ),
        LegalSection(
          title: isVi ? '1. Khám phá địa điểm' : '1. Discover places',
          bullets: isVi
              ? [
                  'Mở tab Khám phá để xem các địa điểm, nhà hàng và chỗ ở được gợi ý.',
                  'Dùng tab Tìm kiếm để lọc địa điểm theo tên, tỉnh thành hoặc loại địa điểm.',
                  'Chọn một địa điểm để xem hình ảnh, mô tả, vị trí và các thông tin liên quan.',
                ]
              : [
                  'Open the Explore tab to view suggested places, restaurants, and stays.',
                  'Use the Search tab to filter by name, province, or place type.',
                  'Select a place to view photos, description, location, and related information.',
                ],
        ),
        LegalSection(
          title: isVi ? '2. Lưu địa điểm yêu thích' : '2. Save favorites',
          bullets: isVi
              ? [
                  'Đăng nhập tài khoản trước khi lưu địa điểm.',
                  'Nhấn biểu tượng lưu trên thẻ địa điểm hoặc trang chi tiết.',
                  'Mở tab Đã lưu để xem lại địa điểm, nhà hàng, chỗ ở và tour đã lưu.',
                ]
              : [
                  'Sign in before saving places.',
                  'Tap the save icon on a place card or detail page.',
                  'Open the Saved tab to review saved places, restaurants, stays, and tours.',
                ],
        ),
        LegalSection(
          title: isVi ? '3. Tạo tour bằng khảo sát' : '3. Create a tour from the survey',
          bullets: isVi
              ? [
                  'Mở tab Khảo sát và nhập điểm đến, số ngày, số người, ngân sách và phong cách chuyến đi.',
                  'Kiểm tra lại các lựa chọn trước khi gửi yêu cầu tạo tour.',
                  'Sau khi tạo xong, bạn có thể xem chi tiết lịch trình và lưu tour vào tài khoản.',
                ]
              : [
                  'Open the Survey tab and enter destination, number of days, travelers, budget, and trip style.',
                  'Review your selections before submitting the tour generation request.',
                  'After the tour is created, you can view the detailed itinerary and save it to your account.',
                ],
        ),
        LegalSection(
          title: isVi ? '4. Quản lý tài khoản' : '4. Manage your account',
          bullets: isVi
              ? [
                  'Mở tab Tài khoản để xem hồ sơ, email và số điện thoại.',
                  'Cập nhật số điện thoại trong mục Số điện thoại.',
                  'Mở mục Bảo mật để đổi mật khẩu hoặc xem các phương thức đăng nhập đã liên kết.',
                ]
              : [
                  'Open the Account tab to view your profile, email, and phone number.',
                  'Update your phone number in the Phone Number section.',
                  'Open Security to change your password or view linked login methods.',
                ],
        ),
      ],
    );
  }
}
