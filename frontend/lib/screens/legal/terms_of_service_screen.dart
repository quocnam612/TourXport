import 'package:flutter/material.dart';

import 'legal_scaffold.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isVi = Localizations.localeOf(context).languageCode == 'vi';

    return LegalScaffold(
      title: isVi ? 'Điều Khoản Dịch Vụ' : 'Terms of Service',
      subtitle: isVi
          ? 'Các điều khoản này mô tả cách bạn có thể sử dụng TourXport để khám phá địa điểm, lưu nội dung, tạo lịch trình và đăng nhập bằng tài khoản mạng xã hội.'
          : 'These terms explain how you may use TourXport to explore destinations, save content, create itineraries, and sign in with social accounts.',
      activeRoute: '/terms',
      children: [
        LegalNotice(
          icon: Icons.article_outlined,
          title: isVi ? 'Điều khoản công khai cho người dùng và nền tảng' : 'Public terms for users and platform review',
          body: isVi
              ? 'Trang này có thể truy cập mà không cần đăng nhập và có thể dùng làm Terms of Service URL cho Discord Developer Portal.'
              : 'This page is accessible without login and can be used as the Terms of Service URL for the Discord Developer Portal.',
        ),
        LegalSection(
          title: isVi ? '1. Chấp nhận điều khoản' : '1. Acceptance of terms',
          paragraphs: [
            isVi
                ? 'Khi tạo tài khoản, đăng nhập hoặc sử dụng TourXport, bạn đồng ý tuân thủ các điều khoản này và Chính sách quyền riêng tư của chúng tôi.'
                : 'By creating an account, signing in, or using TourXport, you agree to follow these terms and our Privacy Policy.',
          ],
        ),
        LegalSection(
          title: isVi ? '2. Tài khoản và đăng nhập' : '2. Accounts and sign-in',
          bullets: isVi
              ? [
                  'Bạn chịu trách nhiệm bảo mật tài khoản, thiết bị và phiên đăng nhập của mình.',
                  'Bạn có thể đăng nhập bằng email, Google hoặc Discord nếu tính năng đó được bật.',
                  'Thông tin đăng nhập mạng xã hội chỉ được dùng để xác thực và tạo hồ sơ TourXport.',
                  'Bạn không được mạo danh người khác hoặc dùng thông tin không chính xác để tạo tài khoản.',
                ]
              : [
                  'You are responsible for keeping your account, device, and sessions secure.',
                  'You may sign in with email, Google, or Discord when those features are enabled.',
                  'Social login information is used only to authenticate you and create your TourXport profile.',
                  'You may not impersonate others or use inaccurate information to create an account.',
                ],
        ),
        LegalSection(
          title: isVi ? '3. Sử dụng dịch vụ' : '3. Use of the service',
          bullets: isVi
              ? [
                  'Bạn có thể khám phá địa điểm, nhà hàng, khách sạn, lưu nội dung và tạo lịch trình du lịch.',
                  'Bạn không được sử dụng TourXport để spam, tấn công hệ thống, thu thập dữ liệu trái phép hoặc vi phạm pháp luật.',
                  'Bạn không được gửi nội dung xúc phạm, gây hại, lừa đảo, vi phạm quyền riêng tư hoặc quyền sở hữu trí tuệ.',
                  'Chúng tôi có thể giới hạn hoặc tạm ngừng quyền truy cập nếu phát hiện lạm dụng hoặc rủi ro bảo mật.',
                ]
              : [
                  'You may explore places, restaurants, hotels, save content, and create travel itineraries.',
                  'You may not use TourXport to spam, attack systems, scrape data without permission, or violate the law.',
                  'You may not submit abusive, harmful, deceptive, privacy-violating, or intellectual-property-infringing content.',
                  'We may limit or suspend access if we detect abuse or security risk.',
                ],
        ),
        LegalSection(
          title: isVi ? '4. Lịch trình và dữ liệu du lịch' : '4. Itineraries and travel data',
          paragraphs: [
            isVi
                ? 'Thông tin địa điểm, thời tiết, tuyến đường, chi phí và lịch trình trong TourXport chỉ mang tính tham khảo. Bạn nên kiểm tra lại giờ mở cửa, giá, an toàn di chuyển và yêu cầu pháp lý trước khi đi.'
                : 'Destination, weather, route, cost, and itinerary information in TourXport is for reference only. You should verify opening hours, prices, travel safety, and legal requirements before traveling.',
          ],
        ),
        LegalSection(
          title: isVi ? '5. Nội dung do người dùng tạo' : '5. User content',
          bullets: isVi
              ? [
                  'Bạn giữ quyền đối với nội dung bạn gửi như đánh giá, phản ánh, ảnh và lịch trình.',
                  'Bạn cấp cho TourXport quyền lưu trữ, hiển thị và xử lý nội dung đó để vận hành tính năng trong ứng dụng.',
                  'Bạn chịu trách nhiệm đảm bảo nội dung mình gửi là hợp pháp và không xâm phạm quyền của người khác.',
                ]
              : [
                  'You retain rights to content you submit, such as reviews, reports, photos, and itineraries.',
                  'You grant TourXport permission to store, display, and process that content to operate app features.',
                  'You are responsible for ensuring your submitted content is lawful and does not violate others rights.',
                ],
        ),
        LegalSection(
          title: isVi ? '6. Dịch vụ bên thứ ba' : '6. Third-party services',
          paragraphs: [
            isVi
                ? 'TourXport có thể tích hợp Discord, Google, bản đồ, định tuyến, thời tiết, lưu trữ media và các dịch vụ hạ tầng khác. Việc sử dụng các dịch vụ đó có thể chịu thêm điều khoản riêng của nhà cung cấp.'
                : 'TourXport may integrate Discord, Google, maps, routing, weather, media hosting, and other infrastructure services. Use of those services may also be subject to provider terms.',
          ],
        ),
        LegalSection(
          title: isVi ? '7. Thay đổi và chấm dứt' : '7. Changes and termination',
          bullets: isVi
              ? [
                  'Chúng tôi có thể cập nhật tính năng, sửa lỗi hoặc thay đổi điều khoản khi cần thiết.',
                  'Bạn có thể ngừng sử dụng TourXport bất cứ lúc nào.',
                  'Chúng tôi có thể xóa hoặc hạn chế nội dung/tài khoản vi phạm điều khoản, gây hại cho người dùng khác hoặc ảnh hưởng đến hệ thống.',
                ]
              : [
                  'We may update features, fix issues, or change these terms when necessary.',
                  'You may stop using TourXport at any time.',
                  'We may remove or restrict content/accounts that violate these terms, harm other users, or affect the system.',
                ],
        ),
        LegalSection(
          title: isVi ? '8. Liên hệ' : '8. Contact',
          paragraphs: [
            isVi
                ? 'Nếu có câu hỏi về điều khoản, hãy liên hệ TourXport qua kênh hỗ trợ trong ứng dụng.'
                : 'If you have questions about these terms, contact TourXport through the support channel in the app.',
          ],
        ),
      ],
    );
  }
}
