import 'dart:math' show max;

import 'package:flutter/material.dart';
import '../api/api.dart';
import '../utils/auth_feedback.dart';
import '../widgets/anim_builder.dart';
import 'sign_up.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with TickerProviderStateMixin {
  bool _useEmail = true;
  bool _obscurePassword = true;
  bool _isLoading = false;
  final _inputController = TextEditingController();
  final _passwordController = TextEditingController();

  void _handleLogin() async {
    final input = _inputController.text.trim();
    final password = _passwordController.text.trim();

    if (input.isEmpty || password.isEmpty) {
      showAuthErrorToast(context, 'Vui lòng điền đủ thông tin đăng nhập');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> body = {
        'password': password,
        if (_useEmail) 'email': input else 'phone': input,
      };

      final response = await apiPostJson('/auth/login', body);
      if (!mounted) return;
      setState(() => _isLoading = false);

      final data = tryDecodeJsonObject(response.body);
      final msg = data?['message'] as String?;

      if (response.statusCode == 200 && data?['success'] == true) {
        final user = data?['user'];
        final userName = user is Map ? user['name'] as String? : null;
        showAuthSuccessToast(
          context,
          'Đăng nhập thành công — chào ${userName ?? 'bạn'}!',
        );
        // TODO: lưu token (data['token']), điều hướng Dashboard
        return;
      }

      showAuthErrorToast(
        context,
        msg ?? 'Sai thông tin đăng nhập',
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
  late final Animation<double> _tabFade;
  late final Animation<double> _fieldsFade;
  late final Animation<double> _buttonFade;
  late final Animation<double> _socialFade;
  late final Animation<double> _bottomFade;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Panel slides up from bottom
    _panelSlide = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
    );

    // Title
    _titleFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.15, 0.45, curve: Curves.easeOut),
    );

    // Tab bar
    _tabFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.25, 0.55, curve: Curves.easeOut),
    );

    // Input fields
    _fieldsFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.35, 0.65, curve: Curves.easeOut),
    );

    // Button
    _buttonFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.45, 0.75, curve: Curves.easeOut),
    );

    // Social + bottom
    _socialFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.55, 0.85, curve: Curves.easeOut),
    );

    _bottomFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.65, 0.95, curve: Curves.easeOut),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _passwordController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final contentW = screenW > 600 ? 500.0 : screenW;
    final s = contentW / 412;
    // Vị trí thấp nhất ~833*s + tagline 2 dòng — đủ cao để không overflow trên Windows/web
    final minScrollHeight = 920 * s;

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

            // ── Dark overlay panel (animated slide up)
            AnimBuilder(
              animation: _panelSlide,
              builder: (context, child) {
                final slideOffset = (1 - _panelSlide.value) * 100;
                return Positioned(
                  left: 0,
                  right: 0,
                  top: 227 * s + slideOffset,
                  height: 712 * s,
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
                      const Color(0xFF1C302D).withOpacity(0.80),
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

                  // ── Title "Đăng nhập"
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 248 * s,
                    child: FadeTransition(
                      opacity: _titleFade,
                      child: Center(
                        child: Text(
                          'Đăng nhập',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w400,
                            fontSize: 35 * s,
                            letterSpacing: 0.35,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Tab: Điện thoại / Email
                  Positioned(
                    left: 16 * s,
                    right: 16 * s,
                    top: 305 * s,
                    height: 50 * s,
                    child: FadeTransition(
                      opacity: _tabFade,
                      child: Stack(
                        children: [
                          // Nền tối
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(40),
                              ),
                            ),
                          ),
                          // Pill trắng active — animated
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOutCubic,
                            left: _useEmail ? (380 * s / 2) + 5 : 5,
                            top: 5,
                            width: (380 * s / 2) - 5,
                            height: 40 * s,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(40),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Điện thoại label
                          Positioned(
                            left: 0,
                            width: 380 * s / 2,
                            top: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: () => setState(() => _useEmail = false),
                              child: Center(
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18 * s,
                                    color: _useEmail
                                        ? Colors.white
                                        : const Color(0xFF1C302D),
                                  ),
                                  child: const Text('Điện thoại'),
                                ),
                              ),
                            ),
                          ),
                          // Email label
                          Positioned(
                            left: 380 * s / 2,
                            right: 0,
                            top: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: () => setState(() => _useEmail = true),
                              child: Center(
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18 * s,
                                    color: _useEmail
                                        ? const Color(0xFF1C302D)
                                        : Colors.white,
                                  ),
                                  child: const Text('Email'),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Email / Phone field
                  Positioned(
                    left: 16 * s,
                    right: 16 * s,
                    top: 376 * s,
                    height: 79 * s,
                    child: FadeTransition(
                      opacity: _fieldsFade,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                        child: _buildField(
                          key: ValueKey<bool>(_useEmail),
                          label:
                              _useEmail ? 'Địa chỉ Email' : 'Số điện thoại',
                          hint: _useEmail ? 'abc@gmail.com' : '0123456789',
                          controller: _inputController,
                          keyboardType: _useEmail
                              ? TextInputType.emailAddress
                              : TextInputType.phone,
                          bgOpacity: 0.18,
                          s: s,
                        ),
                      ),
                    ),
                  ),

                  // ── Password field
                  Positioned(
                    left: 16 * s,
                    right: 16 * s,
                    top: 469 * s,
                    height: 79 * s,
                    child: FadeTransition(
                      opacity: _fieldsFade,
                      child: _buildField(
                        label: 'Mật khẩu',
                        hint: '123abc',
                        controller: _passwordController,
                        isPassword: true,
                        bgOpacity: 0.18,
                        s: s,
                      ),
                    ),
                  ),

                  // ── Tiếp tục button
                  Positioned(
                    left: 17 * s,
                    right: 17 * s,
                    top: 581 * s,
                    height: 50 * s,
                    child: FadeTransition(
                      opacity: _buttonFade,
                      child: _buildContinueButton(s),
                    ),
                  ),

                  // ── Divider "Đăng nhập bằng"
                  Positioned(
                    left: 16 * s,
                    right: 16 * s,
                    top: 648 * s,
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
                              'Đăng nhập bằng',
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
                    left: 16 * s,
                    right: 16 * s,
                    top: 691 * s,
                    height: 70 * s,
                    child: FadeTransition(
                      opacity: _socialFade,
                      child: Row(
                        children: [
                          _buildSocialBtn(
                            label: 'Tiếp tục với Google',
                            iconAsset: 'assets/icons/gg_logo.png',
                            s: s,
                          ),
                          SizedBox(width: 10 * s),
                          _buildSocialBtn(
                            label: 'Tiếp tục với Facebook',
                            iconAsset: 'assets/icons/fb_logo.png',
                            s: s,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── "Bạn chưa có tài khoản?"
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 782 * s,
                    child: FadeTransition(
                      opacity: _bottomFade,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Bạn chưa có tài khoản? ',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w400,
                              fontSize: 15 * s,
                              color: Colors.white,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (_, __, ___) =>
                                    const SignUpScreen(),
                                transitionDuration:
                                    const Duration(milliseconds: 400),
                                reverseTransitionDuration:
                                    const Duration(milliseconds: 350),
                                transitionsBuilder:
                                    (_, animation, __, child) {
                                  return FadeTransition(
                                    opacity: CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeInOut,
                                    ),
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0.05, 0),
                                        end: Offset.zero,
                                      ).animate(CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOutCubic,
                                      )),
                                      child: child,
                                    ),
                                  );
                                },
                              ),
                            ),
                            child: Text(
                              'Đăng ký',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w700,
                                fontSize: 15 * s,
                                color: Colors.white,
                                decoration: TextDecoration.underline,
                                decorationColor:
                                    Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Tagline
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 833 * s,
                    child: FadeTransition(
                      opacity: _bottomFade,
                      child: Text(
                        '"Hạnh phúc không phải là điểm đến\nmà là cả một hành trình."',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w300,
                          fontSize: 14 * s,
                          letterSpacing: 0.3,
                          color: Colors.white,
                          height: 1.5,
                          // fontStyle: FontStyle.italic,
                        ),
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

  // ── Continue button with hover-like press effect ──
  Widget _buildContinueButton(double s) {
    return GestureDetector(
      onTap: _isLoading ? null : _handleLogin,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
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
          'Tiếp tục',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w500,
            fontSize: 24 * s,
            color: Colors.white.withOpacity(0.9),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // ── Input field widget ──
  Widget _buildField({
    Key? key,
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    required double bgOpacity,
    required double s,
  }) {
    return Column(
      key: key,
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
              color: Colors.white.withOpacity(bgOpacity),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1,
              ),
            ),
            child: TextField(
              controller: controller,
              obscureText: isPassword && _obscurePassword,
              keyboardType: keyboardType,
              textAlignVertical: TextAlignVertical.center,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18 * s,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 18 * s,
                  color: Colors.white.withOpacity(0.5),
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
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              key: ValueKey<bool>(_obscurePassword),
                              color: Colors.white.withOpacity(0.6),
                              size: 22 * s,
                            ),
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
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