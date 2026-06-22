import 'package:flutter/material.dart';

import 'legal_scaffold.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isVi = Localizations.localeOf(context).languageCode == 'vi';

    return LegalScaffold(
      title: isVi ? 'Chính Sách Quyền Riêng Tư' : 'Privacy Policy',
      subtitle: isVi
          ? 'Trang này giải thích cách TourXport thu thập, sử dụng, lưu trữ và bảo vệ thông tin khi bạn dùng ứng dụng để khám phá địa điểm, tạo lịch trình, lưu nội dung và đăng nhập bằng Discord hoặc Google.'
          : 'This page explains how TourXport collects, uses, stores, and protects information when people use the app, including sign-in with Discord or Google.',
      activeRoute: '/privacy',
      children: [
        LegalNotice(
          icon: Icons.public_rounded,
          title: isVi ? 'Chính sách công khai cho người dùng và nền tảng' : 'Public policy for users and platform review',
          body: isVi
              ? 'Chính sách này có thể truy cập mà không cần đăng nhập và có thể dùng làm Privacy Policy URL cho Discord Developer Portal.'
              : 'This policy is accessible without login and can be used as the Privacy Policy URL for Discord Developer Portal.',
        ),
        LegalSection(
          title: isVi ? '1. Thông tin chúng tôi thu thập' : '1. Information we collect',
          paragraphs: [
            isVi
                ? 'TourXport chỉ thu thập thông tin cần thiết để cung cấp tài khoản, lập kế hoạch du lịch và các tính năng lưu nội dung.'
                : 'TourXport only collects information needed to provide account, travel planning, and saved content features.',
          ],
          bullets: isVi
              ? [
                  'Thông tin tài khoản như tên, email, số điện thoại nếu cung cấp, ảnh đại diện và định danh nhà cung cấp đăng nhập.',
                  'Thông tin hồ sơ Discord hoặc Google mà bạn cho phép trong quá trình đăng nhập mạng xã hội.',
                  'Sở thích du lịch, câu trả lời khảo sát, lịch trình được tạo, địa điểm, khách sạn, nhà hàng và đánh giá đã lưu.',
                  'Vị trí tương đối hoặc chính xác chỉ khi bạn cấp quyền cho bản đồ, định tuyến hoặc tính năng gần bạn.',
                  'Thông tin kỹ thuật như loại thiết bị, lỗi ứng dụng, metadata request và log bảo mật để vận hành dịch vụ.',
                ]
              : [
                  'Account information such as name, email address, phone number if provided, avatar, and authentication provider identifiers.',
                  'Discord or Google profile information that you authorize during social sign-in, such as public profile, email, and profile picture.',
                  'Travel preferences, survey answers, generated itineraries, saved destinations, saved hotels, saved restaurants, and reviews you create.',
                  'Approximate or precise location only when you grant permission for map, routing, or nearby travel features.',
                  'Technical information such as device type, app errors, request metadata, and security logs used to operate and protect the service.',
                ],
        ),
        LegalSection(
          title: isVi ? '2. Cách chúng tôi sử dụng thông tin' : '2. How we use information',
          bullets: isVi
              ? [
                  'Tạo và quản lý tài khoản TourXport của bạn.',
                  'Xác thực bạn qua email, Google hoặc Discord.',
                  'Tạo gợi ý du lịch, lịch trình, thông tin tuyến đường và đề xuất cá nhân hóa.',
                  'Lưu địa điểm, tour, nhà hàng, khách sạn, đánh giá và tùy chọn hồ sơ của bạn.',
                  'Cải thiện độ ổn định, ngăn lạm dụng và bảo mật tài khoản.',
                  'Phản hồi các yêu cầu hỗ trợ, quyền riêng tư hoặc xóa dữ liệu.',
                ]
              : [
                  'Create and manage your TourXport account.',
                  'Authenticate you through email, Google, or Discord login.',
                  'Generate travel suggestions, itineraries, route information, and personalized recommendations.',
                  'Store your saved places, tours, restaurants, hotels, reviews, and profile preferences.',
                  'Improve app reliability, prevent abuse, and secure user accounts.',
                  'Respond to user support, privacy, or data deletion requests.',
                ],
        ),
        LegalSection(
          title: isVi ? '3. Chia sẻ và dịch vụ bên thứ ba' : '3. Sharing and third-party services',
          paragraphs: [
            isVi
                ? 'TourXport không bán dữ liệu cá nhân. Chúng tôi chỉ chia sẻ thông tin giới hạn với nhà cung cấp dịch vụ khi cần để vận hành tính năng.'
                : 'TourXport does not sell personal data. We may share limited information with service providers only when required to run app features.',
          ],
          bullets: isVi
              ? [
                  'Nhà cung cấp xác thực như Discord và Google cho các luồng đăng nhập do người dùng cho phép.',
                  'Dịch vụ cloud và lưu trữ media dùng cho ảnh hồ sơ hoặc tài nguyên ứng dụng.',
                  'Nhà cung cấp dữ liệu bản đồ, tuyến đường, thời tiết và du lịch cho tính năng khám phá và lịch trình.',
                  'Nhà cung cấp hạ tầng và cơ sở dữ liệu để lưu trữ backend và bảo vệ dịch vụ.',
                ]
              : [
                  'Authentication providers such as Discord and Google for login flows authorized by the user.',
                  'Cloud and media hosting services used to store profile images or app assets.',
                  'Map, route, weather, and travel data providers used to power destination discovery and itinerary features.',
                  'Infrastructure and database providers used to host the backend and protect the service.',
                ],
        ),
        LegalSection(
          title: isVi ? '4. Lưu trữ dữ liệu' : '4. Data retention',
          paragraphs: [
            isVi
                ? 'Chúng tôi giữ dữ liệu tài khoản và du lịch khi tài khoản còn hoạt động hoặc khi cần để cung cấp tính năng. Một số dữ liệu có thể được giữ trong thời gian giới hạn vì bảo mật, chống gian lận, nghĩa vụ pháp lý hoặc khôi phục sao lưu.'
                : 'We keep account and travel data while your account is active or as long as needed to provide TourXport features. Some data may be retained for a limited period when required for security, fraud prevention, legal obligations, or backup recovery.',
          ],
        ),
        LegalSection(
          title: isVi ? '5. Lựa chọn và quyền của bạn' : '5. Your choices and rights',
          bullets: isVi
              ? [
                  'Bạn có thể cập nhật thông tin hồ sơ trong ứng dụng.',
                  'Bạn có thể xóa tour đã lưu và các mục du lịch đã lưu khỏi tài khoản.',
                  'Bạn có thể thu hồi quyền Discord hoặc Google từ phần cài đặt của nhà cung cấp tương ứng.',
                  'Bạn có thể yêu cầu xóa dữ liệu cá nhân theo hướng dẫn trên trang Xóa dữ liệu.',
                ]
              : [
                  'You can update profile information inside the app.',
                  'You can remove saved tours and saved travel items from your account.',
                  'You can revoke Discord or Google access from the relevant provider account settings.',
                  'You can request deletion of personal data by following the instructions on the Data Deletion page.',
                ],
        ),
        LegalSection(
          title: isVi ? '6. Bảo mật' : '6. Security',
          paragraphs: [
            isVi
                ? 'TourXport sử dụng request API có xác thực, hash mật khẩu, access token, xác minh nhà cung cấp đăng nhập và các biện pháp vận hành hợp lý để bảo vệ dữ liệu người dùng.'
                : 'TourXport uses authenticated API requests, password hashing, access tokens, provider verification, and reasonable operational safeguards to protect user data.',
          ],
        ),
        LegalSection(
          title: isVi ? '7. Trẻ em' : '7. Children',
          paragraphs: [
            isVi
                ? 'TourXport không dành cho trẻ em dưới 13 tuổi. Chúng tôi không cố ý thu thập thông tin cá nhân từ trẻ em dưới 13 tuổi.'
                : 'TourXport is not intended for children under 13. We do not knowingly collect personal information from children under 13.',
          ],
        ),
        LegalSection(
          title: isVi ? '8. Liên hệ và cập nhật' : '8. Contact and updates',
          paragraphs: [
            isVi
                ? 'Chúng tôi có thể cập nhật chính sách khi tính năng, nhà cung cấp hoặc yêu cầu pháp lý thay đổi. Với câu hỏi về quyền riêng tư, hãy liên hệ TourXport qua kênh hỗ trợ trong ứng dụng.'
                : 'We may update this policy when app features, providers, or legal requirements change. For privacy questions, contact TourXport through the support channel listed in the app.',
          ],
        ),
      ],
    );
  }
}
