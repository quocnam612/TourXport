import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/anim_builder.dart';
import 'place_detail.dart';

// ─────────────────────────────────────────────
//  DATA MODEL
// ─────────────────────────────────────────────
class Destination {
  final String name;
  final String province;
  final String price;
  final String imagePath;
  final String bgBlurPath;

  const Destination({
    required this.name,
    required this.province,
    required this.price,
    required this.imagePath,
    required this.bgBlurPath,
  });
}

// ── Sample data – sử dụng ảnh thực tế có trong assets ──
const List<Destination> _destinations = [
  Destination(
    name: 'Hạ Long Bay',
    province: 'Quảng Ninh',
    price: 'Chỉ từ 3 triệu đồng',
    imagePath: 'assets/images/halong.jpg',
    bgBlurPath: 'assets/images/halong.jpg',
  ),
  Destination(
    name: 'Hội An',
    province: 'Hà Nội',
    price: 'Chỉ từ 2 triệu đồng',
    imagePath: 'assets/images/Hoi An.jpg',
    bgBlurPath: 'assets/images/Hoi An.jpg',
  ),
  Destination(
    name: 'Đà Nẵng',
    province: 'Sài Gòn',
    price: 'Chỉ từ 1.5 triệu đồng',
    imagePath: 'assets/images/da_nang.jpg',
    bgBlurPath: 'assets/images/da_nang.jpg',
  ),
  Destination(
    name: 'Phong Nha',
    province: 'Đồng Tháp',
    price: 'Chỉ từ 1 triệu đồng',
    imagePath: 'assets/images/phongnhakebang.jpg',
    bgBlurPath: 'assets/images/phongnhakebang.jpg',
  ),
];

