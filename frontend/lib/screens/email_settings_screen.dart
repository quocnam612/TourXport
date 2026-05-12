import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

class EmailSettingsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String authToken;

  const EmailSettingsScreen({
    super.key,
    required this.userData,
    required this.authToken,
  });

  @override
  State<EmailSettingsScreen> createState() => _EmailSettingsScreenState();
}

class _EmailSettingsScreenState extends State<EmailSettingsScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  
  final TextEditingController _emailController = TextEditingController();
  
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
    _emailController.dispose();
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
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      _showToast('Vui lòng nhập email hợp lệ', isError: true);
      return;
    }
    setState(() {
      _isVerifying = true;
    });
    
    // Simulate API call
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isVerifying = false;
        _showOtpSection = true;
      });
      _startResendTimer();
      _showToast('Mã xác thực đã được gửi đến email của bạn');
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
          // Background Hero Image
          _buildHeroBackground(),
          
          // Main Content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
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
                        _buildSectionLabel('Email hiện tại'),
                        const SizedBox(height: 12),
                        _buildCurrentEmailCard(),
                        const SizedBox(height: 32),
                        _buildSectionLabel('Thay đổi Email'),
                        const SizedBox(height: 12),
                        _buildChangeEmailCard(),
                        if (_showOtpSection) ...[
                          const SizedBox(height: 32),
                          _buildSectionLabel('Xác thực mã OTP'),
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

          // Custom Back Button (Matching Profile Style)
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

  Widget _buildSliverAppBar() {
    return const SliverAppBar(
      expandedHeight: 140,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: SizedBox.shrink(),
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
            child: const Icon(Icons.alternate_email_rounded, color: Color(0xFFD4AF7A), size: 32),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Cài đặt Email',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Quản lý địa chỉ email và bảo mật tài khoản của bạn',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            color: Colors.white.withOpacity(0.6),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: Color(0xFFD4AF7A),
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildCurrentEmailCard() {
    final String currentEmail = widget.userData['email'] ?? 'chua_cap_nhat@example.com';
    final bool isVerified = widget.userData['isVerified'] ?? true; // Mocked

    return _buildGlassCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentEmail,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Montserrat',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isVerified ? 'Đã xác thực bảo mật' : 'Chưa xác thực email',
                  style: TextStyle(
                    color: isVerified ? const Color(0xFF2ECC71).withOpacity(0.8) : Colors.orangeAccent,
                    fontSize: 12,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ],
            ),
          ),
          if (isVerified)
            FadeTransition(
              opacity: _pulseController,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2ECC71).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF2ECC71).withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_user_rounded, color: Color(0xFF2ECC71), size: 14),
                    SizedBox(width: 4),
                    Text(
                      'XÁC THỰC',
                      style: TextStyle(color: Color(0xFF2ECC71), fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            )
          else
            TextButton(
              onPressed: () {},
              child: const Text('Gửi lại mã', style: TextStyle(color: Color(0xFFD4AF7A), fontSize: 12, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildChangeEmailCard() {
    return _buildGlassCard(
      child: Column(
        children: [
          _buildPremiumInput(
            controller: _emailController,
            label: 'Email mới',
            icon: Icons.mark_email_read_outlined,
            hint: 'Nhập địa chỉ email mới',
            keyboardType: TextInputType.emailAddress,
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                elevation: 0,
              ),
              child: _isVerifying
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : const Text('Gửi mã xác thực', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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
          const Text(
            'Nhập mã 6 chữ số đã được gửi tới email mới',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) => _buildOtpBox(index)),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _resendTimer > 0 ? 'Gửi lại mã sau ${_resendTimer}s' : 'Không nhận được mã? ',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
              ),
              if (_resendTimer == 0)
                GestureDetector(
                  onTap: _startResendTimer,
                  child: const Text(
                    'Gửi lại ngay',
                    style: TextStyle(color: Color(0xFFD4AF7A), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return Container(
      width: 45,
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _otpControllers[index].text.isNotEmpty 
              ? const Color(0xFFD4AF7A) 
              : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(counterText: '', border: InputBorder.none),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _otpFocusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _otpFocusNodes[index - 1].requestFocus();
          }
          setState(() {});
        },
      ),
    );
  }

  Widget _buildSecurityNoticeCard() {
    return _buildGlassCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF7A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shield_outlined, color: Color(0xFFD4AF7A), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lưu ý bảo mật',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Email này được dùng để khôi phục mật khẩu và nhận các thông báo bảo mật quan trọng.',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFFD4AF7A), Color(0xFFB5956A)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF7A).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              _showToast('Đang cập nhật thay đổi...');
              Future.delayed(const Duration(milliseconds: 1500), () {
                _showToast('Cập nhật Email thành công!');
                Navigator.pop(context, true);
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: const Text(
              'Lưu thay đổi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1B2321), letterSpacing: 0.5),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Hủy bỏ',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
        ),
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
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildPremiumInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
              prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.5), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}
