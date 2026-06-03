import 'dart:ui';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import '../api/api.dart';
import '../services/discord_auth_service.dart';
import '../services/google_auth_service.dart';
import '../utils/auth_feedback.dart';
import '../utils/auth_storage.dart';
import '../widgets/anim_builder.dart';
import 'sign_in.dart';
import 'dashboard.dart';
import 'landing_page.dart';

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

  bool get _supportsNativeSocialAuth {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  void _showUnsupportedSocialLogin(String provider) {
    showAuthErrorToast(
      context,
      '$provider chưa hỗ trợ trên Linux/Windows desktop. Hãy test bằng Chrome, Android, iOS hoặc macOS.',
    );
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^0\d{9}$');
    return phoneRegex.hasMatch(phone);
  }

  bool _isValidPassword(String password) {
    return password.length >= 8;
  }

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

    if (!_isValidEmail(email)) {
      showAuthErrorToast(
        context,
        'Vui lòng nhập email hợp lệ (ví dụ: abc@gmail.com)',
      );
      return;
    }

    if (phone.isNotEmpty && !_isValidPhone(phone)) {
      showAuthErrorToast(
        context,
        'Vui lòng nhập số điện thoại hợp lệ (10 chữ số, bắt đầu với 0)',
      );
      return;
    }

    if (!_isValidPassword(password)) {
      showAuthErrorToast(context, 'Mật khẩu phải có ít nhất 8 ký tự');
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
        final authToken = data?['token'] as String?;
        if (authToken != null && authToken.trim().isNotEmpty) {
          await AuthStorage.saveSession(
            token: authToken,
            userName: name,
          );
          if (!mounted) return;
        }

        showAuthSuccessToast(
          context,
          msg ?? 'Đăng ký thành công! Chào mừng bạn!',
        );
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => HomeScreen(
                userName: name,
                authToken: authToken,
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
        msg ?? 'Đăng ký thất bại — kiểm tra email/SĐT đã tồn tại chưa.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showAuthErrorToast(
        context,
        'Không kết nối được server. Đã bật backend chưa? ($e)',
      );
    }
  }

  Future<void> _loginWithGoogleIdToken(
    String idToken, {
    bool loadingAlreadySet = false,
  }) async {
    if (_isLoading && !loadingAlreadySet) return;

    if (!loadingAlreadySet) {
      setState(() => _isLoading = true);
    }

    try {
      final response = await apiPostJson('/auth/google', {
        'idToken': idToken,
      });

      if (!mounted) return;
      setState(() => _isLoading = false);

      final data = tryDecodeJsonObject(response.body);
      final msg = data?['message'] as String?;

      if (response.statusCode == 200 && data?['success'] == true) {
        final user = data?['user'];
        final userName = user is Map ? user['name'] as String? : null;
        final authToken = data?['token'] as String?;
        if (authToken != null && authToken.trim().isNotEmpty) {
          await AuthStorage.saveSession(
            token: authToken,
            userName: userName ?? 'bạn',
          );
          if (!mounted) return;
        }

        showAuthSuccessToast(
          context,
          msg ?? 'Đăng nhập Google thành công!',
        );

        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => HomeScreen(
              userName: userName ?? 'bạn',
              authToken: authToken,
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
        return;
      }

      showAuthErrorToast(context, msg ?? 'Đăng nhập Google thất bại');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showAuthErrorToast(context, 'Đăng nhập Google thất bại ($e)');
    }
  }

  void _handleGoogleLogin() async {
    if (!_supportsNativeSocialAuth) {
      _showUnsupportedSocialLogin('Google login');
      return;
    }

    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final idToken = await GoogleAuthService.signInAndGetIdToken();
      if (!mounted) return;

      if (idToken == null) {
        setState(() => _isLoading = false);
        return;
      }

      await _loginWithGoogleIdToken(idToken, loadingAlreadySet: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showAuthErrorToast(context, 'Đăng nhập Google thất bại ($e)');
    }
  }

  void _handleDiscordLogin() async {
    if (!kIsWeb) {
      _showUnsupportedSocialLogin('Discord login');
      return;
    }

    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final oauthResult = await DiscordAuthService.signInAndGetAuthorizationCode();
      if (!mounted) return;

      if (oauthResult == null) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await apiPostJson('/auth/discord', {
        'code': oauthResult['code'],
        'redirectUri': oauthResult['redirectUri'],
      });

      if (!mounted) return;
      setState(() => _isLoading = false);

      final data = tryDecodeJsonObject(response.body);
      final msg = data?['message'] as String?;

      if (response.statusCode == 200 && data?['success'] == true) {
        final user = data?['user'];
        final userName = user is Map ? user['name'] as String? : null;
        final authToken = data?['token'] as String?;
        if (authToken != null && authToken.trim().isNotEmpty) {
          await AuthStorage.saveSession(
            token: authToken,
            userName: userName ?? 'bạn',
          );
          if (!mounted) return;
        }

        showAuthSuccessToast(
          context,
          msg ?? 'Đăng nhập Discord thành công!',
        );

        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => HomeScreen(
              userName: userName ?? 'bạn',
              authToken: authToken,
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
        return;
      }

      showAuthErrorToast(context, msg ?? 'Đăng nhập Discord thất bại');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showAuthErrorToast(context, 'Đăng nhập Discord thất bại ($e)');
    }
  }

  // ── Animations ──
  late final AnimationController _entranceController;
  late final Animation<double> _headerFade;
  late final Animation<double> _panelSlide;
  late final Animation<double> _contentFade;

  // Sheet controller for parallax
  final DraggableScrollableController _sheetCtrl =
      DraggableScrollableController();
  double _sheetFraction = 0.72;

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
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _entranceController.dispose();
    _sheetCtrl.removeListener(_onSheetChanged);
    _sheetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final isDesktop = screenW >= 800;
    final contentW = screenW > 600 ? 500.0 : screenW;
    final s = contentW / 412;

    if (isDesktop) {
      return Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // Background
            _buildHeroImage(s),

            // Back button
            _buildBackButton(),

            // Centered form card
            Center(
              child: Container(
                width: 480,
                margin: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.50),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(36),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Title
                          Center(
                            child: Text(
                              'Tạo tài khoản',
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w400,
                                fontSize: 32,
                                letterSpacing: 0.175,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Fields
                          _buildField(
                            label: 'Họ tên',
                            hint: 'Nguyen Van A',
                            controller: _nameController,
                            s: 1.0,
                          ),
                          const SizedBox(height: 14),

                          _buildField(
                            label: 'Số điện thoại (Không bắt buộc)',
                            hint: '0123456789',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            s: 1.0,
                          ),
                          const SizedBox(height: 14),

                          _buildField(
                            label: 'Địa chỉ Email',
                            hint: 'abc@gmail.com',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            s: 1.0,
                          ),
                          const SizedBox(height: 14),

                          _buildField(
                            label: 'Mật khẩu',
                            hint: 'abc123',
                            controller: _passwordController,
                            isPassword: true,
                            obscure: _obscurePassword,
                            onToggleObscure: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            s: 1.0,
                          ),
                          const SizedBox(height: 14),

                          _buildField(
                            label: 'Xác nhận mật khẩu',
                            hint: 'abc123',
                            controller: _confirmController,
                            isPassword: true,
                            obscure: _obscureConfirm,
                            onToggleObscure: () =>
                                setState(() => _obscureConfirm = !_obscureConfirm),
                            s: 1.0,
                          ),
                          const SizedBox(height: 16),

                          // Terms text
                          const Text(
                            'Bằng việc tiếp tục, bạn đồng ý với Điều khoản dịch vụ của TourXport và Chính sách quyền riêng tư.',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w300,
                              fontSize: 12,
                              letterSpacing: 0.12,
                              color: Colors.white,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Register button
                          _buildRegisterButton(1.0),
                          const SizedBox(height: 24),

                          // Divider
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withOpacity(0.4),
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  'Hoặc',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.w400,
                                    fontSize: 14,
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
                          const SizedBox(height: 16),

                          // Social buttons
                          SizedBox(
                            height: 60,
                            child: Row(
                              children: [
                                _buildSocialBtn(
                                  label: 'Đăng kí với Google',
                                  iconAsset: 'assets/icons/gg_logo.png',
                                  s: 1.0,
                                  onTap: _handleGoogleLogin,
                                ),
                                const SizedBox(width: 10),
                                _buildSocialBtn(
                                  label: 'Đăng kí với Discord',
                                  iconAsset: 'assets/icons/dc_logo.png',
                                  s: 1.0,
                                  onTap: _handleDiscordLogin,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Login link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Đã có tài khoản? ',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Text(
                                  'Đăng nhập',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: Colors.white,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.white70,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Background image with parallax
          _buildHeroImage(s),

          // ── Draggable panel with green transparent overlay
          _buildDraggablePanel(s),

          // ── Back button (top-left)
          _buildBackButton(),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return SafeArea(
      child: FadeTransition(
        opacity: _headerFade,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: GestureDetector(
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushAndRemoveUntil(
                  context,
                  PageRouteBuilder(
                    // pageBuilder: (_, __, ___) => const LandingPage(),
                    pageBuilder: (_, __, ___) => HomeScreen(
                        userName: "Khách",
                        authToken: null
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
            },
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImage(double s) {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/login_bg.jpg', fit: BoxFit.cover),
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
        initialChildSize: 0.72,
        minChildSize: 0.72,
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
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(36),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: FadeTransition(
                  opacity: _contentFade,
                  child: ListView(
                    controller: scrollCtrl,
                    padding: EdgeInsets.fromLTRB(
                      24 * s,
                      12,
                      24 * s,
                      MediaQuery.viewInsetsOf(context).bottom + 24,
                    ),
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 42,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),

                      // Title
                      Center(
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
                      SizedBox(height: 20 * s),

                      // ── Họ tên
                      _buildField(
                        label: 'Họ tên',
                        hint: 'Nguyen Van A',
                        controller: _nameController,
                        s: s,
                      ),
                      SizedBox(height: 14 * s),

                      // ── Số điện thoại
                      _buildField(
                        label: 'Số điện thoại (Không bắt buộc)',
                        hint: '0123456789',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        s: s,
                      ),
                      SizedBox(height: 14 * s),

                      // ── Địa chỉ Email
                      _buildField(
                        label: 'Địa chỉ Email',
                        hint: 'abc@gmail.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        s: s,
                      ),
                      SizedBox(height: 14 * s),

                      // ── Mật khẩu
                      _buildField(
                        label: 'Mật khẩu',
                        hint: 'abc123',
                        controller: _passwordController,
                        isPassword: true,
                        obscure: _obscurePassword,
                        onToggleObscure: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        s: s,
                      ),
                      SizedBox(height: 14 * s),

                      // ── Xác nhận mật khẩu
                      _buildField(
                        label: 'Xác nhận mật khẩu',
                        hint: 'abc123',
                        controller: _confirmController,
                        isPassword: true,
                        obscure: _obscureConfirm,
                        onToggleObscure: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                        s: s,
                      ),
                      SizedBox(height: 12 * s),

                      // ── Terms text
                      Text(
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
                      SizedBox(height: 16 * s),

                      // ── Đăng ký button
                      _buildRegisterButton(s),
                      SizedBox(height: 20 * s),

                      // ── Divider "Hoặc"
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
                      SizedBox(height: 16 * s),

                      // ── Social buttons
                      SizedBox(
                        height: 70 * s,
                        child: Row(
                          children: [
                            _buildSocialBtn(
                              label: 'Đăng kí với Google',
                              iconAsset: 'assets/icons/gg_logo.png',
                              s: s,
                              onTap: _handleGoogleLogin,
                            ),
                            SizedBox(width: 10 * s),
                            _buildSocialBtn(
                              label: 'Đăng kí với Discord',
                              iconAsset: 'assets/icons/dc_logo.png',
                              s: s,
                              onTap: _handleDiscordLogin,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20 * s),

                      // ── "Đã có tài khoản? Đăng nhập"
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Đã có tài khoản? ',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w400,
                              fontSize: 15 * s,
                              color: Colors.white,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              'Đăng nhập',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w700,
                                fontSize: 15 * s,
                                color: Colors.white,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ),
                        ],
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
        Container(
          height: 50 * s,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
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
                            obscure ? Icons.visibility_off : Icons.visibility,
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
      ],
    );
  }

  // ── Social button widget ──
  Widget _buildSocialBtn({
    required String label,
    required double s,
    String? iconAsset,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : onTap,
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
                if (iconAsset != null)
                  Image.asset(iconAsset, width: 26 * s, height: 26 * s)
                else
                  Icon(icon ?? Icons.login_rounded, size: 26 * s, color: Colors.white),
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

  Widget _buildRegisterButton(double s) {
    return GestureDetector(
      onTap: _isLoading ? null : _handleRegister,
      child: Container(
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
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
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
    );
  }
}
