import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/api.dart';
import '../services/discord_auth_service.dart';
import '../services/google_auth_service.dart';
import '../utils/auth_feedback.dart';
import '../utils/auth_storage.dart';
import '../widgets/anim_builder.dart';
import '../widgets/auth/auth_text_field.dart';
import '../widgets/auth/auth_continue_button.dart';
import '../widgets/auth/social_login_button.dart';
import '../widgets/auth/saved_accounts_dropdown.dart';

import 'dashboard.dart';
import 'landing_page.dart';
import '../utils/formatters.dart';
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
  bool _isSuccess = false;
  bool _isError = false;
  bool _rememberMe = true;
  bool _capsLockOn = false;
  final _inputController = TextEditingController();
  final _inputFocusNode = FocusNode();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  List<Map<String, String>> _savedAccounts = [];
  bool _showSavedAccounts = false;



  Future<void> _loadSavedAccounts() async {
    final accounts = await AuthStorage.getSavedAccounts();
    if (mounted) {
      setState(() {
        _savedAccounts = accounts;
      });
    }
  }

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

  void _shakeFields() {
    _shakeController.forward(from: 0.0);
    setState(() => _isError = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _isError = false);
    });
  }

  void _handleLogin() async {
    final input = _inputController.text.trim();
    final password = _passwordController.text.trim();

    if (input.isEmpty || password.isEmpty) {
      _shakeFields();
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
        final authToken = data?['token'] as String?;
        if (authToken != null && authToken.trim().isNotEmpty) {
          if (_rememberMe) {
            await AuthStorage.saveSession(
              token: authToken,
              userName: userName ?? 'bạn',
            );
            await AuthStorage.saveAccountToHistory(
              emailOrPhone: user is Map ? (user['email'] ?? input) : input,
              name: userName ?? 'bạn',
              avatar: user is Map ? user['avatar'] as String? : null,
            );
          }
          if (!mounted) return;
        }
        showAuthSuccessToast(
          context,
          'Đăng nhập thành công — chào ${userName ?? 'bạn'}!',
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
            _isSuccess = true;
          });
          await Future.delayed(const Duration(milliseconds: 600));
        }

        // Điều hướng tới Dashboard sau khi đăng nhập thành công
        if (mounted) {
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
        }
        return;
      }

      _shakeFields();
      showAuthErrorToast(
        context,
        msg ?? 'Sai thông tin đăng nhập',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _shakeFields();
      showAuthErrorToast(context, 'Không kết nối được server. Đã bật backend chưa? ($e)');
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
          if (_rememberMe) {
            await AuthStorage.saveSession(
              token: authToken,
              userName: userName ?? 'bạn',
            );
            await AuthStorage.saveAccountToHistory(
              emailOrPhone: user is Map ? (user['email'] ?? 'Google Account') : 'Google Account',
              name: userName ?? 'bạn',
              avatar: user is Map ? user['avatar'] as String? : null,
            );
          }
          if (!mounted) return;
        }

        showAuthSuccessToast(
          context,
          'Đăng nhập Google thành công — chào ${userName ?? 'bạn'}!',
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
          if (_rememberMe) {
            await AuthStorage.saveSession(
              token: authToken,
              userName: userName ?? 'bạn',
            );
            await AuthStorage.saveAccountToHistory(
              emailOrPhone: user is Map ? (user['email'] ?? 'Discord Account') : 'Discord Account',
              name: userName ?? 'bạn',
              avatar: user is Map ? user['avatar'] as String? : null,
            );
          }
          if (!mounted) return;
        }

        showAuthSuccessToast(
          context,
          'Đăng nhập Discord thành công — chào ${userName ?? 'bạn'}!',
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
  late final AnimationController _shakeController;

  // Sheet controller for parallax
  final DraggableScrollableController _sheetCtrl = DraggableScrollableController();
  double _sheetFraction = 0.62;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    _checkCapsLock();
    _loadSavedAccounts();

    _inputFocusNode.addListener(() {
      if (_inputFocusNode.hasFocus) {
        setState(() => _showSavedAccounts = true);
      } else {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) setState(() => _showSavedAccounts = false);
        });
      }
    });

    _inputController.addListener(() {
      setState(() {});
    });

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

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

  void _checkCapsLock() {
    final capsOn = HardwareKeyboard.instance.lockModesEnabled.contains(KeyboardLockMode.capsLock);
    if (_capsLockOn != capsOn && mounted) {
      setState(() => _capsLockOn = capsOn);
    }
  }

  bool _handleKeyEvent(KeyEvent event) {
    _checkCapsLock();
    return false;
  }

  void _onSheetChanged() {
    setState(() => _sheetFraction = _sheetCtrl.size);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _inputFocusNode.dispose();
    _passwordFocusNode.dispose();
    _inputController.dispose();
    _passwordController.dispose();
    _entranceController.dispose();
    _shakeController.dispose();
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
            // ── Background image
            _buildHeroImage(s),

            // ── Back button
            _buildBackButton(),

            // ── Centered glassmorphic card for Desktop Web
            Align(
              alignment: const Alignment(0.0, -0.20),
              child: Container(
                width: 480,
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
                              'Đăng nhập',
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w400,
                                fontSize: 32,
                                letterSpacing: 0.35,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Tab bar
                          _buildTabBar(1.0, 480 - 40 * 2),
                          const SizedBox(height: 19),

                          // Fields
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                            child: AuthTextField(shakeAnimation: _shakeController, capsLockOn: _capsLockOn, obscurePassword: _obscurePassword, onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                              key: ValueKey<bool>(_useEmail),
                              label: _useEmail ? 'Địa chỉ Email' : 'Số điện thoại',
                              hint: _useEmail ? 'abc@gmail.com' : '0123456789',
                              controller: _inputController,
                              focusNode: _inputFocusNode,
                              textInputAction: TextInputAction.next,
                              onEditingComplete: () => _passwordFocusNode.requestFocus(),
                              keyboardType: _useEmail
                                  ? TextInputType.emailAddress
                                  : TextInputType.phone,
                              inputFormatters: !_useEmail ? [PhoneNumberFormatter()] : null,
                              s: 1.0,
                            ),
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: (_savedAccounts.isNotEmpty && _showSavedAccounts)
                                ? SavedAccountsDropdown(
      savedAccounts: _savedAccounts,
      s: 1.0,
      onSelectAccount: (acc) {
        setState(() {
          _useEmail = acc['email']!.contains('@');
          _inputController.text = acc['email']!;
          _showSavedAccounts = false;
        });
        _passwordFocusNode.requestFocus();
      },
      onRemoveAccount: (email) async {
        await AuthStorage.removeSavedAccount(email);
        _loadSavedAccounts();
      },
    )
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 16),

                          AuthTextField(shakeAnimation: _shakeController, capsLockOn: _capsLockOn, obscurePassword: _obscurePassword, onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                            key: const ValueKey('password_field_desktop'),
                            label: 'Mật khẩu',
                            hint: '123abc',
                            controller: _passwordController,
                            focusNode: _passwordFocusNode,
                            isPassword: true,
                            textInputAction: TextInputAction.done,
                            onEditingComplete: () => _handleLogin(),
                            s: 1.0,
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => setState(() => _rememberMe = !_rememberMe),
                            child: Row(
                              children: [
                                Theme(
                                  data: Theme.of(context).copyWith(
                                    unselectedWidgetColor: Colors.white54,
                                  ),
                                  child: Checkbox(
                                    value: _rememberMe,
                                    onChanged: (val) {
                                      setState(() {
                                        _rememberMe = val ?? true;
                                      });
                                    },
                                    activeColor: const Color(0xFFD4AF7A),
                                    checkColor: Colors.black,
                                  ),
                                ),
                                Text(
                                  'Ghi nhớ đăng nhập của tôi',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Continue button
                          AuthContinueButton(isLoading: _isLoading, isSuccess: _isSuccess, isError: _isError, onLogin: _handleLogin, s: 1.0),
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
                                  'Đăng nhập bằng',
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
                                SocialLoginButton(isLoading: _isLoading,
                                  label: 'Tiếp tục với Google',
                                  iconAsset: 'assets/icons/gg_logo.png',
                                  s: 1.0,
                                  onTap: _handleGoogleLogin,
                                ),
                                const SizedBox(width: 10),
                                SocialLoginButton(isLoading: _isLoading,
                                  label: 'Tiếp tục với Discord',
                                  iconAsset: 'assets/icons/dc_logo.png',
                                  s: 1.0,
                                  onTap: _handleDiscordLogin,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Sign up link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Bạn chưa có tài khoản? ',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pushReplacementNamed(context, '/signup'),
                                child: const Text(
                                  'Đăng ký',
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
                          const SizedBox(height: 16),

                          // Tagline
                          const Text(
                            '"Hạnh phúc không phải là điểm đến\nmà là cả một hành trình."',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w300,
                              fontSize: 13,
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
                      _buildTabBar(s, MediaQuery.sizeOf(context).width),
                      SizedBox(height: 19 * s),

                      // ── Email / Phone field
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                        child: AuthTextField(shakeAnimation: _shakeController, capsLockOn: _capsLockOn, obscurePassword: _obscurePassword, onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                          key: ValueKey<bool>(_useEmail),
                          label: _useEmail ? 'Địa chỉ Email' : 'Số điện thoại',
                          hint: _useEmail ? 'abc@gmail.com' : '0123456789',
                          controller: _inputController,
                          focusNode: _inputFocusNode,
                          textInputAction: TextInputAction.next,
                          onEditingComplete: () => _passwordFocusNode.requestFocus(),
                          keyboardType: _useEmail
                              ? TextInputType.emailAddress
                              : TextInputType.phone,
                          inputFormatters: !_useEmail ? [PhoneNumberFormatter()] : null,
                          s: s,
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: (_savedAccounts.isNotEmpty && _showSavedAccounts)
                            ? SavedAccountsDropdown(
      savedAccounts: _savedAccounts,
      s: s,
      onSelectAccount: (acc) {
        setState(() {
          _useEmail = acc['email']!.contains('@');
          _inputController.text = acc['email']!;
          _showSavedAccounts = false;
        });
        _passwordFocusNode.requestFocus();
      },
      onRemoveAccount: (email) async {
        await AuthStorage.removeSavedAccount(email);
        _loadSavedAccounts();
      },
    )
                            : const SizedBox.shrink(),
                      ),
                      SizedBox(height: 16 * s),

                      // ── Password field
                      AuthTextField(shakeAnimation: _shakeController, capsLockOn: _capsLockOn, obscurePassword: _obscurePassword, onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                        key: const ValueKey('password_field_mobile'),
                        label: 'Mật khẩu',
                        hint: '123abc',
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        isPassword: true,
                        textInputAction: TextInputAction.done,
                        onEditingComplete: () => _handleLogin(),
                        s: s,
                      ),
                      SizedBox(height: 8 * s),
                      GestureDetector(
                        onTap: () => setState(() => _rememberMe = !_rememberMe),
                        child: Row(
                          children: [
                            Theme(
                              data: Theme.of(context).copyWith(
                                unselectedWidgetColor: Colors.white54,
                              ),
                              child: Checkbox(
                                value: _rememberMe,
                                onChanged: (val) {
                                  setState(() {
                                    _rememberMe = val ?? true;
                                  });
                                },
                                activeColor: const Color(0xFFD4AF7A),
                                checkColor: Colors.black,
                              ),
                            ),
                            Text(
                              'Ghi nhớ đăng nhập của tôi',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 14 * s,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16 * s),

                      // ── Tiếp tục button
                      AuthContinueButton(isLoading: _isLoading, isSuccess: _isSuccess, isError: _isError, onLogin: _handleLogin, s: s),
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
                            SocialLoginButton(isLoading: _isLoading,
                              label: 'Tiếp tục với Google',
                              iconAsset: 'assets/icons/gg_logo.png',
                              s: s,
                              onTap: _handleGoogleLogin,
                            ),
                            SizedBox(width: 10 * s),
                            SocialLoginButton(isLoading: _isLoading,
                              label: 'Tiếp tục với Discord',
                              iconAsset: 'assets/icons/dc_logo.png',
                              s: s,
                              onTap: _handleDiscordLogin,
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
                            onTap: () => Navigator.pushReplacementNamed(context, '/signup'),
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
  Widget _buildTabBar(double s, double containerWidth) {
    final bool isDesktop = MediaQuery.sizeOf(context).width >= 800;
    final double actualWidth = isDesktop ? containerWidth : containerWidth - 48 * s;
    final tabWidth = actualWidth / 2;

    return Center(
      child: SizedBox(
        width: actualWidth,
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
              left: _useEmail ? tabWidth + 5 : 5,
              top: 5,
              width: tabWidth - 10,
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
              width: tabWidth,
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
              left: tabWidth,
              width: tabWidth,
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
      ),
    );
  }

}
