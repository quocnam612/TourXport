import 'dart:ui';

import 'package:flutter/material.dart';

import '../api/api.dart';
import '../models/destination.dart';
import '../widgets/anim_builder.dart';
import 'place_detail.dart';
import 'saved_place.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final String? authToken;

  const HomeScreen({
    super.key,
    this.userName = 'Username',
    this.authToken,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  int _previousIndex = 0;
  int _navIndex = 0;
  bool _showLikedOnly = false;

  final Set<String> _savedNames = {};
  final Set<String> _likedNames = {};
  final Set<String> _updatingSavedNames = {};
  List<Destination> _savedDestinations = const [];
  bool _isLoadingSavedPlaces = false;

  late final AnimationController _bgFadeController;
  late final Animation<double> _bgFade;
  late final AnimationController _entranceController;
  late final Animation<double> _cardEntrance;
  late final PageController _pageController;

  static const Map<String, int> _fakeLikeSeeds = {
    'Hạ Long Bay': 1243,
    'Hội An': 987,
    'Đà Nẵng': 1765,
    'Phong Nha': 842,
  };

  @override
  void initState() {
    super.initState();

    _pageController = PageController(viewportFraction: 0.82);

    _bgFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bgFade = CurvedAnimation(
      parent: _bgFadeController,
      curve: Curves.easeInOut,
    );

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _cardEntrance = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _entranceController.forward();

    _loadSavedPlaces();
  }

  @override
  void dispose() {
    _bgFadeController.dispose();
    _entranceController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });
    _bgFadeController.forward(from: 0);
  }

  Future<void> _loadSavedPlaces({bool showError = false}) async {
    final token = widget.authToken?.trim();
    if (token == null || token.isEmpty) {
      return;
    }

    setState(() => _isLoadingSavedPlaces = true);

    try {
      final response = await apiGet('/auth/saved-places', token: token);
      final data = tryDecodeJsonObject(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 && data?['success'] == true) {
        _applySavedPlacesPayload(data!);
      } else if (showError) {
        _showMessage(data?['message'] as String? ?? 'Không tải được danh sách đã lưu');
      }
    } catch (_) {
      if (mounted && showError) {
        _showMessage('Không kết nối được server để tải địa điểm đã lưu');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingSavedPlaces = false);
      }
    }
  }

  void _applySavedPlacesPayload(Map<String, dynamic> data) {
    final rawPlaces = data['savedPlaces'];
    if (rawPlaces is! List) return;

    final places = rawPlaces
        .whereType<Map>()
        .map((item) => Destination.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.name.isNotEmpty)
        .toList();

    setState(() {
      _savedDestinations = places;
      _savedNames
        ..clear()
        ..addAll(places.map((item) => item.name));
    });
  }

  Future<bool> _toggleSaved(Destination dest) async {
    final token = widget.authToken?.trim();
    if (token == null || token.isEmpty) {
      _showMessage('Bạn cần đăng nhập để lưu địa điểm');
      return false;
    }

    if (_updatingSavedNames.contains(dest.name)) {
      return _savedNames.contains(dest.name);
    }

    final currentlySaved = _savedNames.contains(dest.name);
    setState(() => _updatingSavedNames.add(dest.name));

    try {
      final response = currentlySaved
          ? await apiDeleteJson(
              '/auth/saved-places',
              {'name': dest.name},
              token: token,
            )
          : await apiPostJson(
              '/auth/saved-places',
              dest.toJson(),
              token: token,
            );

      final data = tryDecodeJsonObject(response.body);
      if (!mounted) return currentlySaved;

      if (response.statusCode == 200 && data?['success'] == true) {
        _applySavedPlacesPayload(data!);
        _showMessage(
          currentlySaved
              ? 'Đã bỏ lưu ${dest.name}'
              : 'Đã lưu ${dest.name}',
        );
      } else {
        _showMessage(data?['message'] as String? ?? 'Không cập nhật được địa điểm đã lưu');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Không kết nối được server để cập nhật địa điểm đã lưu');
      }
    } finally {
      if (mounted) {
        setState(() => _updatingSavedNames.remove(dest.name));
      }
    }

    return _savedNames.contains(dest.name);
  }

  void _applySavedStateFromDetail(Destination dest, bool isSaved) {
    setState(() {
      if (isSaved) {
        _savedNames.add(dest.name);
        final exists = _savedDestinations.any((item) => item.name == dest.name);
        if (!exists) {
          _savedDestinations = [..._savedDestinations, dest];
        }
      } else {
        _savedNames.remove(dest.name);
        _savedDestinations = _savedDestinations
            .where((item) => item.name != dest.name)
            .toList();
      }
    });
  }

  void _toggleLike(Destination dest) {
    setState(() {
      if (_likedNames.contains(dest.name)) {
        _likedNames.remove(dest.name);
      } else {
        _likedNames.add(dest.name);
      }
    });
  }

  int _fakeLikeCountFor(Destination dest, {required bool isLiked}) {
    final seeded = _fakeLikeSeeds[dest.name] ?? (700 + (dest.name.length * 37));
    return isLiked ? seeded + 1 : seeded;
  }

  Future<void> _openPlaceDetail(Destination dest, BuildContext cardContext) async {
    final useSimpleTransition = _navIndex == 1;
    Rect? cardRect;

    if (!useSimpleTransition) {
      final renderBox = cardContext.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final offset = renderBox.localToGlobal(Offset.zero);
        cardRect = offset & renderBox.size;
      }
    }

    final result = await Navigator.push<Map<String, bool>>(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => PlaceDetailScreen(
          destination: dest,
          cardRect: cardRect,
          isSaved: _savedNames.contains(dest.name),
          isLiked: _likedNames.contains(dest.name),
          authToken: widget.authToken,
          useSimpleTransition: useSimpleTransition,
        ),
        transitionDuration: Duration(
          milliseconds: useSimpleTransition ? 480 : 800,
        ),
        reverseTransitionDuration: Duration(
          milliseconds: useSimpleTransition ? 360 : 800,
        ),
        transitionsBuilder: (_, animation, __, child) {
          if (!useSimpleTransition) return child;

          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          );
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(fade);

          return FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: slide,
              child: child,
            ),
          );
        },
      ),
    );

    if (!mounted || result == null) return;
    final isSaved = result['isSaved'];
    final isLiked = result['isLiked'];
    if (isSaved != null) {
      _applySavedStateFromDetail(dest, isSaved);
    }
    if (isLiked != null) {
      setState(() {
        if (isLiked) {
          _likedNames.add(dest.name);
        } else {
          _likedNames.remove(dest.name);
        }
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _jumpToRegion(String region) {
    final destinations = _homeDestinations;
    final idx = destinations.indexWhere((d) => d.province == region);
    if (idx >= 0 && idx != _currentIndex) {
      _pageController.animateToPage(
        idx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else if (idx < 0) {
      _showMessage('Không có địa điểm phù hợp bộ lọc hiện tại');
    }
  }

  List<Destination> get _homeDestinations {
    if (!_showLikedOnly) return sampleDestinations;
    return sampleDestinations
        .where((d) => _likedNames.contains(d.name))
        .toList();
  }

  void _toggleLikedOnlyView() {
    setState(() => _showLikedOnly = !_showLikedOnly);

    final destinations = _homeDestinations;
    if (destinations.isEmpty) {
      _showMessage('Chưa có địa điểm nào được thả tim');
      return;
    }

    final first = destinations.first;
    final firstSampleIndex =
        sampleDestinations.indexWhere((d) => d.name == first.name);
    if (firstSampleIndex >= 0) {
      setState(() {
        _previousIndex = _currentIndex;
        _currentIndex = firstSampleIndex;
      });
      _bgFadeController.forward(from: 0);
    }

    if (_pageController.hasClients) {
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _jumpToRandomDestination() {
    final destinations = _homeDestinations;
    if (destinations.isEmpty) {
      _showMessage('Không có địa điểm để chọn ngẫu nhiên');
      return;
    }
    final seed = DateTime.now().microsecondsSinceEpoch.abs();
    final idx = seed % destinations.length;

    if (_pageController.hasClients) {
      _pageController.animateToPage(
        idx,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _openSearchToolsSheet() async {
    final regions = _homeDestinations
        .map((d) => d.province)
        .toSet()
        .toList();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1B2321).withOpacity(0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.26),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Công cụ nhanh',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              _toolActionTile(
                icon: _showLikedOnly
                    ? Icons.visibility_rounded
                    : Icons.favorite_rounded,
                title: _showLikedOnly
                    ? 'Hiện tất cả địa điểm'
                    : 'Chỉ xem đã thích',
                subtitle: _showLikedOnly
                    ? 'Tắt lọc theo tim'
                    : 'Lọc nhanh theo tim',
                onTap: () {
                  Navigator.pop(context);
                  _toggleLikedOnlyView();
                },
              ),
              const SizedBox(height: 8),
              _toolActionTile(
                icon: Icons.casino_rounded,
                title: 'Điểm đến ngẫu nhiên',
                subtitle: 'Nhảy đến một địa điểm bất kỳ',
                onTap: () {
                  Navigator.pop(context);
                  _jumpToRandomDestination();
                },
              ),
              const SizedBox(height: 8),
              _toolActionTile(
                icon: Icons.refresh_rounded,
                title: 'Làm mới dữ liệu đã lưu',
                subtitle: 'Tải lại từ server',
                onTap: () {
                  Navigator.pop(context);
                  _loadSavedPlaces(showError: true);
                },
              ),
              const SizedBox(height: 14),
              Text(
                'Đi nhanh theo khu vực',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.82),
                ),
              ),
              const SizedBox(height: 10),
              if (regions.isEmpty)
                Text(
                  'Không có khu vực nào cho bộ lọc hiện tại.',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: regions.map((region) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _jumpToRegion(region);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Text(
                          region,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _toolActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.14)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFFD4AF7A), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.72),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

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

  Widget _buildPreviousBackground() {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            sampleDestinations[_previousIndex].bgBlurPath,
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
              sampleDestinations[_currentIndex].bgBlurPath,
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
    final bool isSavedTab = _navIndex == 1;

    return SafeArea(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 360),
        reverseDuration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(animation);

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: slide,
              child: child,
            ),
          );
        },
        child: isSavedTab
            ? SavedPlacesSection(
                entranceAnimation: _cardEntrance,
                savedDestinations: _savedDestinations,
                updatingSavedNames: _updatingSavedNames,
                isLoading: _isLoadingSavedPlaces,
                onBack: () => setState(() => _navIndex = 0),
                onOpenDetail: _openPlaceDetail,
                onToggleSaved: _toggleSaved,
              )
            : _buildHomeTabBody(size),
      ),
    );
  }

  Widget _buildHomeTabBody(Size size) {
    return Column(
      key: const ValueKey<String>('home_tab'),
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
    );
  }

  Widget _buildTopBar() {
    return FadeTransition(
      opacity: _cardEntrance,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
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
    const title = 'Trải nghiệm chuyến đi\ncùng TourXport';

    return FadeTransition(
      opacity: _cardEntrance,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(_cardEntrance),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Chào mừng đến với TourXport',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 30,
                fontWeight: FontWeight.w400,
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
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.40),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.7), size: 22),
                const SizedBox(width: 10),
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
                        color: Colors.white.withOpacity(0.4),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    cursorColor: const Color(0xFFB5956A),
                  ),
                ),
                Container(
                  width: 38,
                  height: 38,
                  margin: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.tune_rounded, color: Colors.white.withOpacity(0.7), size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegionTabs() {
    final regions = _homeDestinations
        .map((d) => d.province)
        .toSet()
        .toList();
    if (regions.isEmpty) {
      return const SizedBox(height: 36);
    }
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
                sampleDestinations[_currentIndex].province == regions[i];
            return GestureDetector(
              onTap: () {
                final idx = sampleDestinations
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
    final destinations = _homeDestinations;
    if (destinations.isEmpty) {
      return Center(
        child: Text(
          'Chưa có địa điểm nào được thả tim.',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 15,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _cardEntrance,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(_cardEntrance),
        child: PageView.builder(
          controller: _pageController,
          itemCount: destinations.length,
          onPageChanged: (index) {
            final selected = destinations[index];
            final mappedIndex =
                sampleDestinations.indexWhere((d) => d.name == selected.name);
            _onPageChanged(mappedIndex >= 0 ? mappedIndex : index);
          },
          itemBuilder: (context, index) {
            return AnimBuilder(
              animation: _pageController,
              builder: (context, child) {
                double page =
                    _pageController.hasClients && _pageController.page != null
                        ? _pageController.page!
                        : index.toDouble();
                final diff = (page - index).abs();
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
              child: _buildDestinationCard(destinations[index]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDestinationCard(Destination dest) {
    final isSaved = _savedNames.contains(dest.name);
    final isLiked = _likedNames.contains(dest.name);
    final likeCount = _fakeLikeCountFor(dest, isLiked: isLiked);
    final isBusy = _updatingSavedNames.contains(dest.name);

    return Padding(
      padding: const EdgeInsets.only(bottom: 80, left: 6, right: 6),
      child: Builder(
        builder: (cardContext) {
          return Hero(
            tag: 'card_hero_${dest.name}',
            flightShuttleBuilder: (_, __, ___, ____, _____) => const SizedBox.shrink(),
            placeholderBuilder: (context, size, child) =>
                Opacity(opacity: 0.0, child: child),
            child: Container(
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
                    Image.asset(
                      dest.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF2A4A3E),
                        child: const Center(
                          child: Icon(Icons.image, color: Colors.white38, size: 60),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      left: 14,
                      child: GestureDetector(
                        onTap: () => _toggleLike(dest),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(scale: animation, child: child),
                            child: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              key: ValueKey<bool>(isLiked),
                              color: isLiked ? const Color(0xFFE74C3C) : Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 62,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.36),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Text(
                          '$likeCount',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isLiked
                                ? const Color(0xFFE74C3C)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      right: 14,
                      child: GestureDetector(
                        onTap: isBusy ? null : () => _toggleSaved(dest),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(scale: animation, child: child),
                            child: isBusy
                                ? const Padding(
                                    key: ValueKey<String>('loading'),
                                    padding: EdgeInsets.all(11),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    isSaved
                                        ? Icons.bookmark_rounded
                                        : Icons.bookmark_border_rounded,
                                    key: ValueKey<bool>(isSaved),
                                    color: isSaved
                                        ? const Color(0xFFD4AF7A)
                                        : Colors.white,
                                    size: 22,
                                  ),
                          ),
                        ),
                      ),
                    ),
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
                                Row(
                                  children: [
                                    const Icon(Icons.pin_drop_rounded,
                                        color: Color(0xFFB5956A), size: 24),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
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
                                    ),
                                  ],
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
                          GestureDetector(
                            onTap: () => _openPlaceDetail(dest, cardContext),
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      Icons.home_rounded,
      Icons.bookmark_rounded,
      Icons.explore_rounded,
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
