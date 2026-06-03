import 'dart:ui';
import 'package:flutter/material.dart';

class ProfileSection extends StatelessWidget {
  final Animation<double> entranceAnimation;
  final Map<String, dynamic>? userData;
  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback onLogout;
  final VoidCallback onUpdateAvatar;
  final VoidCallback onUpdateCover;
  final VoidCallback onEditPhone;
  final VoidCallback onEditSecurity;
  final VoidCallback onEditNotifications;
  final VoidCallback onEditLanguage;
  final VoidCallback onEditHelpSupport;

  const ProfileSection({
    super.key,
    required this.entranceAnimation,
    required this.userData,
    required this.isLoading,
    required this.onBack,
    required this.onLogout,
    required this.onUpdateAvatar,
    required this.onUpdateCover,
    required this.onEditPhone,
    required this.onEditSecurity,
    required this.onEditNotifications,
    required this.onEditLanguage,
    required this.onEditHelpSupport,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    final isVi = Localizations.localeOf(context).languageCode == 'vi';
    final isGuest = userData == null;
    final name = isGuest ? (isVi ? 'Khách du lịch' : 'Guest Traveler') : (userData?['name'] ?? (isVi ? 'Người dùng' : 'User'));
    final email = isGuest ? (isVi ? 'Đăng nhập để xem email' : 'Sign in to view email') : (userData?['email'] ?? (isVi ? 'Chưa cập nhật email' : 'Email not updated'));
    final phone = isGuest ? (isVi ? 'Đăng nhập để xem số điện thoại' : 'Sign in to view phone number') : (userData?['phone'] ?? (isVi ? 'Chưa cập nhật số điện thoại' : 'Phone not updated'));
    final bio = isGuest 
        ? (isVi ? 'Hãy đăng nhập để mọi người biết thêm về bạn!.' : 'Please sign in to let others know more about you!')
        : (userData?['bio'] ?? (isVi ? 'Chưa có tiểu sử. Hãy cập nhật để mọi người biết thêm về bạn!' : 'No bio yet. Update to let others know more about you!'));
    final avatarUrl = userData?['avatarUrl'] ?? userData?['avatar'] ?? '';
    final coverUrl = userData?['coverUrl'] ?? userData?['cover'] ?? '';

    return Stack(
      children: [
        // Subtle top ambient gold glow for premium style
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.2,
                colors: [
                  const Color(0xFFD4AF7A).withOpacity(0.10),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Scrollable Content
        MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: SingleChildScrollView(
            key: const ValueKey<String>('profile_tab'),
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(context, name, avatarUrl, coverUrl, bio, isGuest),
                Transform.translate(
                  offset: const Offset(0, -60),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        if (isGuest) ...[
                          // Beautiful Guest CTA Card
                          Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.32),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: const Color(0xFFD4AF7A).withOpacity(0.25),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFD4AF7A).withOpacity(0.04),
                                  blurRadius: 40,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD4AF7A).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.login_rounded,
                                    color: Color(0xFFD4AF7A),
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  isVi ? 'Khám phá nhiều hơn!' : 'Discover more!',
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isVi 
                                      ? 'Hãy đăng nhập tài khoản của bạn để lưu lại các điểm đến yêu thích và lên lịch trình du lịch cá nhân hóa với trí tuệ nhân tạo.'
                                      : 'Please sign in to your account to save your favorite destinations and plan personalized itineraries with AI.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.7),
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: onLogout, // Directs to Sign In screen for guest
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD4AF7A),
                                    foregroundColor: const Color(0xFF1B2321),
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    elevation: 4,
                                  ),
                                  child: Text(
                                    isVi ? 'ĐĂNG NHẬP / ĐĂNG KÝ' : 'SIGN IN / SIGN UP',
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // General settings group for guest
                          _buildMenuGroup(
                            context,
                            items: [
                              _MenuDataItem(
                                icon: Icons.language_rounded, 
                                title: isVi ? 'Ngôn ngữ' : 'Language', 
                                subtitle: isVi ? 'Tiếng Việt' : 'English', 
                                onTap: onEditLanguage
                              ),
                              _MenuDataItem(
                                icon: Icons.help_outline_rounded, 
                                title: isVi ? 'Trợ giúp & Hỗ trợ' : 'Help & Support', 
                                onTap: onEditHelpSupport
                              ),
                              _MenuDataItem(
                                icon: Icons.login_rounded,
                                title: isVi ? 'Đăng nhập / Đăng ký' : 'Sign In / Sign Up',
                                titleColor: const Color(0xFFD4AF7A),
                                onTap: onLogout,
                              ),
                            ],
                          ),
                        ] else ...[
                          _buildMenuGroup(
                            context,
                            items: [
                              _MenuDataItem(
                                icon: Icons.person_outline_rounded,
                                title: isVi ? 'Thông tin cá nhân' : 'Personal Information',
                                subtitle: name,
                              ),
                              _MenuDataItem(
                                icon: Icons.email_outlined,
                                title: 'Email',
                                subtitle: email,
                              ),
                              _MenuDataItem(
                                icon: Icons.phone_android_rounded,
                                title: isVi ? 'Số điện thoại' : 'Phone Number',
                                subtitle: phone,
                                onTap: onEditPhone,
                              ),
                            ],
                          ),
                          _buildMenuGroup(
                            context,
                            items: [
                              _MenuDataItem(
                                icon: Icons.notifications_none_rounded, 
                                title: isVi ? 'Thông báo' : 'Notifications', 
                                onTap: onEditNotifications
                              ),
                              _MenuDataItem(
                                icon: Icons.language_rounded, 
                                title: isVi ? 'Ngôn ngữ' : 'Language', 
                                subtitle: isVi ? 'Tiếng Việt' : 'English', 
                                onTap: onEditLanguage
                              ),
                              _MenuDataItem(
                                icon: Icons.security_rounded, 
                                title: isVi ? 'Bảo mật' : 'Security', 
                                onTap: onEditSecurity
                              ),
                            ],
                          ),
                          _buildMenuGroup(
                            context,
                            items: [
                              _MenuDataItem(
                                icon: Icons.help_outline_rounded, 
                                title: isVi ? 'Trợ giúp & Hỗ trợ' : 'Help & Support', 
                                onTap: onEditHelpSupport
                              ),
                              _MenuDataItem(
                                icon: Icons.logout_rounded,
                                title: isVi ? 'Đăng xuất' : 'Log Out',
                                titleColor: const Color(0xFFE74C3C),
                                onTap: onLogout,
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, String name, String avatarUrl, String coverUrl, String bio, bool isGuest) {
    final screenW = MediaQuery.of(context).size.width;
    final topPadding = MediaQuery.of(context).padding.top;
    
    return FadeTransition(
      opacity: entranceAnimation,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Header sizing container (background provided by parent Stack)
          SizedBox(
            height: 440,
            width: screenW,
          ),
          
          // Action Button (Back)
          Positioned(
            top: topPadding + 12,
            left: 20,
            child: _glassIconButton(Icons.arrow_back_ios_new_rounded, onBack),
          ),

          // Header Content (Avatar + Name + Bio)
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Avatar with Glowing Ring
                _buildAvatar(name, avatarUrl, isGuest),
                const SizedBox(height: 20),
                // Name
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Colors.black54, blurRadius: 15, offset: Offset(0, 4))
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Bio
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    bio,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.75),
                      height: 1.5,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String name, String avatarUrl, bool isGuest) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glowing Ambient Ring
        Container(
          width: 128,
          height: 128,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFD4AF7A).withOpacity(0.35),
                const Color(0xFFD4AF7A).withOpacity(0.0),
              ],
            ),
          ),
        ),
        // Outer Gradient Border Ring
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFD4AF7A),
                Color(0xFFB5956A),
                Color(0xFF2A4A3E),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF7A).withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFF1B2321),
              shape: BoxShape.circle,
            ),
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF2A4A3E), Color(0xFF1B2321)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: ClipOval(
                child: avatarUrl.isNotEmpty
                    ? Image.network(avatarUrl, fit: BoxFit.cover)
                    : Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 44,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFD4AF7A),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
        // Edit Avatar Badge
        if (!isGuest)
          Positioned(
            bottom: 4,
            right: 4,
            child: GestureDetector(
              onTap: onUpdateAvatar,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF7A),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFF1B2321), width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMenuGroup(BuildContext context, {required List<_MenuDataItem> items}) {
    return FadeTransition(
      opacity: entranceAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.32),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withOpacity(0.12),
            width: 1.2,
          ),
          boxShadow: [
            // Deep Ambient Shadow
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 30,
              spreadRadius: -2,
              offset: const Offset(0, 15),
            ),
            // Subtle Accent Glow
            BoxShadow(
              color: const Color(0xFFD4AF7A).withOpacity(0.04),
              blurRadius: 40,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Column(
              children: List.generate(items.length, (index) {
                final item = items[index];
                final isLast = index == items.length - 1;
                
                return Column(
                  children: [
                    _buildMenuItem(context, item),
                    if (!isLast)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Divider(
                          color: Colors.white.withOpacity(0.06),
                          height: 1,
                          thickness: 0.5,
                        ),
                      ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, _MenuDataItem item) {
    return InkWell(
      onTap: item.onTap,
      highlightColor: Colors.white.withOpacity(0.05),
      splashColor: const Color(0xFFD4AF7A).withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                  width: 1,
                ),
              ),
              child: Icon(
                item.icon,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: item.titleColor ?? Colors.white,
                    ),
                  ),
                  if (item.subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        item.subtitle!,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.45),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (item.onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.25),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

class _MenuDataItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? titleColor;

  _MenuDataItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.titleColor,
  });
}
