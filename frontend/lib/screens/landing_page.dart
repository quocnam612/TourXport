import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/anim_builder.dart';
import 'sign_in.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  // ── Animation controllers ──
  late final AnimationController _fadeController;
  late final AnimationController _shimmerController;
  late final AnimationController _buttonPulseController;

  // ── Individual element animations ──
  late final Animation<double> _logoFade;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _buttonFade;
  late final Animation<Offset> _buttonSlide;

  @override
  void initState() {
    super.initState();

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
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _shimmerController.dispose();
    _buttonPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackgroundImage(),
          _buildShimmerOverlay(),
          _buildGradientOverlay(),
          _buildContent(context),
        ],
      ),
    );
  }

  // ── Layout Components ──

  Widget _buildBackgroundImage() {
    return Image.asset(
      'assets/images/halong.jpg',
      fit: BoxFit.cover,
    );
  }

  Widget _buildShimmerOverlay() {
    return AnimBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(
                math.sin(_shimmerController.value * 2 * math.pi) * 0.3,
                math.cos(_shimmerController.value * 2 * math.pi) * 0.2 - 0.3,
              ),
              radius: 1.2,
              colors: const [
                Color(0x18FFFFFF),
                Color(0x00FFFFFF),
              ],
            ),
          ),
        );
      },
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
            Color(0x22000000),
            Color(0x08000000),
            Color(0x55000000),
            Color(0xAA000000),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableW = constraints.maxWidth;
          final availableH = constraints.maxHeight;
          // Constrain content width on wide screens
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
                      const SizedBox(height: 24),
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
            width: 250,
            height: 250,
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
        child: Column(
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
                    color: const Color(0x55000000),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
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
                    color: const Color(0x88000000),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  Shadow(
                    color: const Color(0x44000000),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
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
                borderRadius: BorderRadius.circular(30),
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
            constraints: const BoxConstraints(maxWidth: 400),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const SignInScreen(),
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
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith((states) {
                    if (states.contains(MaterialState.hovered)) {
                      return Colors.black.withOpacity(0.9);
                    }
                    return AppColors.buttonDark.withOpacity(0.85);
                  }),
                  foregroundColor: MaterialStateProperty.all(AppColors.textPrimary),
                  padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 22)),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  elevation: MaterialStateProperty.all(0),
                ),
                child: const Text(
                  'BẮT ĐẦU NGAY',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 20,
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