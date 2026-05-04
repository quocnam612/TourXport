import 'dart:ui';

import 'package:flutter/material.dart';

import '../api/api.dart';
import '../models/destination.dart';

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

  Animation<double>? _routeAnimation;
  late Animation<double> _headerFade;
  late Animation<double> _panelSlide;
  late Animation<double> _contentFade;

  // Sheet controller for parallax
  final DraggableScrollableController _sheetCtrl = DraggableScrollableController();
  double _sheetFraction = 0.58;

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
      final response = _isSaved
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
    final Color panelColor = Colors.black.withOpacity(0.38);
    final parentAnim = _routeAnimation ?? const AlwaysStoppedAnimation(1.0);

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

            // Gradient bóng đen ở trên cùng (Fade theo nhịp 2)
            Positioned(
              top: 0, left: 0, right: 0, height: 140,
              child: FadeTransition(
                opacity: _headerFade,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),

            _buildTopBar(context),

            // Panel giao diện trượt lên ĐỒNG THỜI với phase 2!
            _buildDraggablePanel(dest, panelColor),
            _buildBottomCTA(),
          ],
        ),
      ),
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
        child: Image.asset('${dest.imagePath}', fit: BoxFit.cover),
      );
    }

    return AnimatedBuilder(
      animation: parentAnim,
      builder: (context, child) {
        final val = parentAnim.value;
        final cardRect = widget.cardRect!;
        
        // Cố định khi hoàn thành (kèm Parallax khi kéo panel)
        if (val == 1.0) {
          final t = ((_sheetFraction - 0.58) / (0.92 - 0.58)).clamp(0.0, 1.0);
          final double offsetY = -t * 50; 
          
          return Positioned.fill(
            child: Transform.translate(
              offset: Offset(0, offsetY),
              child: Image.asset('${dest.imagePath}', fit: BoxFit.cover),
            ),
          );
        }

        double currentTop, currentLeft, currentWidth, currentHeight, currentRadius;
        double cardInfoOpacity = 1.0;
        
        // Nhịp 1 (0.0 -> 0.4): Đẩy nguyên card lên GIỮA màn hình
        if (val <= 0.4) {
          // Dùng easeInOutCubic thay vì easeOutCubic để lúc quay về (pop) cũng mượt mà chậm dần!
          final p1 = Curves.easeInOutCubic.transform(val / 0.4);
          final targetTop = (screenH - cardRect.height) / 2;
          
          currentTop = lerpDouble(cardRect.top, targetTop, p1)!;
          currentLeft = cardRect.left;
          currentWidth = cardRect.width;
          currentHeight = cardRect.height;
          currentRadius = 28.0;
          cardInfoOpacity = 1.0;
        } 
        // Nhịp 2 (0.4 -> 1.0): Từ giữa màn hình phóng to ra TOÀN màn hình
        else {
          final p2 = Curves.easeInOutCubic.transform((val - 0.4) / 0.6);
          final startTop = (screenH - cardRect.height) / 2;
          
          currentTop = lerpDouble(startTop, 0, p2)!;
          currentLeft = lerpDouble(cardRect.left, 0, p2)!;
          currentWidth = lerpDouble(cardRect.width, screenW, p2)!;
          currentHeight = lerpDouble(cardRect.height, screenH, p2)!;
          currentRadius = lerpDouble(28.0, 0.0, p2)!;
          
          // Phai mờ giao diện card (chữ, nút) nhanh hơn tốc độ phóng to ảnh để ảnh sạch sẽ
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
                  color: Colors.black.withValues(alpha: 0.4),
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
                  Image.asset('${dest.imagePath}', fit: BoxFit.cover),
                  
                  // Giao diện card sao chép y hệt từ dashboard
                  if (cardInfoOpacity > 0)
                    Opacity(
                      opacity: cardInfoOpacity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Bottom gradient
                          Positioned(
                            left: 0, right: 0, bottom: 0, height: 180,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
                                ),
                              ),
                            ),
                          ),
                          
                          // Info text
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
                                      const Row(
                                        children: [
                                          Icon(Icons.pin_drop_rounded, color: Color(0xFFB5956A), size: 24),
                                          SizedBox(width: 4),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${dest.name}',
                                        style: const TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          shadows: [Shadow(color: Color(0x88000000), blurRadius: 8)],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${dest.price}',
                                        style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Arrow button
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
        child: Image.asset(
          dest.imagePath,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return SafeArea(
      child: FadeTransition(
        opacity: _headerFade,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _glassCircle(
                Icons.arrow_back_ios_new,
                () => Navigator.pop(context, {
                  'isSaved': _isSaved,
                  'isLiked': _isLiked,
                }),
              ),
              Row(
                children: [
                  _glassCircle(
                    Icons.share_rounded,
                    () {
                      // Tính năng chia sẻ sẽ được xử lý tại đây
                    },
                  ),
                  const SizedBox(width: 12),
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
                    activeIcon: Icons.bookmark_rounded,
                    inactiveIcon: Icons.bookmark_border_rounded,
                    onTap: _toggleSaved,
                    activeColor: const Color(0xFFD4AF7A),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDraggablePanel(Destination dest, Color panelColor) {
    return AnimatedBuilder(
      animation: _panelSlide,
      builder: (context, child) {
        final screenH = MediaQuery.of(context).size.height;
        // Chỉ dịch chuyển phần chiều cao thực tế của panel (khoảng 60% màn hình) 
        // để panel bắt đầu xuất hiện ngay lập tức cùng lúc với hiệu ứng phóng to ảnh
        final slideOffset = (1 - _panelSlide.value) * (screenH * 0.6);
        return Transform.translate(
          offset: Offset(0, slideOffset),
          child: child,
        );
      },
      child: DraggableScrollableSheet(
        controller: _sheetCtrl,
        initialChildSize: 0.58,
        minChildSize: 0.58,
        maxChildSize: 0.92,
        builder: (context, scrollCtrl) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: panelColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                  border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.22), width: 1),
                  ),
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
                        color: Colors.white.withOpacity(0.32),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${dest.name}',
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 28, fontWeight: FontWeight.w700,
                          color: Colors.white, height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.pin_drop_rounded, color: Color(0xFFB5956A), size: 22),
                          const SizedBox(width: 4),
                          Text('${dest.province}', style: const TextStyle(
                            fontFamily: 'Montserrat', fontSize: 14,
                            color: Colors.white,
                          )),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildStatsRow(),
                  const SizedBox(height: 28),
                  _sectionTitle('Điểm nổi bật'),
                  const SizedBox(height: 12),
                  _buildHighlightChips(),
                  const SizedBox(height: 28),
                  _sectionTitle('Giới thiệu'),
                  const SizedBox(height: 10),
                  _buildAboutSection(),
                  const SizedBox(height: 28),
                  _sectionTitle('Hình ảnh'),
                  const SizedBox(height: 12),
                  _buildGallery(dest),
                  const SizedBox(height: 28),
                  _sectionTitle('Đánh giá'),
                  const SizedBox(height: 12),
                  _buildReviewCard(
                    name: 'Minh Tuấn', rating: 5,
                    text: 'Phong cảnh tuyệt đẹp, dịch vụ rất chu đáo. Nhất định sẽ quay lại!',
                  ),
                  const SizedBox(height: 10),
                  _buildReviewCard(
                    name: 'Hồng Nhung', rating: 4,
                    text: 'Trải nghiệm rất đáng nhớ. Hướng dẫn viên nhiệt tình và thân thiện.',
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

  Widget _buildBottomCTA() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: AnimatedBuilder(
        animation: _panelSlide,
        builder: (context, child) {
          final slideOffset = (1 - _panelSlide.value) * 150.0;
          return Transform.translate(
            offset: Offset(0, slideOffset),
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.4),
                Colors.black.withOpacity(0.8),
              ],
            ),
          ),
          child: GestureDetector(
            onTap: () {},
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
                    blurRadius: 20, offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 10),
                  Text('ĐẶT TOUR NGAY', style: TextStyle(
                    fontFamily: 'Montserrat', fontWeight: FontWeight.w700,
                    fontSize: 16, color: Colors.white, letterSpacing: 1,
                  )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  // ── Glass circle button ──
  Widget _glassCircle(
    IconData icon,
    VoidCallback onTap, {
    Color iconColor = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: Icon(icon, color: iconColor, size: 20),
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
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
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

  // ── Section title ──
  Widget _sectionTitle(String text) {
    return Text(text, style: const TextStyle(
      fontFamily: 'Montserrat', fontSize: 18,
      fontWeight: FontWeight.w700, color: Colors.white,
    ));
  }

  // ── Stats row (rating, duration, group) ──
  Widget _buildStatsRow() {
    return Row(
      children: [
        _statCard(Icons.star_rounded, '4.8', 'Đánh giá', const Color(0xFFFFB74D)),
        const SizedBox(width: 12),
        _statCard(Icons.schedule_rounded, '3 ngày', 'Thời gian', const Color(0xFF4FC3F7)),
        const SizedBox(width: 12),
        _statCard(Icons.group_rounded, '2-10', 'Nhóm', const Color(0xFF81C784)),
      ],
    );
  }

  Widget _statCard(IconData icon, String value, String label, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.16),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withOpacity(0.34)),
        ),
        child: Column(
          children: [
            Icon(icon, color: accent, size: 24),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(
              fontFamily: 'Montserrat', fontSize: 16,
              fontWeight: FontWeight.w700, color: accent,
            )),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(
              fontFamily: 'Montserrat', fontSize: 11,
              color: Colors.white.withOpacity(0.8),
            )),
          ],
        ),
      ),
    );
  }

  // ── Highlight chips ──
  Widget _buildHighlightChips() {
    final highlights = [
      (Icons.landscape_rounded, 'Thiên nhiên'),
      (Icons.camera_alt_rounded, 'Chụp ảnh'),
      (Icons.restaurant_rounded, 'Ẩm thực'),
      (Icons.kayaking_rounded, 'Phiêu lưu'),
      (Icons.hotel_rounded, 'Khách sạn 4★'),
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
            Text(h.$2, style: TextStyle(
              fontFamily: 'Montserrat', fontSize: 13,
              color: Colors.white,
            )),
          ],
        ),
      )).toList(),
    );
  }

  // ── About section with expand ──
  Widget _buildAboutSection() {
    const fullText =
        'Đây là một trong những điểm đến tuyệt vời nhất tại Việt Nam. '
        'Bạn sẽ được trải nghiệm không gian thiên nhiên hùng vĩ, '
        'khám phá văn hóa bản địa đặc sắc và thưởng thức ẩm thực địa phương. '
        'Tour bao gồm đưa đón tận nơi, hướng dẫn viên tiếng Việt, '
        'và bữa ăn đặc sản vùng miền. Phù hợp cho gia đình, '
        'nhóm bạn hoặc du lịch cặp đôi lãng mạn.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fullText,
          maxLines: _showFullDesc ? 20 : 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Montserrat', fontSize: 14,
            color: Colors.white.withOpacity(0.84), height: 1.7,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => setState(() => _showFullDesc = !_showFullDesc),
          child: Text(
            _showFullDesc ? 'Thu gọn' : 'Xem thêm',
            style: const TextStyle(
              fontFamily: 'Montserrat', fontSize: 13,
              fontWeight: FontWeight.w600, color: Color(0xFFB5956A),
            ),
          ),
        ),
      ],
    );
  }

  // ── Gallery ──
  Widget _buildGallery(dynamic dest) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: List.generate(4, (i) => Padding(
          padding: EdgeInsets.only(right: i < 3 ? 10 : 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 130,
              child: Image.asset('${dest.imagePath}', fit: BoxFit.cover),
            ),
          ),
        )),
      ),
    );
  }

  // ── Review card ──
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
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFB5956A).withOpacity(0.2),
                child: Text(name[0], style: const TextStyle(
                  fontFamily: 'Montserrat', fontWeight: FontWeight.w700,
                  color: Color(0xFFB5956A),
                )),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(
                      fontFamily: 'Montserrat', fontSize: 14,
                      fontWeight: FontWeight.w600, color: Colors.white,
                    )),
                    Row(
                      children: List.generate(5, (i) => Icon(
                        i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                        color: const Color(0xFFFFB74D), size: 16,
                      )),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
