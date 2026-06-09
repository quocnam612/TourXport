import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../api/api.dart';
import '../theme/app_colors.dart';
import '../utils/auth_storage.dart';
import '../widgets/anim_builder.dart';
import '../widgets/responsive_builder.dart';
import '../models/destination.dart';
import 'sign_in.dart';
import 'sign_up.dart';
import 'dashboard.dart';

class LandingPage extends StatefulWidget {
  final String? authToken;
  final String? userName;

  const LandingPage({
    super.key,
    this.authToken,
    this.userName,
  });

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  // ── Animation controllers ──
  late final AnimationController _fadeController;
  late final AnimationController _shimmerController;
  late final AnimationController _buttonPulseController;

  // ── Background Fade Controllers ──
  int _currentIndex = 0;
  String _currentBgPath = 'assets/images/halong.jpg';
  String _previousBgPath = 'assets/images/halong.jpg';
  late final AnimationController _bgFadeController;
  late final Animation<double> _bgFade;

  // ── Individual element animations ──
  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _buttonFade;
  late final Animation<Offset> _buttonSlide;
  String? _storedAuthToken;
  String? _storedUserName;
  bool _isRestoringSession = true;

  Timer? _carouselTimer;

  bool get hasSession {
    return !_isRestoringSession &&
        _storedAuthToken != null &&
        _storedAuthToken!.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();

    // Initial Active Showcase Values
    _currentBgPath = sampleDestinations[0].imagePath;
    _previousBgPath = sampleDestinations[0].imagePath;

    _bgFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bgFade = CurvedAnimation(
      parent: _bgFadeController,
      curve: Curves.easeInOut,
    );
    _bgFadeController.forward(from: 1.0);

    // Main staggered entrance – 1.8s total
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Shimmer loop on background
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    // Subtle button pulse
    _buttonPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // ── Logo: 0 → 35%
    _logoFade = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOutCubic),
    ));

    // ── Title: 15% → 50%
    _titleFade = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.15, 0.50, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.15, 0.50, curve: Curves.easeOutCubic),
    ));

    // ── Subtitle: 30% → 65%
    _subtitleFade = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.30, 0.65, curve: Curves.easeOut),
    );
    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.30, 0.65, curve: Curves.easeOutCubic),
    ));

    // ── Button: 45% → 80%
    _buttonFade = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.45, 0.80, curve: Curves.easeOut),
    );
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.45, 0.80, curve: Curves.easeOutCubic),
    ));

    // Fire entrance
    _fadeController.forward();
    _restoreSession();
    _startCarouselTimer();
  }

  void _startCarouselTimer() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final nextIdx = (_currentIndex + 1) % sampleDestinations.length;
      _selectDestination(nextIdx, userInitiated: false);
    });
  }

  Future<void> _restoreSession() async {
    String? token = widget.authToken?.trim().isNotEmpty == true
        ? widget.authToken!.trim()
        : await AuthStorage.getToken();
    String? userName = widget.userName?.trim().isNotEmpty == true
        ? widget.userName!.trim()
        : await AuthStorage.getUserName();

    if (token != null && token.isNotEmpty) {
      try {
        final response = await apiGet(
          '/auth/profile',
          token: token,
          handleUnauthorized: false,
        ).timeout(const Duration(seconds: 8));
        final body = tryDecodeJsonObject(response.body);
        if (response.statusCode == 200 && body?['success'] == true) {
          final user = body?['user'];
          if (user is Map && user['name'] is String) {
            userName = (user['name'] as String).trim();
          }
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          await AuthStorage.clearSession();
          token = null;
          userName = null;
        } else {
          token = null;
          userName = null;
        }
      } catch (_) {
        token = null;
        userName = null;
      }
    }

    if (!mounted) return;
    setState(() {
      _storedAuthToken = token;
      _storedUserName = userName;
      _isRestoringSession = false;
    });
  }


  @override
  void dispose() {
    _carouselTimer?.cancel();
    _bgFadeController.dispose();
    _fadeController.dispose();
    _shimmerController.dispose();
    _buttonPulseController.dispose();
    super.dispose();
  }

  void _selectDestination(int index, {bool userInitiated = true}) {
    if (index == _currentIndex) return;
    
    if (userInitiated) {
      _startCarouselTimer(); // Reset timer if user interacts
    }
    
    final nextPath = sampleDestinations[index].imagePath;
    setState(() {
      _previousBgPath = _currentBgPath;
      _currentBgPath = nextPath;
      _currentIndex = index;
    });
    _bgFadeController.forward(from: 0);
  }

  int _findFirstIndexForCategory(String category) {
    final list = sampleDestinations;
    for (int i = 0; i < list.length; i++) {
      final d = list[i];
      final prov = d.province.toLowerCase();
      final name = d.name.toLowerCase();
      if (category == 'vịnh biển') {
        if (prov.contains('quảng ninh') || prov.contains('khánh hòa') || prov.contains('vũng tàu') || prov.contains('kiên giang') || name.contains('vịnh') || name.contains('biển') || name.contains('đảo')) {
          return i;
        }
      } else if (category == 'núi rừng') {
        if (prov.contains('lào cai') || prov.contains('quảng bình') || prov.contains('sơn la') || prov.contains('hà giang') || name.contains('núi') || name.contains('động') || name.contains('hang') || name.contains('phong nha')) {
          return i;
        }
      } else if (category == 'di sản') {
        if (prov.contains('quảng nam') || prov.contains('huế') || prov.contains('hà nội') || prov.contains('ninh bình') || name.contains('cổ') || name.contains('di tích') || name.contains('tự') || name.contains('lăng') || name.contains('chùa')) {
          return i;
        }
      } else if (category == 'đô thị') {
        if (prov.contains('chí minh') || prov.contains('đà nẵng') || prov.contains('hà nội') || name.contains('tháp') || name.contains('cầu') || name.contains('nhà hát')) {
          return i;
        }
      }
    }
    return -1;
  }

  String _getBriefDescription(Destination dest) {
    final name = dest.name.toLowerCase();
    if (name.contains('hạ long')) {
      return 'Vịnh Hạ Long là di sản thiên nhiên thế giới được UNESCO công nhận, nổi tiếng với hàng nghìn hòn đảo đá vôi kỳ vĩ và làn nước xanh lục bảo thanh bình.';
    } else if (name.contains('hội an')) {
      return 'Phố cổ Hội An là thương cảng cổ xưa được bảo tồn nguyên vẹn, lung linh với ánh đèn lồng rực rỡ và những mái nhà rêu phong hoài cổ bên dòng sông Thu Bồn.';
    } else if (name.contains('đà nẵng') || name.contains('mỹ khê') || name.contains('bà nà')) {
      return 'Đà Nẵng là thành phố biển đáng sống nhất Việt Nam, nơi giao thoa tuyệt vời giữa những cây cầu biểu tượng, bãi cát trắng mịn và đỉnh Bà Nà quanh năm sương mờ.';
    } else if (name.contains('phong nha') || name.contains('kẻ bàng')) {
      return 'Phong Nha - Kẻ Bàng được mệnh danh là vương quốc hang động thế giới, ẩn chứa hệ thống thạch nhũ tráng lệ triệu năm tuổi sâu bên dưới cánh rừng nguyên sinh xanh mướt.';
    } else if (name.contains('hồ chí minh') || name.contains('sài gòn') || name.contains('củ chi')) {
      return 'Thành phố Hồ Chí Minh năng động và sôi động bậc nhất, nơi lịch sử hào hùng hội tụ với nhịp sống hiện đại, tòa tháp chọc trời và các di tích văn hóa độc đáo.';
    } else if (name.contains('hà nội') || name.contains('hoàn kiếm') || name.contains('lăng chủ tịch')) {
      return 'Thủ đô Hà Nội nghìn năm văn hiến, bình yên với Hồ Gươm liễu rủ, phố cổ trầm mặc, ẩm thực thanh lịch và những di tích lịch sử in đậm dấu ấn thời gian.';
    } else if (name.contains('huế') || name.contains('thiên mụ')) {
      return 'Thừa Thiên Huế mang vẻ đẹp mộng mơ, tĩnh lặng với Đại Nội cổ kính, hệ thống lăng tẩm hoàng gia uy nghiêm soi bóng bên dòng sông Hương thơ mộng.';
    } else if (name.contains('phú quốc') || name.contains('kiên giang')) {
      return 'Đảo ngọc Phú Quốc sở hữu những bãi biển hoang sơ đẹp nhất hành tinh, rạn san hô lộng lẫy và những khu nghỉ dưỡng đẳng cấp thế giới chìm trong hoàng hôn rực rỡ.';
    } else if (name.contains('cát bà') || name.contains('bạch long vĩ')) {
      return 'Cát Bà là hòn đảo ngọc phía Bắc, nổi tiếng với những vịnh biển yên bình xen kẽ dãy núi đá vôi kỳ vĩ và những cánh rừng mưa nhiệt đới trù phú.';
    }
    return '${dest.name} tọa lạc tại ${dest.province}, là điểm đến lý tưởng với phong cảnh hữu tình, mức giá ${dest.price} cực kỳ hấp dẫn cho hành trình khám phá của bạn.';
  }

  void _navigateToSignIn(BuildContext context, bool goToSignUp) {
    final token = _storedAuthToken?.trim();
    if (token != null && token.isNotEmpty) {
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => HomeScreen(
            userName: _storedUserName ?? 'bạn',
            authToken: token,
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

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => goToSignUp ? const SignUpScreen() : const SignInScreen(),
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: const Color(0xFF0C1412),
        body: Stack(
          fit: StackFit.expand,
          children: [
            _buildPreviousBackground(),
            _buildCurrentBackground(),
            _buildGradientOverlay(),
            _buildDesktopUI(context),
          ],
        ),
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildPreviousBackground(),
          _buildCurrentBackground(),
          _buildGradientOverlay(),
          _buildContent(context),
        ],
      ),
    );
  }

  // ── Layout Components ──

  Widget _buildPreviousBackground() {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Destination.buildImage(_previousBgPath),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 0.8, sigmaY: 0.8),
            child: Container(color: Colors.transparent),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentBackground() {
    return Positioned.fill(
      child: AnimBuilder(
        animation: _bgFade,
        builder: (context, child) => Opacity(
          opacity: _bgFade.value,
          child: child,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Destination.buildImage(_currentBgPath),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0.8, sigmaY: 0.8),
              child: Container(color: Colors.transparent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.35, 0.65, 1.0],
          colors: [
            Color(0x33000000),
            Color(0x05000000),
            Color(0x44000000),
            Color(0xCC000000),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopUI(BuildContext context) {
    final activeDest = sampleDestinations[_currentIndex];
    final categoryList = ['VỊNH BIỂN', 'NÚI RỪNG', 'DI SẢN', 'ĐÔ THỊ'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Header Navigation Bar Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo/Travel branding
              Row(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 96, // 3x of original 32!
                    height: 96,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'TourXport',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFD4AF7A),
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              
              // Navigation links (middle)
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(categoryList.length, (idx) {
                        final cat = categoryList[idx];
                        
                        bool isThisCatActive = false;
                        final prov = activeDest.province.toLowerCase();
                        final name = activeDest.name.toLowerCase();
                        if (cat == 'VỊNH BIỂN') {
                          isThisCatActive = prov.contains('quảng ninh') || prov.contains('khánh hòa') || prov.contains('vũng tàu') || prov.contains('kiên giang') || name.contains('vịnh') || name.contains('biển') || name.contains('đảo');
                        } else if (cat == 'NÚI RỪNG') {
                          isThisCatActive = prov.contains('lào cai') || prov.contains('quảng bình') || prov.contains('sơn la') || prov.contains('hà giang') || name.contains('núi') || name.contains('động') || name.contains('hang') || name.contains('phong nha');
                        } else if (cat == 'DI SẢN') {
                          isThisCatActive = prov.contains('quảng nam') || prov.contains('huế') || prov.contains('hà nội') || prov.contains('ninh bình') || name.contains('cổ') || name.contains('di tích') || name.contains('tự') || name.contains('lăng') || name.contains('chùa');
                        } else if (cat == 'ĐÔ THỊ') {
                          isThisCatActive = prov.contains('chí minh') || prov.contains('đà nẵng') || prov.contains('hà nội') || name.contains('tháp') || name.contains('cầu') || name.contains('nhà hát');
                        }

                        return WebHoverable(
                          onTap: () {
                            final firstIdx = _findFirstIndexForCategory(cat.toLowerCase());
                            if (firstIdx != -1) {
                              _selectDestination(firstIdx);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  cat,
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 13,
                                    fontWeight: isThisCatActive ? FontWeight.bold : FontWeight.w500,
                                    color: isThisCatActive ? Colors.white : Colors.white60,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  height: 2.0,
                                  width: isThisCatActive ? 30 : 0,
                                  color: const Color(0xFFD4AF7A),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),

              // Auth Buttons (right)
              Row(
                children: _isRestoringSession
                    ? [
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFD4AF7A),
                          ),
                        ),
                      ]
                    : hasSession
                    ? [
                        Text(
                          'XIN CHÀO, ${(_storedUserName ?? 'BẠN').toUpperCase()}!',
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(width: 24),
                        WebHoverable(
                          onTap: () => _navigateToSignIn(context, false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFD4AF7A), width: 1.5),
                              borderRadius: BorderRadius.circular(30),
                              color: Colors.transparent,
                            ),
                            child: const Text(
                              'VÀO TRANG CHỦ',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD4AF7A),
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ]
                    : [
                        WebHoverable(
                          onTap: () => _navigateToSignIn(context, false),
                          child: const Text(
                            'ĐĂNG NHẬP',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        WebHoverable(
                          onTap: () => _navigateToSignIn(context, true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFD4AF7A), width: 1.5),
                              borderRadius: BorderRadius.circular(30),
                              color: Colors.transparent,
                            ),
                            child: const Text(
                              'ĐĂNG KÝ',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD4AF7A),
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ],
              ),
            ],
          ),

          // 2. Central Section: Left Giant Title and Right Dynamic Cards
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Title Area
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Khám phá Việt Nam — ${activeDest.province}',
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFD4AF7A),
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        activeDest.name.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 60,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                          letterSpacing: -1.0,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 15, offset: Offset(0, 4)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getBriefDescription(activeDest),
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                          height: 1.6,
                          shadows: const [
                            Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          WebHoverable(
                            onTap: () => _navigateToSignIn(context, false),
                            child: Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFD4AF7A), width: 1.5),
                                color: const Color(0xFFD4AF7A).withOpacity(0.1),
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Color(0xFFD4AF7A),
                                size: 30,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          WebHoverable(
                            onTap: () => _navigateToSignIn(context, false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D6A4F),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2D6A4F).withOpacity(0.4),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'BẮT ĐẦU HÀNH TRÌNH',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 40),

                // Right Showcase Cards Area
                Expanded(
                  flex: 4,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(sampleDestinations.length, (i) {
                          final dest = sampleDestinations[i];
                          final isCurrent = i == _currentIndex;

                          return WebHoverable(
                            onTap: () => _selectDestination(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutCubic,
                              width: isCurrent ? 180 : 130,
                              height: isCurrent ? 280 : 220,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isCurrent ? const Color(0xFFD4AF7A) : Colors.white24,
                                  width: isCurrent ? 2.0 : 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(isCurrent ? 0.6 : 0.4),
                                    blurRadius: isCurrent ? 20 : 10,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Destination.buildImage(dest.imagePath, fit: BoxFit.cover),
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          stops: const [0.4, 1.0],
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.85),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 14,
                                      bottom: 14,
                                      right: 14,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            dest.province.toUpperCase(),
                                            style: TextStyle(
                                              fontFamily: 'Montserrat',
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isCurrent ? const Color(0xFFD4AF7A) : Colors.white70,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            dest.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontFamily: 'Montserrat',
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Bottom controls and pages indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  WebHoverable(
                    onTap: () => _selectDestination((_currentIndex - 1 + sampleDestinations.length) % sampleDestinations.length),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white30, width: 1.5),
                        color: Colors.white.withOpacity(0.05),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  WebHoverable(
                    onTap: () => _selectDestination((_currentIndex + 1) % sampleDestinations.length),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white30, width: 1.5),
                        color: Colors.white.withOpacity(0.05),
                      ),
                      child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
              Text(
                '0${_currentIndex + 1}',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableW = constraints.maxWidth;
          final availableH = constraints.maxHeight;
          final contentMaxW = availableW > 600 ? 420.0 : availableW;
          final horizontalPad = (availableW - contentMaxW) / 2 + 32;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: availableH),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      _buildLogo(),
                      const SizedBox(height: 8),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPad),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTitle(),
                        const SizedBox(height: 12),
                        _buildSubtitle(),
                        const SizedBox(height: 24),
                        _buildButton(context),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogo() {
    return SlideTransition(
      position: _logoSlide,
      child: FadeTransition(
        opacity: _logoFade,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF7A).withOpacity(0.3),
                blurRadius: 50,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/logo.png',
            width: 160,
            height: 160,
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return SlideTransition(
      position: _titleSlide,
      child: FadeTransition(
        opacity: _titleFade,
        child: const Column(
          children: [
            Text(
              'KHÁM PHÁ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: AppColors.textPrimary,
                fontSize: 30,
                fontWeight: FontWeight.w400,
                letterSpacing: 6,
                shadows: [
                  Shadow(
                    color: Color(0x55000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
            SizedBox(height: 4),
            Text(
              'VIỆT NAM',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: AppColors.textPrimary,
                fontSize: 44,
                fontWeight: FontWeight.w600,
                letterSpacing: 5,
                shadows: [
                  Shadow(
                    color: Color(0x88000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                  Shadow(
                    color: Color(0x44000000),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    return SlideTransition(
      position: _subtitleSlide,
      child: FadeTransition(
        opacity: _subtitleFade,
        child: const Text(
          'Tìm điểm đến phù hợp cho bạn\nvới TourXport',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Montserrat',
            color: AppColors.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.7,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    return SlideTransition(
      position: _buttonSlide,
      child: FadeTransition(
        opacity: _buttonFade,
        child: AnimBuilder(
          animation: _buttonPulseController,
          builder: (context, child) {
            final pulseValue = _buttonPulseController.value * 0.15 + 0.85;
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2D6A4F).withOpacity(0.3 * pulseValue),
                    blurRadius: 20 * pulseValue,
                    spreadRadius: 2 * pulseValue,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: child,
            );
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _navigateToSignIn(context, false),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.hovered)) {
                      return Colors.black.withOpacity(0.9);
                    }
                    return AppColors.buttonDark.withOpacity(0.85);
                  }),
                  foregroundColor: WidgetStateProperty.all(AppColors.textPrimary),
                  padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 16, horizontal: 32)),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  elevation: WidgetStateProperty.all(0),
                ),
                child: const Text(
                  'BẮT ĐẦU NGAY',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
