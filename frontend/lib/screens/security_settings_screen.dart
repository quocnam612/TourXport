import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../api/api.dart';

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
  
  final TextEditingController _currentPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSavingPassword = false;
  
  double _passStrength = 0.0;
  Color _passStrengthColor = Colors.redAccent;

  bool get _isVi => Localizations.localeOf(context).languageCode == 'vi';

  bool get _hasLocalLogin => _loginProviders.contains('local');

  List<String> get _loginProviders {
    final rawProviders = widget.userData['authProvider'];
    final Set<String> providers;

    if (rawProviders is List) {
      providers = rawProviders
          .map((provider) => provider.toString().trim().toLowerCase())
          .where((provider) => provider.isNotEmpty)
          .toSet();
    } else if (rawProviders is String) {
      providers = rawProviders
          .split(',')
          .map((provider) => provider.trim().toLowerCase())
          .where((provider) => provider.isNotEmpty)
          .toSet();
    } else {
      providers = <String>{};
    }

    return ['local', 'google', 'discord'].where(providers.contains).toList();
  }

  String get _passStrengthLabel {
    if (_passStrength <= 0.25) return _isVi ? 'Yếu' : 'Weak';
    if (_passStrength <= 0.5) return _isVi ? 'Trung bình' : 'Medium';
    if (_passStrength <= 0.75) return _isVi ? 'Mạnh' : 'Strong';
    return _isVi ? 'Rất mạnh' : 'Very strong';
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    
    _fadeController.forward();
    
    _newPassController.addListener(_updatePassStrength);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
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
      if (strength <= 0.25) { _passStrengthColor = Colors.redAccent; }
      else if (strength <= 0.5) { _passStrengthColor = Colors.orangeAccent; }
      else if (strength <= 0.75) { _passStrengthColor = Colors.lightGreenAccent; }
      else { _passStrengthColor = const Color(0xFF2ECC71); }
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

  Future<void> _changePassword() async {
    final oldPassword = _currentPassController.text.trim();
    final newPassword = _newPassController.text.trim();
    final confirmPassword = _confirmPassController.text.trim();

    if (_isSavingPassword) return;

    if ((_hasLocalLogin && oldPassword.isEmpty) || newPassword.isEmpty || confirmPassword.isEmpty) {
      _showToast(_isVi ? 'Vui lòng nhập đầy đủ thông tin mật khẩu.' : 'Please fill in all password fields.', isError: true);
      return;
    }

    if (newPassword.length < 8) {
      _showToast(_isVi ? 'Mật khẩu mới phải có ít nhất 8 ký tự.' : 'New password must be at least 8 characters.', isError: true);
      return;
    }

    if (newPassword != confirmPassword) {
      _showToast(_isVi ? 'Xác nhận mật khẩu mới không khớp.' : 'Password confirmation does not match.', isError: true);
      return;
    }

    setState(() => _isSavingPassword = true);

    try {
      final response = await apiPutJson(
        '/auth/profile/change-password',
        {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        },
        token: widget.authToken,
      );

      if (!mounted) return;

      final data = tryDecodeJsonObject(response.body);
      final message = data?['message'] as String?;

      if (response.statusCode == 200 && data?['success'] == true) {
        _currentPassController.clear();
        _newPassController.clear();
        _confirmPassController.clear();
        _showToast(message ?? (_isVi ? 'Đổi mật khẩu thành công!' : 'Password changed successfully!'));
        Navigator.pop(context);
        return;
      }

      _showToast(message ?? (_isVi ? 'Đổi mật khẩu thất bại.' : 'Failed to change password.'), isError: true);
    } catch (error) {
      if (!mounted) return;
      _showToast(_isVi ? 'Không kết nối được server. ($error)' : 'Could not connect to the server. ($error)', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSavingPassword = false);
      }
    }
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
                        _buildSectionLabel(_isVi ? 'Thay đổi mật khẩu' : 'Change password'),
                        const SizedBox(height: 12),
                        _buildChangePasswordCard(),
                        const SizedBox(height: 32),
                        _buildSectionLabel(_isVi ? 'Phương thức đăng nhập' : 'Login methods'),
                        const SizedBox(height: 12),
                        _buildLoginMethodsCard(),
                        const SizedBox(height: 32),
                        _buildSectionLabel(_isVi ? 'Lịch sử bảo mật' : 'Security history'),
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
        Text(_isVi ? 'Bảo Mật' : 'Security', style: const TextStyle(fontFamily: 'Montserrat', fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
        const SizedBox(height: 8),
        Text(
          _isVi ? 'Quản lý quyền riêng tư và bảo vệ tài khoản của bạn' : 'Manage your privacy and protect your account',
          style: TextStyle(fontFamily: 'Montserrat', fontSize: 14, color: Colors.white.withOpacity(0.6), height: 1.5),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(label.toUpperCase(), style: const TextStyle(fontFamily: 'Montserrat', fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFD4AF7A), letterSpacing: 1.5));
  }

  Widget _buildChangePasswordCard() {
    return _buildGlassCard(
      child: Column(
        children: [
          _buildSecureInput(
            controller: _currentPassController,
            label: _hasLocalLogin
                ? (_isVi ? 'Mật khẩu hiện tại' : 'Current password')
                : (_isVi ? 'Mật khẩu hiện tại (có thể bỏ trống)' : 'Current password (optional)'),
            obscure: _obscureCurrent,
            onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
          ),
          const SizedBox(height: 20),
          _buildSecureInput(controller: _newPassController, label: _isVi ? 'Mật khẩu mới' : 'New password', obscure: _obscureNew, onToggle: () => setState(() => _obscureNew = !_obscureNew)),
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
          _buildSecureInput(controller: _confirmPassController, label: _isVi ? 'Xác nhận mật khẩu mới' : 'Confirm new password', obscure: _obscureConfirm, onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm)),
        ],
      ),
    );
  }

  Widget _buildLoginMethodsCard() {
    final providers = _loginProviders;

    if (providers.isEmpty) {
      return _buildGlassCard(
        child: Text(
          _isVi ? 'Chưa có phương thức đăng nhập nào được ghi nhận.' : 'No login methods have been recorded.',
          style: TextStyle(fontFamily: 'Montserrat', color: Colors.white.withOpacity(0.65), fontSize: 13, height: 1.5),
        ),
      );
    }

    return _buildGlassCard(
      child: Column(
        children: [
          for (int i = 0; i < providers.length; i++) ...[
            _buildLoginMethodItem(providers[i]),
            if (i < providers.length - 1) Divider(height: 24, color: Colors.white.withOpacity(0.08)),
          ],
        ],
      ),
    );
  }

  Widget _buildLoginMethodItem(String provider) {
    final Color color = _loginMethodColor(provider);

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.24))),
          child: Center(child: _buildLoginMethodIcon(provider, color)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_loginMethodLabel(provider), style: const TextStyle(fontFamily: 'Montserrat', color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(_loginMethodDescription(provider), style: TextStyle(fontFamily: 'Montserrat', color: Colors.white.withOpacity(0.45), fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xFF2ECC71).withOpacity(0.12), borderRadius: BorderRadius.circular(999), border: Border.all(color: const Color(0xFF2ECC71).withOpacity(0.32))),
          child: Text(
            _isVi ? 'Đã liên kết' : 'Linked',
            style: const TextStyle(fontFamily: 'Montserrat', color: Color(0xFF2ECC71), fontSize: 10, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }

  String _loginMethodLabel(String provider) {
    switch (provider) {
      case 'local':
        return _isVi ? 'Email / Số điện thoại' : 'Email / Phone';
      case 'google':
        return 'Google';
      case 'discord':
        return 'Discord';
      default:
        return provider;
    }
  }

  String _loginMethodDescription(String provider) {
    switch (provider) {
      case 'local':
        return _isVi ? 'Đăng nhập bằng email và mật khẩu' : 'Sign in with email and password';
      case 'google':
        return _isVi ? 'Đăng nhập bằng tài khoản Google' : 'Sign in with your Google account';
      case 'discord':
        return _isVi ? 'Đăng nhập bằng tài khoản Discord' : 'Sign in with your Discord account';
      default:
        return _isVi ? 'Phương thức đăng nhập đã liên kết' : 'Linked login method';
    }
  }

  Widget _buildLoginMethodIcon(String provider, Color color) {
    final assetPath = _loginMethodIconAsset(provider);

    if (assetPath != null) {
      return Image.asset(assetPath, width: 22, height: 22, fit: BoxFit.contain);
    }

    return Icon(_loginMethodFallbackIcon(provider), color: color, size: 20);
  }

  String? _loginMethodIconAsset(String provider) {
    switch (provider) {
      case 'google':
        return 'assets/icons/gg_logo.png';
      case 'discord':
        return 'assets/icons/dc_logo.png';
      default:
        return null;
    }
  }

  IconData _loginMethodFallbackIcon(String provider) {
    switch (provider) {
      case 'local':
        return Icons.email_rounded;
      default:
        return Icons.login_rounded;
    }
  }

  Color _loginMethodColor(String provider) {
    switch (provider) {
      case 'local':
        return const Color(0xFFD4AF7A);
      case 'google':
        return const Color(0xFF4285F4);
      case 'discord':
        return const Color(0xFF5865F2);
      default:
        return Colors.white70;
    }
  }

  Widget _buildActivityTimeline() {
    return _buildGlassCard(
      child: Column(
        children: [
          _buildActivityItem(_isVi ? 'Đổi mật khẩu' : 'Password changed', _isVi ? 'Hôm nay, 10:30' : 'Today, 10:30', Icons.key_rounded, const Color(0xFFD4AF7A)),
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
            onPressed: _isSavingPassword ? null : _changePassword,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
            child: _isSavingPassword
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF1B2321)))
                : Text(_isVi ? 'Lưu thay đổi' : 'Save changes', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1B2321))),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(onPressed: () => Navigator.pop(context), child: Text(_isVi ? 'Đặt lại mặc định' : 'Reset defaults', style: TextStyle(color: Colors.white.withOpacity(0.4), fontWeight: FontWeight.bold))),
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
