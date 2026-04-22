import 'dart:math' show max;

import 'package:flutter/material.dart';
import '../api/api.dart';
import '../utils/auth_feedback.dart';
import '../widgets/anim_builder.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with TickerProviderStateMixin {
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;

  void _handleRegister() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      showAuthErrorToast(context, 'Vui lòng điền đủ các trường bắt buộc');
      return;
    }
    if (password != confirm) {
      showAuthErrorToast(context, 'Mật khẩu xác nhận không khớp');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await apiPostJson('/auth/register', {
        'name': name,
        'email': email,
        if (phone.isNotEmpty) 'phone': phone,
        'password': password,
      });

      if (!mounted) return;
      setState(() => _isLoading = false);

      final data = tryDecodeJsonObject(response.body);
      final msg = data?['message'] as String?;
      final ok = (response.statusCode == 200 || response.statusCode == 201) &&
          data?['success'] == true;

      if (ok) {
        showAuthSuccessToast(
          context,
          msg ?? 'Đăng ký thành công! Bạn có thể quay lại đăng nhập.',
        );
        return;
      }

      showAuthErrorToast(
        context,
        msg ?? 'Đăng ký thất bại — kiểm tra email/SĐT đã tồn tại chưa.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showAuthErrorToast(context, 'Không kết nối được server. Đã bật backend chưa? ($e)');
    }
  }

  // ── Animations ──
  late final AnimationController _entranceController;
  late final Animation<double> _panelSlide;
  late final Animation<double> _titleFade;
  late final Animation<double> _field1Fade;
  late final Animation<double> _field2Fade;
  late final Animation<double> _field3Fade;
  late final Animation<double> _field4Fade;
  late final Animation<double> _field5Fade;
  late final Animation<double> _termsFade;
  late final Animation<double> _buttonFade;
  late final Animation<double> _socialFade;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Panel slides up
    _panelSlide = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOutCubic),
    );

    _titleFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.10, 0.35, curve: Curves.easeOut),
    );

    // Staggered fields
    _field1Fade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.15, 0.40, curve: Curves.easeOut),
    );
    _field2Fade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.22, 0.47, curve: Curves.easeOut),
    );
    _field3Fade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.29, 0.54, curve: Curves.easeOut),
    );
    _field4Fade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.36, 0.61, curve: Curves.easeOut),
    );
    _field5Fade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.43, 0.68, curve: Curves.easeOut),
    );

    _termsFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.50, 0.75, curve: Curves.easeOut),
    );

    _buttonFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.57, 0.82, curve: Curves.easeOut),
    );

    _socialFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.65, 0.95, curve: Curves.easeOut),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final contentW = screenW > 600 ? 500.0 : screenW;
    final s = contentW / 412;
    // Khối thấp nhất ~802*s + 70*s + lề — tránh overflow trên Windows/web
    final minScrollHeight = 940 * s;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Background image
            Positioned.fill(
              child: Image.asset(
                'assets/images/login_bg.jpg',
                fit: BoxFit.cover,
              ),
            ),

            // ── Overlay gradient (animated)
            AnimBuilder(
              animation: _panelSlide,
              builder: (context, child) {
                final slideOffset = (1 - _panelSlide.value) * 80;
                return Positioned(
                  left: 0,
                  right: 0,
                  top: 107 * s + slideOffset,
                  height: 832 * s,
                  child: Opacity(
                    opacity: _panelSlide.value.clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF1C302D).withOpacity(0.55),
                      const Color(0xFF1C302D).withOpacity(0.82),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
              ),
            ),

            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final viewportH = constraints.maxHeight;
                  final scrollContentH = max(minScrollHeight, viewportH);
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.viewInsetsOf(context).bottom + 12,
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: contentW,
                        height: scrollContentH,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                  // ── Title "Tạo tài khoản"
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 123 * s,
                    child: FadeTransition(
                      opacity: _titleFade,
                      child: Center(
                        child: Text(
                          'Tạo tài khoản',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w400,
                            fontSize: 35 * s,
                            letterSpacing: 0.175,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Họ tên
                  Positioned(
                    left: 14 * s,
                    right: 14 * s,
                    top: 164 * s,
                    height: 79 * s,
                    child: FadeTransition(
                      opacity: _field1Fade,
                      child: _buildField(
                        label: 'Họ tên',
                        hint: 'Nguyen Van A',
                        controller: _nameController,
                        s: s,
                      ),
                    ),
                  ),

                  // ── Số điện thoại
                  Positioned(
                    left: 16 * s,
                    right: 16 * s,
                    top: 261 * s,
                    height: 79 * s,
                    child: FadeTransition(
                      opacity: _field2Fade,
                      child: _buildField(
                        label: 'Số điện thoại (Không bắt buộc)',
                        hint: '0123456789',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        s: s,
                      ),
                    ),
                  ),

                  // ── Địa chỉ Email
                  Positioned(
                    left: 16 * s,
                    right: 16 * s,
                    top: 358 * s,
                    height: 79 * s,
                    child: FadeTransition(
                      opacity: _field3Fade,
                      child: _buildField(
                        label: 'Địa chỉ Email',
                        hint: 'abc@gmail.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        s: s,
                      ),
                    ),
                  ),

                  // ── Mật khẩu
                  Positioned(
                    left: 14 * s,
                    right: 14 * s,
                    top: 457 * s,
                    height: 79 * s,
                    child: FadeTransition(
                      opacity: _field4Fade,
                      child: _buildField(
                        label: 'Mật khẩu',
                        hint: 'abc123',
                        controller: _passwordController,
                        isPassword: true,
                        obscure: _obscurePassword,
                        onToggleObscure: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                        s: s,
                      ),
                    ),
                  ),

                  // ── Xác nhận mật khẩu
                  Positioned(
                    left: 16 * s,
                    right: 16 * s,
                    top: 555 * s,
                    height: 79 * s,
                    child: FadeTransition(
                      opacity: _field5Fade,
                      child: _buildField(
                        label: 'Xác nhận mật khẩu',
                        hint: 'abc123',
                        controller: _confirmController,
                        isPassword: true,
                        obscure: _obscureConfirm,
                        onToggleObscure: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                        s: s,
                      ),
                    ),
                  ),

                  // ── Terms text
                  Positioned(
                    left: 24 * s,
                    right: 24 * s,
                    top: 650 * s,
                    child: FadeTransition(
                      opacity: _termsFade,
                      child: Text(
                        'Bằng việc tiếp tục, bạn đồng ý với Điều khoản dịch vụ của TourXport và Chính sách quyền riêng tư.',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w300,
                          fontSize: 12 * s,
                          letterSpacing: 0.12,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),

                  // ── Đăng ký button
                  Positioned(
                    left: 14 * s,
                    right: 14 * s,
                    top: 694 * s,
                    height: 50 * s,
                    child: FadeTransition(
                      opacity: _buttonFade,
                      child: GestureDetector(
                        onTap: _isLoading ? null : _handleRegister,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: _isLoading 
                            ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                            'Đăng ký',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w500,
                              fontSize: 24 * s,
                              color: Colors.white.withOpacity(0.9),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Divider "Hoặc"
                  Positioned(
                    left: 16 * s,
                    right: 16 * s,
                    top: 759 * s,
                    child: FadeTransition(
                      opacity: _socialFade,
                      child: Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.white.withOpacity(0.4),
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding:
                                EdgeInsets.symmetric(horizontal: 10 * s),
                            child: Text(
                              'Hoặc',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w400,
                                fontSize: 15 * s,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.white.withOpacity(0.4),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Social buttons
                  Positioned(
                    left: 10 * s,
                    right: 10 * s,
                    top: 802 * s,
                    height: 70 * s,
                    child: FadeTransition(
                      opacity: _socialFade,
                      child: Row(
                        children: [
                          _buildSocialBtn(
                            label: 'Đăng kí với Google',
                            iconAsset: 'assets/icons/gg_logo.png',
                            s: s,
                          ),
                          SizedBox(width: 10 * s),
                          _buildSocialBtn(
                            label: 'Đăng kí với Facebook',
                            iconAsset: 'assets/icons/fb_logo.png',
                            s: s,
                          ),
                        ],
                      ),
                    ),
                  ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Input field widget ──
  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
    bool obscure = true,
    VoidCallback? onToggleObscure,
    TextInputType keyboardType = TextInputType.text,
    required double s,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w400,
            fontSize: 16 * s,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 6 * s),
        // Input box
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1,
              ),
            ),
            child: TextField(
              controller: controller,
              obscureText: isPassword && obscure,
              keyboardType: keyboardType,
              textAlignVertical: TextAlignVertical.center,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18 * s,
                color: Colors.white,
                height: 1.2,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 18 * s,
                  color: Colors.white.withOpacity(0.5),
                  height: 1.2,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20 * s,
                  vertical: 14 * s,
                ),
                border: InputBorder.none,
                suffixIcon: isPassword
                    ? Padding(
                        padding: EdgeInsets.only(right: 8 * s),
                        child: IconButton(
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (child, animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: child,
                              );
                            },
                            child: Icon(
                              obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              key: ValueKey<bool>(obscure),
                              color: Colors.white.withOpacity(0.6),
                              size: 22 * s,
                            ),
                          ),
                          onPressed: onToggleObscure,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Social button widget ──
  Widget _buildSocialBtn({
    required String label,
    required String iconAsset,
    required double s,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.white.withOpacity(0.05),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(iconAsset, width: 26 * s, height: 26 * s),
                SizedBox(height: 4 * s),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w300,
                    fontSize: 13 * s,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}