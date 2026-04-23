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
  int _selectedTab = 0; // 0 = Tổng quan, 1 = Nhận xét
  int _currentImageIndex = 0;
  late final PageController _imagePageCtrl;

  final DraggableScrollableController _sheetCtrl = DraggableScrollableController();
  double _sheetFraction = 0.50;

  Animation<double>? _routeAnimation;
  late Animation<double> _headerFade;
  late Animation<double> _panelSlide;
  late Animation<double> _contentFade;

  // All available gallery images for horizontal swipe
  List<String> get _galleryImages {
    final dest = widget.destination;
    return [
      dest.imagePath,
      'assets/images/halong.jpg',
      'assets/images/Hoi An.jpg',
      'assets/images/da_nang.jpg',
      'assets/images/phongnhakebang.jpg',
    ];
  }

  @override
  void initState() {
    super.initState();
    _imagePageCtrl = PageController();
    _sheetCtrl.addListener(_onSheetChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeAnimation == null) {
      _routeAnimation = ModalRoute.of(context)?.animation;
      final parentAnim = _routeAnimation ?? const AlwaysStoppedAnimation(1.0);
      _headerFade = CurvedAnimation(parent: parentAnim, curve: const Interval(0.0, 0.5, curve: Curves.easeOut));
      _panelSlide = CurvedAnimation(parent: parentAnim, curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic));
      _contentFade = CurvedAnimation(parent: parentAnim, curve: const Interval(0.0, 1.0, curve: Curves.easeOut));
    }
  }

  void _onSheetChanged() {
    setState(() => _sheetFraction = _sheetCtrl.size);
  }

  @override
  void dispose() {
    _sheetCtrl.removeListener(_onSheetChanged);
    _sheetCtrl.dispose();
    _imagePageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dest = widget.destination;
    final screenH = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // Full-screen background image with swipe
          _buildImageCarousel(dest, screenH),
          // Dot indicators
          _buildDotIndicators(),
          // Top bar
          _buildTopBar(context),
          // Draggable transparent panel
          _buildDraggablePanel(dest),
          // Bottom CTA
          _buildBottomCTA(),
        ],
      ),
    );
  }

  Widget _buildImageCarousel(dynamic dest, double screenH) {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _imagePageCtrl,
            itemCount: _galleryImages.length,
            onPageChanged: (i) => setState(() => _currentImageIndex = i),
            itemBuilder: (context, i) {
              if (i == 0) {
                return Hero(
                  tag: 'hero_img_${dest.name}',
                  child: Image.asset(_galleryImages[i], fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: const Color(0xFF2A4A3E))),
                );
              }
              return Image.asset(_galleryImages[i], fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFF2A4A3E)));
            },
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

  Widget _buildDotIndicators() {
    return Positioned(
      left: 0, right: 0,
      bottom: MediaQuery.of(context).size.height * 0.52,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_galleryImages.length, (i) {
          final isActive = i == _currentImageIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: isActive ? 10 : 8,
            height: isActive ? 10 : 8,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
            ),
          );
        }),
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
              _glassCircle(Icons.arrow_back_ios_new, () => Navigator.pop(context)),
              Row(
                children: [
                  _glassCircle(Icons.share_outlined, () {}),
                  const SizedBox(width: 10),
                  _glassCircle(
                    _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    () => setState(() => _isBookmarked = !_isBookmarked),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDraggablePanel(dynamic dest) {
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
                      // Drag handle
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
                      // Name
                      Text(dest.name, style: const TextStyle(
                        fontFamily: 'Montserrat', fontSize: 30, fontWeight: FontWeight.w700,
                        color: Colors.white, height: 1.2,
                      )),
                      const SizedBox(height: 6),
                      // Location + rating
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Color(0xFFD4AF7A), size: 16),
                          const SizedBox(width: 4),
                          Text(dest.province, style: TextStyle(
                            fontFamily: 'Montserrat', fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                          )),
                          const SizedBox(width: 16),
                          Text('Đánh giá', style: TextStyle(
                            fontFamily: 'Montserrat', fontSize: 13,
                            color: Colors.white.withOpacity(0.6),
                          )),
                          const SizedBox(width: 6),
                          const Icon(Icons.star_rounded, color: Color(0xFFFFB74D), size: 16),
                          const SizedBox(width: 2),
                          const Text('4.9', style: TextStyle(
                            fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.w600,
                            color: Color(0xFFFFB74D),
                          )),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Tab bar: Tổng quan / Nhận xét
                      _buildTabBar(),
                      const SizedBox(height: 20),
                      // Tab content
                      if (_selectedTab == 0) _buildOverviewTab(dest),
                      if (_selectedTab == 1) _buildReviewsTab(),
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

  // ── Overview tab ──
  Widget _buildOverviewTab(dynamic dest) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Mô tả'),
        const SizedBox(height: 8),
        Text(
          _getDescription(dest.name),
          style: TextStyle(
            fontFamily: 'Montserrat', fontSize: 14,
            color: Colors.white.withOpacity(0.7), height: 1.7,
          ),
        ),
        const SizedBox(height: 24),
        _sectionTitle('Điểm nổi bật'),
        const SizedBox(height: 12),
        _buildHighlightChips(),
      ],
    );
  }

  // ── Reviews tab ──
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

  Widget _buildBottomCTA() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: AnimatedBuilder(
        animation: _panelSlide,
        builder: (context, child) {
          final screenH = MediaQuery.of(context).size.height;
          final slideOffset = (1 - _panelSlide.value) * screenH;
          return Transform.translate(offset: Offset(0, slideOffset), child: child);
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
                  Colors.black.withOpacity(0.0),
                  Colors.black.withOpacity(0.70),
                  Colors.black.withOpacity(0.85),
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
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('Đường đi', style: TextStyle(
                    fontFamily: 'Montserrat', fontWeight: FontWeight.w700,
                    fontSize: 16, color: Colors.white, letterSpacing: 1,
                  )),
                ),
              ),
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
            color: Colors.white.withOpacity(0.6), height: 1.5,
          )),
        ],
      ),
    );
  }
}