// ─────────────────────────────────────────────
//  HOME SCREEN
// ─────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  final String userName;

  const HomeScreen({super.key, this.userName = 'Username'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {

  // ── Page / swipe state ──
  int _currentIndex = 0;
  int _previousIndex = 0;

  // ── Favorites ──
  final Set<String> _favorites = {};

  // ── Background crossfade controller ──
  late final AnimationController _bgFadeController;
  late final Animation<double> _bgFade;

  // ── Card entrance controller ──
  late final AnimationController _entranceController;
  late final Animation<double> _cardEntrance;

  // ── Bottom nav ──
  int _navIndex = 0;

  // ── PageController cho card carousel ──
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(viewportFraction: 0.82);

    // Background crossfade
    _bgFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bgFade = CurvedAnimation(
      parent: _bgFadeController,
      curve: Curves.easeInOut,
    );

    // Card entrance (khi mới vào màn hình)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _cardEntrance = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _bgFadeController.dispose();
    _entranceController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ── Xử lý swipe → đổi background ──
  void _onPageChanged(int index) {
    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });
    _bgFadeController.forward(from: 0);
  }

  // ─────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [

          _buildPreviousBackground(),
          _buildCurrentBackground(),
          _buildDarkOverlay(),
          _buildUIContent(size),
          Positioned(
            left: 24,
            right: 24,
            bottom: 20,
            child: _buildBottomNav(),
          ),
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
          Image.asset(
            _destinations[_previousIndex].bgBlurPath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFF1C302D),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
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
            Image.asset(
              _destinations[_currentIndex].bgBlurPath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF1C302D),
              ),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.transparent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDarkOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.3, 0.7, 1.0],
            colors: [
              Color(0x55000000),
              Color(0x10000000),
              Color(0x30000000),
              Color(0xBB000000),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUIContent(Size size) {
    return SafeArea(
      child: Column(
        children: [
          _buildTopBar(),
          const SizedBox(height: 8),
          _buildTitle(),
          const SizedBox(height: 12),
          _buildSearchBar(),
          const SizedBox(height: 12),
          _buildRegionTabs(),
          const SizedBox(height: 12),
          Expanded(
            child: _buildCardCarousel(size),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  //  WIDGETS
  // ─────────────────────────────────────────

  Widget _buildTopBar() {
    return FadeTransition(
      opacity: _cardEntrance,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 10),

            // Hello Username
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào,\n${widget.userName}!',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Hamburger menu
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.menu, color: Colors.white, size: 26),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return FadeTransition(
      opacity: _cardEntrance,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(_cardEntrance),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Trải nghiệm chuyến đi\ncùng TourXport',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.2,
                shadows: [
                  Shadow(
                    color: Color(0x88000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return FadeTransition(
      opacity: _cardEntrance,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(_cardEntrance),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.9), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm điểm đến, tour...',
                      hintStyle: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    cursorColor: const Color(0xFFB5956A),
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB5956A),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFB5956A).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegionTabs() {
    final regions = ['Quảng Ninh', 'Hà Nội', 'Sài Gòn', 'Đồng Tháp'];
    return FadeTransition(
      opacity: _cardEntrance,
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: regions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, i) {
            final isSelected =
                _destinations[_currentIndex].province == regions[i];
            return GestureDetector(
              onTap: () {
                // Tìm destination đầu tiên có province khớp và scroll đến
                final idx = _destinations
                    .indexWhere((d) => d.province == regions[i]);
                if (idx >= 0 && idx != _currentIndex) {
                  _pageController.animateToPage(
                    idx,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white
                      : Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  regions[i],
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? Colors.black : Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCardCarousel(Size size) {
    return FadeTransition(
      opacity: _cardEntrance,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(_cardEntrance),
        child: PageView.builder(
          controller: _pageController,
          itemCount: _destinations.length,
          onPageChanged: _onPageChanged,
          itemBuilder: (context, index) {
            return AnimBuilder(
              animation: _pageController,
              builder: (context, child) {
                double page =
                    _pageController.hasClients && _pageController.page != null
                        ? _pageController.page!
                        : index.toDouble();
                final diff = (page - index).abs();
                // Scale & vertical offset cho parallax
                final scale = (1 - diff * 0.08).clamp(0.0, 1.0);
                final verticalOffset = diff * 20.0;
                final opacity = (1 - diff * 0.6).clamp(0.4, 1.0);

                return Transform.translate(
                  offset: Offset(0, verticalOffset),
                  child: Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity,
                      child: child,
                    ),
                  ),
                );
              },
              child: _buildDestinationCard(_destinations[index]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDestinationCard(Destination dest) {
    return Container(
      margin: const EdgeInsets.only(bottom: 80, left: 6, right: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [

            // Card image
            Hero(
              tag: 'hero_img_${dest.name}',
              child: Image.asset(
                dest.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF2A4A3E),
                  child: const Center(
                    child: Icon(Icons.image, color: Colors.white38, size: 60),
                  ),
                ),
              ),
            ),

            // Favorite button (top-left)
            Positioned(
              top: 14,
              left: 14,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (_favorites.contains(dest.name)) {
                      _favorites.remove(dest.name);
                    } else {
                      _favorites.add(dest.name);
                    }
                  });
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                    child: Icon(
                      _favorites.contains(dest.name) ? Icons.favorite : Icons.favorite_border,
                      key: ValueKey<bool>(_favorites.contains(dest.name)),
                      color: _favorites.contains(dest.name) ? const Color(0xFFE74C3C) : Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),

            // Bottom gradient on card
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 180,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
              ),
            ),

            // Info overlay at bottom
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Location pin
                        const Row(
                          children: [
                            Icon(Icons.location_on,
                                color: Color(0xFFE74C3C), size: 18),
                            SizedBox(width: 4),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dest.name,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Color(0x88000000),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dest.price,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Arrow button
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => PlaceDetailScreen(destination: dest),
                          transitionDuration: const Duration(milliseconds: 600),
                          reverseTransitionDuration: const Duration(milliseconds: 600),
                          transitionsBuilder: (_, animation, __, child) {
                            return FadeTransition(
                              opacity: CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOut,
                              ),
                              child: child,
                            );
                          },
                        ),
                      );
                    },
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB5956A),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFB5956A).withValues(alpha: 0.8),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 0),
                          ),
                          BoxShadow(
                            color: const Color(0xFFB5956A).withValues(alpha: 0.4),
                            blurRadius: 35,
                            spreadRadius: 8,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      Icons.home_rounded,
      Icons.explore_rounded,
      Icons.bookmark_rounded,
      Icons.person_rounded,
    ];

    return FadeTransition(
      opacity: _cardEntrance,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (i) {
                final isActive = _navIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _navIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      items[i],
                      color: isActive
                          ? Colors.black
                          : Colors.white.withValues(alpha: 0.55),
                      size: 26,
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}