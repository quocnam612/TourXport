import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

class PhoneSettingsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String authToken;

  const PhoneSettingsScreen({
    super.key,
    required this.userData,
    required this.authToken,
  });

  @override
  State<PhoneSettingsScreen> createState() => _PhoneSettingsScreenState();
}

class _PhoneSettingsScreenState extends State<PhoneSettingsScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  
  final TextEditingController _phoneController = TextEditingController();
  String _selectedCountryCode = '+84';
  String _selectedCountryName = 'Việt Nam';
  
  bool _isVerifying = false;
  bool _showOtpSection = false;
  int _resendTimer = 0;
  Timer? _timer;
  
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _phoneController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() => _resendTimer = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer == 0) {
        timer.cancel();
      } else {
        setState(() => _resendTimer--);
      }
    });
  }

  void _handleSendCode() {
    if (_phoneController.text.isEmpty || _phoneController.text.length < 9) {
      _showToast('Vui lòng nhập số điện thoại hợp lệ', isError: true);
      return;
    }
    setState(() => _isVerifying = true);
    
    // Simulate API call
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isVerifying = false;
        _showOtpSection = true;
      });
      _startResendTimer();
      _showToast('Mã OTP đã được gửi đến số điện thoại của bạn');
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

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1B2321),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Chọn mã vùng quốc gia',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  _buildCountryTile('🇻🇳', 'Việt Nam', '+84'),
                  _buildCountryTile('🇺🇸', 'Hoa Kỳ', '+1'),
                  _buildCountryTile('🇸🇬', 'Singapore', '+65'),
                  _buildCountryTile('🇯🇵', 'Nhật Bản', '+81'),
                  _buildCountryTile('🇰🇷', 'Hàn Quốc', '+82'),
                  _buildCountryTile('🇹🇭', 'Thái Lan', '+66'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountryTile(String flag, String name, String code) {
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(name, style: const TextStyle(color: Colors.white)),
      trailing: Text(code, style: const TextStyle(color: Color(0xFFD4AF7A), fontWeight: FontWeight.bold)),
      onTap: () {
        setState(() {
          _selectedCountryCode = code;
          _selectedCountryName = name;
        });
        Navigator.pop(context);
      },
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
                        _buildSectionLabel('Số điện thoại hiện tại'),
                        const SizedBox(height: 12),
                        _buildCurrentPhoneCard(),
                        const SizedBox(height: 32),
                        _buildSectionLabel('Thay đổi Số điện thoại'),
                        const SizedBox(height: 12),
                        _buildChangePhoneCard(),
                        if (_showOtpSection) ...[
                          const SizedBox(height: 32),
                          _buildSectionLabel('Xác thực OTP'),
                          const SizedBox(height: 12),
                          _buildOtpSection(),
                        ],
                        const SizedBox(height: 32),
                        _buildSecurityNoticeCard(),
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
    final String coverUrl = widget.userData['coverUrl'] ?? '';
    final screenW = MediaQuery.of(context).size.width;
    
    return Container(
      height: 440,
      width: screenW,
      child: Stack(
        fit: StackFit.expand,
        children: [
          coverUrl.isNotEmpty
              ? Image.network(coverUrl, fit: BoxFit.cover)
              : Image.asset(
                  'assets/images/ha_long_bay_sailing.jpg',
                  fit: BoxFit.cover,
                ),
          // Layered Atmospheric Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2),
                  const Color(0xFF1B2321).withOpacity(0.4),
                  const Color(0xFF1B2321).withOpacity(0.9),
                  const Color(0xFF1B2321),
                ],
                stops: const [0.0, 0.4, 0.85, 1.0],
              ),
            ),
          ),
          // Soft Top Ambient Glow
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [
                    const Color(0xFFD4AF7A).withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
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
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF7A).withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD4AF7A).withOpacity(0.3)),
            ),
            child: const Icon(Icons.phone_android_rounded, color: Color(0xFFD4AF7A), size: 32),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Số Điện Thoại',
          style: TextStyle(fontFamily: 'Montserrat', fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1),
        ),
        const SizedBox(height: 8),
        Text(
          'Bảo mật tài khoản và xác thực danh tính qua số điện thoại',
          style: TextStyle(fontFamily: 'Montserrat', fontSize: 14, color: Colors.white.withOpacity(0.6), height: 1.5),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(fontFamily: 'Montserrat', fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFD4AF7A), letterSpacing: 1.5),
    );
  }

  Widget _buildCurrentPhoneCard() {
    final String currentPhone = widget.userData['phone'] ?? '';
    final bool hasPhone = currentPhone.isNotEmpty;

    return _buildGlassCard(
      child: hasPhone 
          ? Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(currentPhone, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
                      const SizedBox(height: 4),
                      const Text('Đã xác thực bảo mật', style: TextStyle(color: Color(0xFF2ECC71), fontSize: 12, fontFamily: 'Montserrat')),
                    ],
                  ),
                ),
                FadeTransition(
                  opacity: _pulseController,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2ECC71).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF2ECC71).withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: Color(0xFF2ECC71), size: 16),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Icon(Icons.phone_disabled_rounded, color: Colors.white.withOpacity(0.2), size: 48),
                const SizedBox(height: 16),
                const Text('Chưa có số điện thoại', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Thêm số điện thoại để tăng cường bảo mật tài khoản', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
              ],
            ),
    );
  }

  Widget _buildChangePhoneCard() {
    return _buildGlassCard(
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _showCountryPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      Text(_selectedCountryCode, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFFD4AF7A)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Nhập số điện thoại mới',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isVerifying ? null : _handleSendCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.08),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withOpacity(0.1))),
                elevation: 0,
              ),
              child: _isVerifying
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : const Text('Gửi mã xác thực', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpSection() {
    return _buildGlassCard(
      child: Column(
        children: [
          const Text('Nhập mã 6 chữ số đã được gửi tới số điện thoại của bạn', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(6, (index) => _buildOtpBox(index))),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_resendTimer > 0 ? 'Gửi lại mã sau ${_resendTimer}s' : 'Không nhận được mã? ', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
              if (_resendTimer == 0)
                GestureDetector(onTap: _startResendTimer, child: const Text('Gửi lại ngay', style: TextStyle(color: Color(0xFFD4AF7A), fontWeight: FontWeight.bold, fontSize: 13))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return Container(
      width: 45, height: 55,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _otpControllers[index].text.isNotEmpty ? const Color(0xFFD4AF7A) : Colors.white.withOpacity(0.1), width: 1),
      ),
      child: TextField(
        controller: _otpControllers[index], focusNode: _otpFocusNodes[index],
        textAlign: TextAlign.center, keyboardType: TextInputType.number, maxLength: 1,
        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(counterText: '', border: InputBorder.none),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) _otpFocusNodes[index + 1].requestFocus();
          else if (value.isEmpty && index > 0) _otpFocusNodes[index - 1].requestFocus();
          setState(() {});
        },
      ),
    );
  }

  Widget _buildSecurityNoticeCard() {
    return _buildGlassCard(
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFD4AF7A).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.shield_outlined, color: Color(0xFFD4AF7A), size: 24)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Lưu ý bảo mật', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text('Số điện thoại giúp khôi phục tài khoản và xác minh các giao dịch quan trọng của bạn.', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, height: 1.4)),
          ])),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Container(
          width: double.infinity, height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(colors: [Color(0xFFD4AF7A), Color(0xFFB5956A)]),
            boxShadow: [BoxShadow(color: const Color(0xFFD4AF7A).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: ElevatedButton(
            onPressed: () {
              _showToast('Đang cập nhật thay đổi...');
              Future.delayed(const Duration(milliseconds: 1500), () {
                _showToast('Cập nhật Số điện thoại thành công!');
                Navigator.pop(context, true);
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
            child: const Text('Lưu thay đổi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1B2321))),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Hủy bỏ', style: TextStyle(color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.bold))),
      ],
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.1))),
          child: child,
        ),
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
            width: 48, height: 48,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(0.25))),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}
