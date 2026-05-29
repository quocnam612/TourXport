import 'dart:ui';

import 'package:flutter/material.dart';

import '../api/api.dart';
import '../models/destination.dart';
import 'map_screen.dart';

class PlaceDetailScreen extends StatefulWidget {
  final Destination destination;
  final Rect? cardRect;
  final bool isSaved;
  final bool isLiked;
  final String? authToken;
  final bool useSimpleTransition;

  const PlaceDetailScreen({
    super.key,
    required this.destination,
    this.cardRect,
    this.isSaved = false,
    this.isLiked = false,
    this.authToken,
    this.useSimpleTransition = false,
  });

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  late bool _isSaved;
  late bool _isLiked;
  bool _showFullDesc = false;
  int _selectedTab = 0; // 0 = Tổng quan, 1 = Nhận xét

  Animation<double>? _routeAnimation;
  late Animation<double> _headerFade;
  late Animation<double> _panelSlide;
  late Animation<double> _contentFade;

  // Sheet controller for parallax
  final DraggableScrollableController _sheetCtrl = DraggableScrollableController();
  double _sheetFraction = 0.50;

  @override
  void initState() {
    super.initState();
    _isSaved = widget.isSaved;
    _isLiked = widget.isLiked;
    _sheetCtrl.addListener(_onSheetChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeAnimation == null) {
      _routeAnimation = ModalRoute.of(context)?.animation;
      final parentAnim = _routeAnimation ?? const AlwaysStoppedAnimation(1.0);

      if (widget.useSimpleTransition) {
        _headerFade = CurvedAnimation(
          parent: parentAnim,
          curve: Curves.easeOut,
        );
        _panelSlide = CurvedAnimation(
          parent: parentAnim,
          curve: Curves.easeOutCubic,
        );
        _contentFade = CurvedAnimation(
          parent: parentAnim,
          curve: Curves.easeOut,
        );
      } else {
        _headerFade = CurvedAnimation(
          parent: parentAnim,
          curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
        );
        _panelSlide = CurvedAnimation(
          parent: parentAnim,
          curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
        );
        _contentFade = CurvedAnimation(
          parent: parentAnim,
          curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
        );
      }
    }
  }

  void _onSheetChanged() {
    setState(() => _sheetFraction = _sheetCtrl.size);
  }

  Future<void> _toggleSaved() async {
    final token = widget.authToken?.trim();
    if (token == null || token.isEmpty) {
      _showMessage('Bạn cần đăng nhập để lưu địa điểm');
      return;
    }

    final dest = widget.destination;

    try {
      String? placeId = dest.id;
      if (placeId == null || placeId.isEmpty) {
        placeId = await resolveLocationIdByName(dest.name, dest.type, token: token);
      }

      if (placeId == null || placeId.isEmpty) {
        _showMessage('Không tìm thấy thông tin địa điểm này trên hệ thống');
        return;
      }

      final savedEndpoint = savedLocationEndpointForType(dest.type);
      final savedBodyKey = savedLocationBodyKeyForType(dest.type);
      final response = _isSaved
          ? await apiDeleteJson(
              '$savedEndpoint/$placeId',
              {},
              token: token,
            )
          : await apiPostJson(
              savedEndpoint,
              {savedBodyKey: placeId},
              token: token,
            );

      final data = tryDecodeJsonObject(response.body);
      if (!mounted) return;

      if (response.statusCode == 200 && data?['success'] == true) {
        setState(() => _isSaved = !_isSaved);
        _showMessage(
          _isSaved ? 'Đã lưu ${dest.name}' : 'Đã bỏ lưu ${dest.name}',
        );
      } else {
        _showMessage(data?['message'] as String? ?? 'Không cập nhật được trạng thái lưu');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Không kết nối được server để cập nhật trạng thái lưu');
      }
    }
  }

