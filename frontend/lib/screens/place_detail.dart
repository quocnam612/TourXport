import 'dart:ui';
import 'package:flutter/material.dart';

class PlaceDetailScreen extends StatefulWidget {
  final dynamic destination;

  const PlaceDetailScreen({super.key, required this.destination});

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  bool _isBookmarked = false;
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
    _sheetCtrl.addListener(_onSheetChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeAnimation == null) {
      _routeAnimation = ModalRoute.of(context)?.animation;
      final parentAnim = _routeAnimation ?? const AlwaysStoppedAnimation(1.0);
      
      _headerFade = CurvedAnimation(
        parent: parentAnim,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      );
      _panelSlide = CurvedAnimation(
        parent: parentAnim,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
      );
      _contentFade = CurvedAnimation(
        parent: parentAnim,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      );
    }
  }

  void _onSheetChanged() {
    setState(() => _sheetFraction = _sheetCtrl.size);
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
    const Color bgColor = Color(0xFF1C302D);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          _buildHeroImage(dest, screenH, bgColor),
          _buildTopBar(context),
          _buildDraggablePanel(dest, bgColor),
          _buildBottomCTA(bgColor),
        ],
      ),
    );
  }

  // ── Layout Components ──

  Widget _buildHeroImage(dynamic dest, double screenH, Color bgColor) {
    return Builder(
      builder: (context) {
        final t = ((_sheetFraction - 0.58) / (0.92 - 0.58)).clamp(0.0, 1.0);
        final imageHeight = screenH * (0.48 - t * 0.18);
        return SizedBox(
          height: imageHeight,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: 'hero_img_${dest.name}',
                flightShuttleBuilder: (flightContext, animation, flightDirection, fromContext, toContext) {
                  return AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                      final curvedAnim = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
                      final radius = flightDirection == HeroFlightDirection.push
                          ? lerpDouble(28, 0, curvedAnim.value)!
                          : 28.0;
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(radius),
                        child: Image.asset(dest.imagePath, fit: BoxFit.cover),
                      );
                    },
                  );
                },
                child: Image.asset(dest.imagePath, fit: BoxFit.cover),
              ),
              Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.4, 0.85, 1.0],
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                        Colors.transparent,
                        bgColor,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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
              _glassCircle(Icons.arrow_back_ios_new, () => Navigator.pop(context)),
              _glassCircle(
                _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                () => setState(() => _isBookmarked = !_isBookmarked),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDraggablePanel(dynamic dest, Color bgColor) {
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
        initialChildSize: 0.58,
        minChildSize: 0.58,
        maxChildSize: 0.92,
        builder: (context, scrollCtrl) {
          return Container(
            decoration: BoxDecoration(
              color: bgColor.withOpacity(0.97),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, offset: const Offset(0, -8)),
              ],
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
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dest.name,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 28, fontWeight: FontWeight.w700,
                          color: Colors.white, height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Color(0xFFE74C3C), size: 16),
                          const SizedBox(width: 4),
                          Text(dest.province, style: TextStyle(
                            fontFamily: 'Montserrat', fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
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
          );
        },
      ),
    );
  }

  Widget _buildBottomCTA(Color bgColor) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: AnimatedBuilder(
        animation: _panelSlide,
        builder: (context, child) {
          final screenH = MediaQuery.of(context).size.height;
          final slideOffset = (1 - _panelSlide.value) * screenH;
          return Transform.translate(
            offset: Offset(0, slideOffset),
            child: child,
          );
        },
        child: FadeTransition(
          opacity: _contentFade,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
            decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                bgColor.withOpacity(0.0),
                bgColor.withOpacity(0.95),
                bgColor,
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
      ),
    );
  }


  // ── Glass circle button ──
  Widget _glassCircle(IconData icon, VoidCallback onTap) {
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
            child: Icon(icon, color: Colors.white, size: 20),
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
          color: accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withOpacity(0.2)),
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
              color: Colors.white.withOpacity(0.5),
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
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(h.$1, size: 16, color: Colors.white.withOpacity(0.7)),
            const SizedBox(width: 6),
            Text(h.$2, style: TextStyle(
              fontFamily: 'Montserrat', fontSize: 13,
              color: Colors.white.withOpacity(0.85),
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
            color: Colors.white.withOpacity(0.6), height: 1.7,
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
              child: Image.asset(dest.imagePath, fit: BoxFit.cover),
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
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
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
            color: Colors.white.withOpacity(0.6), height: 1.5,
          )),
        ],
      ),
    );
  }
}