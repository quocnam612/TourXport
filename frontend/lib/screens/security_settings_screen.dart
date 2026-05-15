import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

class SecuritySettingsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String authToken;

  const SecuritySettingsScreen({
    super.key,
    required this.userData,
    required this.authToken,
  });

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  
  final TextEditingController _currentPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  
  bool _twoFactorEnabled = true;
  bool _faceIdEnabled = false;
  bool _fingerprintEnabled = true;
  
  double _passStrength = 0.0;
  String _passStrengthLabel = 'Yếu';
  Color _passStrengthColor = Colors.redAccent;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _progressController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    
    _fadeController.forward();
    _progressController.forward();
    
    _newPassController.addListener(_updatePassStrength);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _updatePassStrength() {
    String p = _newPassController.text;
    double strength = 0;
    if (p.length > 6) strength += 0.25;
    if (p.contains(RegExp(r'[A-Z]'))) strength += 0.25;
    if (p.contains(RegExp(r'[0-9]'))) strength += 0.25;
    if (p.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.25;

    setState(() {
      _passStrength = strength;
      if (strength <= 0.25) { _passStrengthLabel = 'Yếu'; _passStrengthColor = Colors.redAccent; }
      else if (strength <= 0.5) { _passStrengthLabel = 'Trung bình'; _passStrengthColor = Colors.orangeAccent; }
      else if (strength <= 0.75) { _passStrengthLabel = 'Mạnh'; _passStrengthColor = Colors.lightGreenAccent; }
      else { _passStrengthLabel = 'Rất mạnh'; _passStrengthColor = const Color(0xFF2ECC71); }
    });
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
                        _buildSecurityStatusSection(),
                        const SizedBox(height: 32),
                        _buildSectionLabel('Thay đổi mật khẩu'),
                        const SizedBox(height: 12),
                        _buildChangePasswordCard(),
                        const SizedBox(height: 32),
                        _buildSectionLabel('Xác thực nâng cao'),
                        const SizedBox(height: 12),
                        _buildTwoFactorCard(),
                        const SizedBox(height: 16),
                        _buildBiometricCard(),
                        const SizedBox(height: 32),
                        _buildSectionLabel('Thiết bị đang đăng nhập'),
                        const SizedBox(height: 12),
                        _buildDeviceList(),
                        const SizedBox(height: 32),
                        _buildSectionLabel('Lịch sử bảo mật'),
                        const SizedBox(height: 12),
                        _buildActivityTimeline(),
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
            child: const Icon(Icons.shield_rounded, color: Color(0xFFD4AF7A), size: 32),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Bảo Mật', style: TextStyle(fontFamily: 'Montserrat', fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
        const SizedBox(height: 8),
        Text('Quản lý quyền riêng tư và bảo vệ tài khoản của bạn', style: TextStyle(fontFamily: 'Montserrat', fontSize: 14, color: Colors.white.withOpacity(0.6), height: 1.5)),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(label.toUpperCase(), style: const TextStyle(fontFamily: 'Montserrat', fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFD4AF7A), letterSpacing: 1.5));
  }

  Widget _buildSecurityStatusSection() {
    return _buildGlassCard(
      child: Row(
        children: [
          SizedBox(
            width: 80, height: 80,
            child: AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) => Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(value: _progressController.value * 0.95, strokeWidth: 8, backgroundColor: Colors.white10, valueColor: const AlwaysStoppedAnimation(Color(0xFF2ECC71))),
                  Text('${(_progressController.value * 95).toInt()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bảo mật rất mạnh', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Tài khoản của bạn đang được bảo vệ tối ưu.', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF2ECC71).withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF2ECC71).withOpacity(0.3))),
                  child: const Text('ĐÃ XÁC MINH', style: TextStyle(color: Color(0xFF2ECC71), fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangePasswordCard() {
    return _buildGlassCard(
      child: Column(
        children: [
          _buildSecureInput(controller: _currentPassController, label: 'Mật khẩu hiện tại', obscure: _obscureCurrent, onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent)),
          const SizedBox(height: 20),
          _buildSecureInput(controller: _newPassController, label: 'Mật khẩu mới', obscure: _obscureNew, onToggle: () => setState(() => _obscureNew = !_obscureNew)),
          const SizedBox(height: 12),
          // Strength Bar
          Row(
            children: [
              Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(value: _passStrength, backgroundColor: Colors.white10, valueColor: AlwaysStoppedAnimation(_passStrengthColor)))),
              const SizedBox(width: 12),
              Text(_passStrengthLabel, style: TextStyle(color: _passStrengthColor, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          _buildSecureInput(controller: _confirmPassController, label: 'Xác nhận mật khẩu mới', obscure: _obscureConfirm, onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm)),
        ],
      ),
    );
  }

  Widget _buildTwoFactorCard() {
    return _buildGlassCard(
      child: Row(
        children: [
          const Icon(Icons.phonelink_lock_rounded, color: Color(0xFFD4AF7A), size: 28),
          const SizedBox(width: 16),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Xác thực 2 bước (2FA)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('Thêm lớp bảo mật khi đăng nhập.', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ])),
          Switch(value: _twoFactorEnabled, onChanged: (v) => setState(() => _twoFactorEnabled = v), activeColor: const Color(0xFFD4AF7A)),
        ],
      ),
    );
  }

  Widget _buildBiometricCard() {
    return _buildGlassCard(
      child: Column(
        children: [
          _buildSwitchTile(Icons.face_unlock_rounded, 'Face ID', _faceIdEnabled, (v) => setState(() => _faceIdEnabled = v)),
          const Divider(color: Colors.white10, height: 24),
          _buildSwitchTile(Icons.fingerprint_rounded, 'Vân tay', _fingerprintEnabled, (v) => setState(() => _fingerprintEnabled = v)),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(IconData icon, String label, bool value, Function(bool) onChanged) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(width: 16),
        Text(label, style: const TextStyle(color: Colors.white)),
        const Spacer(),
        Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFFD4AF7A)),
      ],
    );
  }

  Widget _buildDeviceList() {
    return Column(
      children: [
        _buildDeviceTile('iPhone 15 Pro Max', 'Hà Nội, Việt Nam', 'Đang hoạt động', true),
        const SizedBox(height: 12),
        _buildDeviceTile('MacBook Pro M3', 'Hồ Chí Minh, Việt Nam', '2 giờ trước', false),
      ],
    );
  }

  Widget _buildDeviceTile(String name, String loc, String time, bool isCurrent) {
    return _buildGlassCard(
      child: Row(
        children: [
          Icon(isCurrent ? Icons.smartphone_rounded : Icons.laptop_mac_rounded, color: isCurrent ? const Color(0xFF2ECC71) : Colors.white30, size: 32),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('$loc • $time', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
          ])),
          if (!isCurrent) TextButton(onPressed: () {}, child: const Text('Đăng xuất', style: TextStyle(color: Colors.redAccent, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildActivityTimeline() {
    return _buildGlassCard(
      child: Column(
        children: [
          _buildActivityItem('Đổi mật khẩu', 'Hôm nay, 10:30', Icons.key_rounded, const Color(0xFFD4AF7A)),
          const SizedBox(height: 16),
          _buildActivityItem('Đăng nhập từ thiết bị mới', 'Hôm qua, 21:15', Icons.login_rounded, Colors.orangeAccent),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return Row(
      children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 16)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
          Text(time, style: TextStyle(color: Colors.white38, fontSize: 12)),
        ])),
      ],
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
              // _showToast('Đang cập nhật bảo mật...');
              Future.delayed(const Duration(milliseconds: 1500), () { _showToast('Cài đặt bảo mật đã được lưu!'); Navigator.pop(context); });
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

  Widget _buildSecureInput({required TextEditingController controller, required String label, required bool obscure, required VoidCallback onToggle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.08))),
          child: TextField(
            controller: controller, obscureText: obscure,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.white38, size: 20), onPressed: onToggle),
              border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
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