  void _toggleLike() {
    setState(() => _isLiked = !_isLiked);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _sheetCtrl.removeListener(_onSheetChanged);
    _sheetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dest = widget.destination;
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;
    final parentAnim = _routeAnimation ?? const AlwaysStoppedAnimation(1.0);
    final isDesktop = screenW >= 800;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F1E1B),
        body: _buildDesktopLayout(dest, screenH, screenW),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, {
          'isSaved': _isSaved,
          'isLiked': _isLiked,
        });
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            if (!widget.useSimpleTransition)
              FadeTransition(
                opacity: parentAnim,
                child: Container(color: Colors.black),
              ),

            if (!widget.useSimpleTransition)
              Positioned(
                top: 0, left: 0,
                child: Hero(
                  tag: 'card_hero_${dest.name}',
                  child: const SizedBox(width: 1, height: 1),
                ),
              ),

            widget.useSimpleTransition
                ? _buildSimpleImage(dest, parentAnim)
                : _buildCinematicImage(dest, screenH, screenW, parentAnim),

            // Top bar gradient
            Positioned(
              top: 0, left: 0, right: 0, height: 140,
              child: FadeTransition(
                opacity: _headerFade,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),

            _buildTopBar(context),

            // Panel
            _buildDraggablePanel(dest),
            
            // Bottom CTA
            _buildBottomCTA(),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(Destination dest, double screenH, double screenW) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        padding: const EdgeInsets.all(32),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Half: Image & Gallery
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Beautiful back button and title
                  Row(
                    children: [
                      _glassCircle(Icons.arrow_back_ios_new, () => Navigator.pop(context, {
                        'isSaved': _isSaved,
                        'isLiked': _isLiked,
                      })),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          dest.name,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Image Container
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Destination.buildImage(dest.imagePath, fit: BoxFit.cover),
                            
                            // Top overlay with actions
                            Positioned(
                              top: 20,
                              right: 20,
                              child: Row(
                                children: [
                                  _glassCircleAnimatedIcon(
                                    isActive: _isLiked,
                                    activeIcon: Icons.favorite,
                                    inactiveIcon: Icons.favorite_border,
                                    onTap: _toggleLike,
                                    activeColor: const Color(0xFFE74C3C),
                                  ),
                                  const SizedBox(width: 12),
                                  _glassCircleAnimatedIcon(
                                    isActive: _isSaved,
                                    activeIcon: Icons.bookmark,
                                    inactiveIcon: Icons.bookmark_border,
                                    onTap: _toggleSaved,
                                    activeColor: const Color(0xFFD4AF7A),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Gallery title
                  _sectionTitle('Bộ sưu tập'),
                  const SizedBox(height: 12),

                  // Gallery
                  _buildGallery(dest),
                ],
              ),
            ),
            const SizedBox(width: 48),

            // Right Half: Details, Description, Reviews, CTA
            Expanded(
              flex: 5,
              child: Card(
                color: const Color(0xFF15221F).withOpacity(0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Details
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Color(0xFFD4AF7A), size: 20),
                              const SizedBox(width: 6),
                              Text(
                                dest.province,
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.star_rounded, color: Color(0xFFFFB74D), size: 22),
                              const SizedBox(width: 6),
                              const Text(
                                '4.9 (1.2k nhận xét)',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 15,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // Tab bar
                          _buildTabBar(),
                          const SizedBox(height: 20),

                          // Tab content
                          Expanded(
                            child: SingleChildScrollView(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: _selectedTab == 0
                                    ? _buildOverviewTabForDesktop(dest)
                                    : _buildReviewsTab(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // CTA Button
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MapScreen(destination: widget.destination),
                                ),
                              );
                            },
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFB5956A), Color(0xFFD4AF7A)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFB5956A).withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.directions_rounded, color: Colors.white, size: 24),
                                  SizedBox(width: 10),
                                  Text(
                                    'Đường đi',
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: Colors.white,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
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
      ),
    );
  }

  Widget _buildOverviewTabForDesktop(Destination dest) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Mô tả'),
        const SizedBox(height: 8),
        _buildAboutSection(dest),
        const SizedBox(height: 24),
        _sectionTitle('Điểm nổi bật'),
        const SizedBox(height: 12),
        _buildHighlightChips(),
      ],
    );
  }

  Widget _buildCinematicImage(
    Destination dest,
    double screenH,
    double screenW,
    Animation<double> parentAnim,
  ) {
    if (widget.cardRect == null) {
      return Positioned.fill(
        child: Destination.buildImage(dest.imagePath, fit: BoxFit.cover),
      );
    }

    return AnimatedBuilder(
      animation: parentAnim,
      builder: (context, child) {
        final val = parentAnim.value;
        final cardRect = widget.cardRect!;
        
        if (val == 1.0) {
          final t = ((_sheetFraction - 0.50) / (0.92 - 0.50)).clamp(0.0, 1.0);
          final double offsetY = -t * 50; 
          
          return Positioned.fill(
            child: Transform.translate(
              offset: Offset(0, offsetY),
              child: Destination.buildImage(dest.imagePath, fit: BoxFit.cover),
            ),
          );
        }

        double currentTop, currentLeft, currentWidth, currentHeight, currentRadius;
        double cardInfoOpacity = 1.0;
        
        if (val <= 0.4) {
          final p1 = Curves.easeInOutCubic.transform(val / 0.4);
          final targetTop = (screenH - cardRect.height) / 2;
          
          currentTop = lerpDouble(cardRect.top, targetTop, p1)!;
          currentLeft = cardRect.left;
          currentWidth = cardRect.width;
          currentHeight = cardRect.height;
          currentRadius = 28.0;
          cardInfoOpacity = 1.0;
        } else {
          final p2 = Curves.easeInOutCubic.transform((val - 0.4) / 0.6);
          final startTop = (screenH - cardRect.height) / 2;
          
          currentTop = lerpDouble(startTop, 0, p2)!;
          currentLeft = lerpDouble(cardRect.left, 0, p2)!;
          currentWidth = lerpDouble(cardRect.width, screenW, p2)!;
          currentHeight = lerpDouble(cardRect.height, screenH, p2)!;
          currentRadius = lerpDouble(28.0, 0.0, p2)!;
          
          cardInfoOpacity = lerpDouble(1.0, 0.0, (p2 * 2).clamp(0.0, 1.0))!;
        }

        return Positioned(
          top: currentTop,
          left: currentLeft,
          width: currentWidth,
          height: currentHeight,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(currentRadius),
              boxShadow: val <= 0.4 ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ] : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(currentRadius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Destination.buildImage(dest.imagePath, fit: BoxFit.cover),
                  
                  if (cardInfoOpacity > 0)
                    Opacity(
                      opacity: cardInfoOpacity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Positioned(
                            left: 0, right: 0, bottom: 0, height: 180,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 20, right: 20, bottom: 20,
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
                                          const Icon(Icons.pin_drop_rounded, color: Color(0xFFB5956A), size: 24),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              dest.name,
                                              style: const TextStyle(
                                                fontFamily: 'Montserrat',
                                                fontSize: 26,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                                shadows: [Shadow(color: Color(0x88000000), blurRadius: 8)],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 20, right: 20,
                            child: Container(
                              width: 52, height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFFB5956A),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
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
    );
  }

  Widget _buildSimpleImage(Destination dest, Animation<double> parentAnim) {
    return Positioned.fill(
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: parentAnim,
          curve: Curves.easeOut,
        ),
        child: Destination.buildImage(dest.imagePath, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 20, right: 20,
      child: FadeTransition(
        opacity: _headerFade,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _glassCircle(Icons.arrow_back_ios_new, () => Navigator.pop(context, {
              'isSaved': _isSaved,
              'isLiked': _isLiked,
            })),
            Row(
              children: [
                _glassCircle(Icons.share_outlined, () {}),
                const SizedBox(width: 10),
                _glassCircleAnimatedIcon(
                  isActive: _isLiked,
                  activeIcon: Icons.favorite,
                  inactiveIcon: Icons.favorite_border,
                  onTap: _toggleLike,
                  activeColor: const Color(0xFFE74C3C),
                ),
                const SizedBox(width: 10),
                _glassCircleAnimatedIcon(
                  isActive: _isSaved,
                  activeIcon: Icons.bookmark,
                  inactiveIcon: Icons.bookmark_border,
                  onTap: _toggleSaved,
                  activeColor: const Color(0xFFD4AF7A),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraggablePanel(Destination dest) {
    return AnimatedBuilder(
      animation: _panelSlide,
      builder: (context, child) {
        final screenH = MediaQuery.of(context).size.height;
        final slideOffset = (1 - _panelSlide.value) * screenH;
        return Opacity(
          opacity: _panelSlide.value.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, slideOffset), child: child),
        );
      },
      child: DraggableScrollableSheet(
        controller: _sheetCtrl,
        initialChildSize: 0.50,
        minChildSize: 0.50,
        maxChildSize: 0.92,
        builder: (context, scrollCtrl) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  border: Border(top: BorderSide(color: Colors.white.withOpacity(0.12), width: 1)),
                ),
                child: FadeTransition(
                  opacity: _contentFade,
                  child: ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 120),
                    children: [
                      Center(
                        child: Container(
                          width: 42, height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(dest.name, style: const TextStyle(
                        fontFamily: 'Montserrat', fontSize: 28,
                        fontWeight: FontWeight.w700, color: Colors.white,
                      )),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Color(0xFFD4AF7A), size: 16),
                          const SizedBox(width: 4),
                          Text(dest.province, style: const TextStyle(
                            fontFamily: 'Montserrat', fontSize: 14,
                            color: Colors.white70,
                          )),
                          const Spacer(),
                          const Icon(Icons.star_rounded, color: Color(0xFFFFB74D), size: 18),
                          const SizedBox(width: 4),
                          const Text('4.9 (1.2k nhận xét)', style: TextStyle(
                            fontFamily: 'Montserrat', fontSize: 13,
                            color: Colors.white70,
                          )),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildTabBar(),
                      const SizedBox(height: 20),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _selectedTab == 0
                            ? _buildOverviewTab(dest)
                            : _buildReviewsTab(),
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

  Widget _buildTabBar() {
    return Row(
      children: [
        _tabItem('Tổng quan', 0),
        const SizedBox(width: 24),
        _tabItem('Nhận xét', 1),
      ],
    );
  }

  Widget _tabItem(String label, int index) {
    final isActive = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Column(
        children: [
          Text(label, style: TextStyle(
            fontFamily: 'Montserrat', fontSize: 16,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
          )),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2, width: isActive ? 40 : 0,
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF7A),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(Destination dest) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Mô tả'),
        const SizedBox(height: 8),
        _buildAboutSection(dest),
        const SizedBox(height: 24),
        _sectionTitle('Điểm nổi bật'),
        const SizedBox(height: 12),
        _buildHighlightChips(),
        const SizedBox(height: 24),
        _sectionTitle('Bộ sưu tập'),
        const SizedBox(height: 12),
        _buildGallery(dest),
      ],
    );
  }

  Widget _buildAboutSection(Destination dest) {
    final fullText = _getDescription(dest.name);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fullText,
          maxLines: _showFullDesc ? 20 : 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Montserrat', fontSize: 14,
            color: Colors.white.withOpacity(0.8), height: 1.7,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => setState(() => _showFullDesc = !_showFullDesc),
          child: Text(
            _showFullDesc ? 'Thu gọn' : 'Xem thêm',
            style: const TextStyle(
              fontFamily: 'Montserrat', fontSize: 13,
              fontWeight: FontWeight.w600, color: Color(0xFFD4AF7A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsTab() {
    return Column(
      children: [
        _buildReviewCard(name: 'Minh Tuấn', rating: 5,
          text: 'Phong cảnh tuyệt đẹp, dịch vụ rất chu đáo. Nhất định sẽ quay lại!'),
        const SizedBox(height: 12),
        _buildReviewCard(name: 'Hồng Nhung', rating: 4,
          text: 'Trải nghiệm rất đáng nhớ. Hướng dẫn viên nhiệt tình và thân thiện.'),
        const SizedBox(height: 12),
        _buildReviewCard(name: 'Anh Khoa', rating: 5,
          text: 'Một trong những chuyến đi tuyệt vời nhất. Cảnh đẹp không thể tả!'),
      ],
    );
  }

  String _getDescription(String name) {
    final descriptions = {
      'Hạ Long Bay': 'Hạ Long Bay là kỳ quan thiên nhiên thế giới với hơn 1.600 hòn đảo đá vôi nhô lên từ mặt biển xanh ngọc bích. Nơi đây mang vẻ đẹp huyền bí, lung linh qua từng buổi sớm mai và hoàng hôn.',
      'Hội An': 'Hội An là phố cổ mang đậm dấu ấn lịch sử và văn hóa, nổi tiếng với những ngôi nhà cổ, đèn lồng rực rỡ và ẩm thực đường phố phong phú.',
      'Đà Nẵng': 'Đà Nẵng là thành phố biển năng động với bãi biển Mỹ Khê tuyệt đẹp, cầu Rồng ấn tượng và Bà Nà Hills lãng mạn.',
      'Phong Nha': 'Phong Nha-Kẻ Bàng là vườn quốc gia sở hữu hệ thống hang động kỳ vĩ nhất thế giới, bao gồm Sơn Đoòng — hang động lớn nhất hành tinh.',
    };
    return descriptions[name] ?? 'Một điểm đến tuyệt vời tại Việt Nam với cảnh quan thiên nhiên hùng vĩ và văn hóa đặc sắc.';
  }

  Widget _buildGallery(Destination dest) {
    final images = [
      dest.imagePath,
      destinationPlaceholderPath,
      destinationPlaceholderPath,
      destinationPlaceholderPath,
      destinationPlaceholderPath,
    ];
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) => ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 130,
            child: Destination.buildImage(
              images[i],
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomCTA() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 34),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MapScreen(destination: widget.destination),
                        ),
                      );
                    },
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFB5956A), Color(0xFFD4AF7A)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFB5956A).withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_rounded, color: Colors.white, size: 24),
                          SizedBox(width: 10),
                          Text(
                            'Đường đi',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassCircle(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.25),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _glassCircleAnimatedIcon({
    required bool isActive,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required VoidCallback onTap,
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.25),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                isActive ? activeIcon : inactiveIcon,
                key: ValueKey<bool>(isActive),
                color: isActive ? activeColor : Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text, style: const TextStyle(
      fontFamily: 'Montserrat', fontSize: 18,
      fontWeight: FontWeight.w700, color: Colors.white,
    ));
  }

  Widget _buildHighlightChips() {
    final highlights = [
      (Icons.landscape_rounded, 'Thiên nhiên'),
      (Icons.camera_alt_rounded, 'Chụp ảnh'),
      (Icons.restaurant_rounded, 'Ẩm thực'),
      (Icons.kayaking_rounded, 'Phiêu lưu'),
    ];
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: highlights.map((h) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.13),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(h.$1, size: 16, color: Colors.white.withOpacity(0.9)),
            const SizedBox(width: 6),
            Text(h.$2, style: const TextStyle(
              fontFamily: 'Montserrat', fontSize: 13,
              color: Colors.white,
            )),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildReviewCard({required String name, required int rating, required String text}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.11),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFB5956A).withOpacity(0.2),
              child: Text(name[0], style: const TextStyle(
                fontFamily: 'Montserrat', fontWeight: FontWeight.w700,
                color: Color(0xFFB5956A),
              )),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(
                  fontFamily: 'Montserrat', fontSize: 14,
                  fontWeight: FontWeight.w600, color: Colors.white,
                )),
                Row(children: List.generate(5, (i) => Icon(
                  i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                  color: const Color(0xFFFFB74D), size: 16,
                ))),
              ],
            )),
          ]),
          const SizedBox(height: 10),
          Text(text, style: TextStyle(
            fontFamily: 'Montserrat', fontSize: 13,
            color: Colors.white.withOpacity(0.82), height: 1.5,
          )),
        ],
      ),
    );
  }
}
