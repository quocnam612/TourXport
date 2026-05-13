import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String authToken;

  const NotificationSettingsScreen({
    super.key,
    required this.userData,
    required this.authToken,
  });

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  
  bool _masterNotification = true;
  
  // Push Notifications
  bool _pushMessages = true;
  bool _pushAccountActivity = true;
  bool _pushSystemUpdates = true;
  bool _pushPromotions = false;
  bool _pushTravelTips = true;
  bool _pushTripReminders = true;
  bool _pushFriendActivity = false;
  bool _pushSecurityAlerts = true;
  
  // Email Notifications
  bool _emailAccount = true;
  bool _emailSecurity = true;
  bool _emailPromotions = false;
  bool _emailNewsletter = true;
  bool _emailWeeklySummary = false;
  
  // Sound & Vibration
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  double _vibrationIntensity = 0.7;
  
  // Preview Mode
  int _previewModeIndex = 0; // 0: Show all, 1: Hide on lock, 2: Icon only
  
  // Do Not Disturb
  bool _dndEnabled = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Montserrat')),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFFD4AF7A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F1412),
      body: Stack(
        children: [
          _buildHeroBackground(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverAppBar(expandedHeight: 140, backgroundColor: Colors.transparent, elevation: 0, automaticallyImplyLeading: false),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeController,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroHeaderContent(),
                        const SizedBox(height: 32),
                        _buildMasterToggleCard(),
                        const SizedBox(height: 32),
                        _buildSectionLabel('Thông báo ứng dụng (Push)'),
                        const SizedBox(height: 12),
                        _buildPushSection(),
                        const SizedBox(height: 32),
                        _buildSectionLabel('Thông báo qua Email'),
                        const SizedBox(height: 12),
                        _buildEmailSection(),
                        const SizedBox(height: 32),
                        _buildSectionLabel('Âm thanh & Rung'),
                        const SizedBox(height: 12),
                        _buildSoundVibrationSection(),
                        const SizedBox(height: 32),
                        _buildSectionLabel('Xem trước thông báo'),
                        const SizedBox(height: 12),
                        _buildPreviewSection(),
                        const SizedBox(height: 32),
                        _buildSectionLabel('Chế độ không làm phiền'),
                        const SizedBox(height: 12),
                        _buildDndSection(),
                        const SizedBox(height: 48),
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: topPadding + 12,
            left: 20,
            child: _glassIconButton(Icons.arrow_back_ios_new_rounded, () => Navigator.pop(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBackground() {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/halong.jpg', fit: BoxFit.cover),
          Container(decoration: BoxDecoration(color: const Color(0xFF1B2321).withOpacity(0.78))),
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 150,
              decoration: BoxDecoration(gradient: RadialGradient(center: Alignment.topCenter, radius: 1.2, colors: [const Color(0xFFD4AF7A).withOpacity(0.10), Colors.transparent])),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeaderContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScaleTransition(
          scale: _fadeController,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFD4AF7A).withOpacity(0.15), shape: BoxShape.circle, border: Border.all(color: const Color(0xFFD4AF7A).withOpacity(0.3))),
            child: const Icon(Icons.notifications_active_rounded, color: Color(0xFFD4AF7A), size: 32),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Thông Báo', style: TextStyle(fontFamily: 'Montserrat', fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
        const SizedBox(height: 8),
        Text('Cá nhân hóa cách bạn nhận cập nhật và tin tức', style: TextStyle(fontFamily: 'Montserrat', fontSize: 14, color: Colors.white.withOpacity(0.6), height: 1.5)),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(label.toUpperCase(), style: const TextStyle(fontFamily: 'Montserrat', fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFD4AF7A), letterSpacing: 1.5));
  }

  Widget _buildMasterToggleCard() {
    return _buildGlassCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_masterNotification ? 'Thông báo đang bật' : 'Thông báo đang tắt', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Bạn sẽ nhận được các cập nhật quan trọng từ TourXport.', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
              ],
            ),
          ),
          Switch(value: _masterNotification, onChanged: (v) => setState(() => _masterNotification = v), activeColor: const Color(0xFFD4AF7A)),
        ],
      ),
    );
  }

  Widget _buildPushSection() {
    return _buildGlassCard(
      child: Column(
        children: [
          _buildToggleTile(Icons.chat_bubble_outline_rounded, 'Tin nhắn', 'Thông báo khi có tin nhắn mới', _pushMessages, (v) => setState(() => _pushMessages = v)),
          _buildToggleTile(Icons.person_outline_rounded, 'Hoạt động tài khoản', 'Thay đổi mật khẩu, đăng nhập mới', _pushAccountActivity, (v) => setState(() => _pushAccountActivity = v)),
          _buildToggleTile(Icons.system_update_rounded, 'Cập nhật hệ thống', 'Thông báo bảo trì và tính năng mới', _pushSystemUpdates, (v) => setState(() => _pushSystemUpdates = v)),
          _buildToggleTile(Icons.card_giftcard_rounded, 'Khuyến mãi', 'Ưu đãi và mã giảm giá độc quyền', _pushPromotions, (v) => setState(() => _pushPromotions = v)),
          _buildToggleTile(Icons.explore_outlined, 'Gợi ý du lịch', 'Điểm đến phù hợp với sở thích', _pushTravelTips, (v) => setState(() => _pushTravelTips = v)),
          _buildToggleTile(Icons.event_note_rounded, 'Nhắc nhở hành trình', 'Thông báo trước chuyến đi', _pushTripReminders, (v) => setState(() => _pushTripReminders = v)),
          _buildToggleTile(Icons.group_outlined, 'Hoạt động bạn bè', 'Khi bạn bè chia sẻ khoảnh khắc mới', _pushFriendActivity, (v) => setState(() => _pushFriendActivity = v)),
          _buildToggleTile(Icons.security_rounded, 'Thông báo bảo mật', 'Cảnh báo rủi ro quan trọng', _pushSecurityAlerts, (v) => setState(() => _pushSecurityAlerts = v)),
        ],
      ),
    );
  }

  Widget _buildEmailSection() {
    return _buildGlassCard(
      child: Column(
        children: [
          _buildToggleTile(Icons.alternate_email_rounded, 'Email tài khoản', 'Cập nhật thông tin hồ sơ', _emailAccount, (v) => setState(() => _emailAccount = v)),
          _buildToggleTile(Icons.verified_user_outlined, 'Email bảo mật', 'Xác thực OTP và đăng nhập', _emailSecurity, (v) => setState(() => _emailSecurity = v)),
          _buildToggleTile(Icons.local_offer_outlined, 'Email khuyến mãi', 'Tin tức về tour du lịch giá rẻ', _emailPromotions, (v) => setState(() => _emailPromotions = v)),
          _buildToggleTile(Icons.newspaper_rounded, 'Bản tin du lịch', 'Cảm hứng du lịch hàng tháng', _emailNewsletter, (v) => setState(() => _emailNewsletter = v)),
          _buildToggleTile(Icons.summarize_outlined, 'Tổng hợp hàng tuần', 'Báo cáo hoạt động của bạn', _emailWeeklySummary, (v) => setState(() => _emailWeeklySummary = v)),
        ],
      ),
    );
  }

  Widget _buildToggleTile(IconData icon, String title, String subtitle, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 24),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(color: Colors.white38, fontSize: 12)),
          ])),
          Switch(value: value, onChanged: _masterNotification ? onChanged : null, activeColor: const Color(0xFFD4AF7A)),
        ],
      ),
    );
  }

  Widget _buildSoundVibrationSection() {
    return _buildGlassCard(
      child: Column(
        children: [
          _buildSwitchRow(Icons.volume_up_rounded, 'Âm thanh thông báo', _soundEnabled, (v) => setState(() => _soundEnabled = v)),
          const Divider(color: Colors.white10, height: 32),
          _buildSwitchRow(Icons.vibration_rounded, 'Rung khi có thông báo', _vibrationEnabled, (v) => setState(() => _vibrationEnabled = v)),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.graphic_eq_rounded, color: Colors.white.withOpacity(0.3), size: 18),
              const SizedBox(width: 12),
              const Text('Cường độ rung', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
          Slider(
            value: _vibrationIntensity,
            onChanged: _vibrationEnabled ? (v) => setState(() => _vibrationIntensity = v) : null,
            activeColor: const Color(0xFFD4AF7A),
            inactiveColor: Colors.white10,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(IconData icon, String label, bool value, Function(bool) onChanged) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 22),
        const SizedBox(width: 16),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
        const Spacer(),
        Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFFD4AF7A)),
      ],
    );
  }

  Widget _buildPreviewSection() {
    return _buildGlassCard(
      child: Column(
        children: [
          Row(
            children: [
              _buildSegmentItem(0, 'Hiện tất cả'),
              _buildSegmentItem(1, 'Ẩn nội dung'),
              _buildSegmentItem(2, 'Chỉ biểu tượng'),
            ],
          ),
          const SizedBox(height: 24),
          // Preview Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.1))),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFFD4AF7A), shape: BoxShape.circle), child: const Icon(Icons.notifications, color: Colors.white, size: 16)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('TourXport', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(_previewModeIndex == 0 ? 'Bạn có gợi ý du lịch mới tại Đà Lạt!' : (_previewModeIndex == 1 ? 'Thông báo mới' : '...'), style: TextStyle(color: Colors.white60, fontSize: 12)),
                ])),
                Text('Bây giờ', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentItem(int index, String label) {
    bool isSelected = _previewModeIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _previewModeIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFD4AF7A) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? const Color(0xFF1B2321) : Colors.white54, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ),
      ),
    );
  }

  Widget _buildDndSection() {
    return _buildGlassCard(
      child: Column(
        children: [
          _buildSwitchRow(Icons.do_not_disturb_on_rounded, 'Chế độ không làm phiền', _dndEnabled, (v) => setState(() => _dndEnabled = v)),
          if (_dndEnabled) ...[
            const SizedBox(height: 16),
            _buildActionTile(Icons.access_time_rounded, 'Lên lịch tự động', '22:00 - 07:00'),
          ],
        ],
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFD4AF7A), size: 20),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Color(0xFFD4AF7A), fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Container(
          width: double.infinity, height: 60,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), gradient: const LinearGradient(colors: [Color(0xFFD4AF7A), Color(0xFFB5956A)]), boxShadow: [BoxShadow(color: const Color(0xFFD4AF7A).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))]),
          child: ElevatedButton(
            onPressed: () {
              _showToast('Đang lưu cài đặt thông báo...');
              Future.delayed(const Duration(milliseconds: 1500), () { _showToast('Đã lưu các thay đổi!'); Navigator.pop(context); });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
            child: const Text('Lưu thay đổi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1B2321))),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Đặt lại mặc định', style: TextStyle(color: Colors.white.withOpacity(0.4), fontWeight: FontWeight.bold))),
      ],
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.black.withOpacity(0.32), borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.2)), child: child),
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
          child: Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(0.25))), child: Icon(icon, color: Colors.white, size: 20)),
        ),
      ),
    );
  }
}
