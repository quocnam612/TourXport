import 'dart:ui';
import 'package:flutter/material.dart';
import '../api/api.dart';
import '../utils/auth_feedback.dart';
import '../widgets/anim_builder.dart';
import 'sign_up.dart';
import 'dashboard.dart';

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
        // Điều hướng tới Dashboard sau khi đăng nhập thành công
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => HomeScreen(
                userName: userName ?? 'bạn',
              ),
              transitionDuration: const Duration(milliseconds: 600),
              reverseTransitionDuration: const Duration(milliseconds: 400),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(
                  opacity: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOut,
                  ),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.05),
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
            (route) => false,
          );
        }
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
  late final Animation<double> _headerFade;
  late final Animation<double> _panelSlide;
  late final Animation<double> _contentFade;

  // Sheet controller for parallax
  final DraggableScrollableController _sheetCtrl = DraggableScrollableController();
  double _sheetFraction = 0.62;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _headerFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );

    _panelSlide = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    );

    _contentFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
    );

    _sheetCtrl.addListener(_onSheetChanged);
    _entranceController.forward();
  }

  void _onSheetChanged() {
    setState(() => _sheetFraction = _sheetCtrl.size);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _passwordController.dispose();
    _entranceController.dispose();
    _sheetCtrl.removeListener(_onSheetChanged);
    _sheetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final contentW = screenW > 600 ? 500.0 : screenW;
    final s = contentW / 412;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Background image with parallax
          _buildHeroImage(s),

          // ── Draggable panel with green transparent overlay
          _buildDraggablePanel(s),
        ],
      ),
    );
  }

  Widget _buildHeroImage(double s) {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/login_bg.jpg',
            fit: BoxFit.cover,
          ),
          // Light blur on the background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Container(color: Colors.transparent),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggablePanel(double s) {
    return AnimatedBuilder(
      animation: _panelSlide,
      builder: (context, child) {
        final screenH = MediaQuery.of(context).size.height;
        final slideOffset = (1 - _panelSlide.value) * screenH;
        return Opacity(
          opacity: _panelSlide.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, slideOffset),
            child: child,
          ),
        );
      },
      child: DraggableScrollableSheet(
        controller: _sheetCtrl,
        initialChildSize: 0.62,
        minChildSize: 0.62,
        maxChildSize: 0.92,
        builder: (context, scrollCtrl) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.50),
                      Colors.black.withOpacity(0.55),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                  border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
                  ),
                ),
                child: FadeTransition(
                  opacity: _contentFade,
                  child: ListView(
                    controller: scrollCtrl,
                    padding: EdgeInsets.fromLTRB(24 * s, 12, 24 * s, MediaQuery.viewInsetsOf(context).bottom + 24),
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 42, height: 5,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),

                      // Title
                      Center(
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
                      SizedBox(height: 24 * s),

                      // ── Tab: Điện thoại / Email
                      _buildTabBar(s),
                      SizedBox(height: 24 * s),

                      // ── Email / Phone field
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                        child: _buildField(
                          key: ValueKey<bool>(_useEmail),
                          label: _useEmail ? 'Địa chỉ Email' : 'Số điện thoại',
                          hint: _useEmail ? 'abc@gmail.com' : '0123456789',
                          controller: _inputController,
                          keyboardType: _useEmail
                              ? TextInputType.emailAddress
                              : TextInputType.phone,
                          s: s,
                        ),
                      ),
                      SizedBox(height: 16 * s),

                      // ── Password field
                      _buildField(
                        label: 'Mật khẩu',
                        hint: '123abc',
                        controller: _passwordController,
                        isPassword: true,
                        s: s,
                      ),
                      SizedBox(height: 28 * s),

                      // ── Tiếp tục button
                      _buildContinueButton(s),
                      SizedBox(height: 24 * s),

                      // ── Divider "Đăng nhập bằng"
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.white.withOpacity(0.4),
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10 * s),
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
                      SizedBox(height: 16 * s),

                      // ── Social buttons
                      SizedBox(
                        height: 70 * s,
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
                      SizedBox(height: 20 * s),

                      // ── "Bạn chưa có tài khoản?"
                      Row(
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
                      SizedBox(height: 16 * s),

                      // ── Tagline
                      Text(
                        '"Hạnh phúc không phải là điểm đến\nmà là cả một hành trình."',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w300,
                          fontSize: 14 * s,
                          letterSpacing: 0.3,
                          color: Colors.white,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Tab bar ──
  Widget _buildTabBar(double s) {
    return SizedBox(
      height: 50 * s,
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
            left: _useEmail ? (MediaQuery.sizeOf(context).width - 48 * s) / 2 + 5 : 5,
            top: 5,
            width: (MediaQuery.sizeOf(context).width - 48 * s) / 2 - 10,
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
            width: (MediaQuery.sizeOf(context).width - 48 * s) / 2,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
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
            left: (MediaQuery.sizeOf(context).width - 48 * s) / 2,
            right: 0,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
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
    );
  }

  // ── Continue button with hover-like press effect ──
  Widget _buildContinueButton(double s) {
    return GestureDetector(
      onTap: _isLoading ? null : _handleLogin,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 50 * s,
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
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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
        Container(
          height: 50 * s,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
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
              contentPadding: EdgeInsets.only(
                left: 20 * s,
                right: 20 * s,
                top: 12 * s,
                bottom: 16 * s,
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