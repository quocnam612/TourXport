import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/survey_answer.dart';
import '../widgets/survey_chips.dart';
import '../widgets/survey_slider.dart';
import '../widgets/survey_star_rating.dart';
import '../widgets/survey_image_grid.dart';
import 'survey_result_screen.dart';

class SurveyScreen extends StatefulWidget {
  final String? authToken;
  const SurveyScreen({super.key, this.authToken});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen>
    with TickerProviderStateMixin {
  static const _totalPages = 9;
  int _currentPage = 0;
  final _answer = SurveyAnswer();
  late final PageController _pageCtrl;
  late final AnimationController _entranceCtrl;
  late final Animation<double> _entranceFade;

  // Per-page selected sets for chip groups
  final _q1 = <String>{};
  final _q2 = <String>{};
  final _q4 = <String>{};
  final _q5 = <String>{};
  final _q6 = <String>{};
  final _q7 = <String>{};
  final _q8 = <String>{};
  final _q9 = <String>{};
  final _q10 = <String>{};
  final _q11 = <String>{};
  final _q13 = <String>{};
  final _q14 = <String>{};
  final _q15 = <String>{};
  final _q16 = <String>{};

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _entranceCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800));
    _entranceFade = CurvedAnimation(
      parent: _entranceCtrl, curve: Curves.easeOut);
    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic);
      setState(() => _currentPage++);
    } else {
      _syncAnswers();
      Navigator.push(context, PageRouteBuilder(
        pageBuilder: (_, __, ___) => SurveyResultScreen(answer: _answer),
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05), end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child));
        },
      ));
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic);
      setState(() => _currentPage--);
    } else {
      Navigator.pop(context);
    }
  }

  void _syncAnswers() {
    _answer.travelFeelings = _q1.toList();
    _answer.groupType = _q2.isEmpty ? null : _q2.first;
    _answer.budget = _q4.isEmpty ? null : _q4.first;
    _answer.duration = _q5.isEmpty ? null : _q5.first;
    _answer.timing = _q6.isEmpty ? null : _q6.first;
    _answer.activities = _q7.toList();
    _answer.accommodationPriority = _q8.isEmpty ? null : _q8.first;
    _answer.placeTypes = _q9.toList();
    _answer.scheduleStyle = _q10.isEmpty ? null : _q10.first;
    _answer.travelDistance = _q11.isEmpty ? null : _q11.first;
    _answer.avoidList = _q13.toList();
    _answer.specialNeeds = _q14.toList();
    _answer.inspirationImages = _q15.toList();
    _answer.vibeStyle = _q16.isEmpty ? null : _q16.first;
  }

  static const _sectionLabels = [
    'PHẦN 1 — MỤC TIÊU CHUYẾN ĐI',
    'PHẦN 1 — MỤC TIÊU CHUYẾN ĐI',
    'PHẦN 1 — MỤC TIÊU CHUYẾN ĐI',
    'PHẦN 2 — NGÂN SÁCH & THỜI GIAN',
    'PHẦN 3 — SỞ THÍCH CÁ NHÂN',
    'PHẦN 3 — SỞ THÍCH CÁ NHÂN',
    'PHẦN 4 — MỨC ĐỘ TRẢI NGHIỆM',
    'PHẦN 5 — RÀNG BUỘC & ƯU TIÊN',
    'PHẦN 6 — CÁ NHÂN HÓA',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(fit: StackFit.expand, children: [
        // BG
        Image.asset('assets/images/login_bg.jpg', fit: BoxFit.cover),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(color: Colors.black.withOpacity(0.55))),
        // Content
        SafeArea(
          child: FadeTransition(
            opacity: _entranceFade,
            child: Column(children: [
              _buildTopBar(),
              _buildProgressBar(),
              Expanded(
                child: PageView(
                  controller: _pageCtrl,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _page1(), _page2(), _page3(), _page4(), _page5(),
                    _page6(), _page7(), _page8(), _page9(),
                  ],
                ),
              ),
              _buildBottomButton(),
            ]),
          ),
        ),
      ]),
    );
  }

  // ── Top bar ──
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        GestureDetector(
          onTap: _prevPage,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.15))),
            child: const Icon(Icons.arrow_back_rounded,
              color: Colors.white, size: 20)),
        ),
        const Spacer(),
        Text('${_currentPage + 1} / $_totalPages',
          style: TextStyle(fontFamily: 'Montserrat', fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.8))),
        const Spacer(),
        const SizedBox(width: 40),
      ]),
    );
  }

  // ── Progress bar ──
  Widget _buildProgressBar() {
    final progress = (_currentPage + 1) / _totalPages;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 5,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(3)),
        child: Align(
          alignment: Alignment.centerLeft,
          child: AnimatedFractionallySizedBox(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: const LinearGradient(
                  colors: [Color(0xFFD4AF7A), Color(0xFFB5956A)])),
            ),
          ),
        ),
      ),
    );
  }

  // ── Bottom button ──
  Widget _buildBottomButton() {
    final isLast = _currentPage == _totalPages - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: GestureDetector(
        onTap: _nextPage,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD4AF7A), Color(0xFFB5956A)]),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF7A).withOpacity(0.3),
                blurRadius: 16, offset: const Offset(0, 4)),
            ]),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(isLast ? 'Xem kết quả' : 'Tiếp tục',
                style: const TextStyle(fontFamily: 'Montserrat', fontSize: 16,
                  fontWeight: FontWeight.w600, color: Colors.white,
                  letterSpacing: 0.5)),
              const SizedBox(width: 8),
              Icon(isLast ? Icons.auto_awesome_rounded : Icons.arrow_forward_rounded,
                color: Colors.white, size: 20),
            ]),
        ),
      ),
    );
  }

  // ── Page wrapper ──
  Widget _pageWrap({
    required String section,
    required List<Widget> children,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section,
            style: TextStyle(fontFamily: 'Montserrat', fontSize: 11,
              fontWeight: FontWeight.w600, letterSpacing: 1.5,
              color: const Color(0xFFD4AF7A).withOpacity(0.8))),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _questionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Text(text,
        style: const TextStyle(fontFamily: 'Montserrat', fontSize: 22,
          fontWeight: FontWeight.w600, color: Colors.white, height: 1.3)),
    );
  }

  Widget _subLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(text,
        style: TextStyle(fontFamily: 'Montserrat', fontSize: 13,
          fontWeight: FontWeight.w400,
          color: Colors.white.withOpacity(0.6), fontStyle: FontStyle.italic)),
    );
  }

  Widget _divider() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Divider(color: Colors.white.withOpacity(0.1), thickness: 1));

  // ═══════════════════════════════════════════════
  //  PAGES
  // ═══════════════════════════════════════════════

  // Page 1: Câu 1 — Cảm giác chuyến đi
  Widget _page1() => _pageWrap(
    section: _sectionLabels[0],
    children: [
      _questionTitle('Bạn muốn chuyến đi này\nmang lại cảm giác gì nhất?'),
      _subLabel('Chọn tối đa 3 mục'),
      SurveyChipGroup(
        options: const [
          'Thư giãn', 'Khám phá', 'Phiêu lưu', 'Sang trọng',
          'Chữa lành', 'Gắn kết bạn bè / gia đình', 'Check-in sống ảo',
          'Trải nghiệm văn hóa', 'Ẩm thực', 'Thiên nhiên'],
        selected: _q1, maxSelections: 3,
        icons: const {
          'Thư giãn': Icons.spa_rounded,
          'Khám phá': Icons.explore_rounded,
          'Phiêu lưu': Icons.terrain_rounded,
          'Sang trọng': Icons.diamond_rounded,
          'Chữa lành': Icons.self_improvement_rounded,
          'Gắn kết bạn bè / gia đình': Icons.groups_rounded,
          'Check-in sống ảo': Icons.camera_alt_rounded,
          'Trải nghiệm văn hóa': Icons.temple_buddhist_rounded,
          'Ẩm thực': Icons.restaurant_rounded,
          'Thiên nhiên': Icons.forest_rounded,
        },
        onChanged: (v) => setState(() { _q1..clear()..addAll(v); })),
    ],
  );

  // Page 2: Câu 2 — Hình thức đi
  Widget _page2() => _pageWrap(
    section: _sectionLabels[1],
    children: [
      _questionTitle('Bạn đi du lịch\ntheo hình thức nào?'),
      SurveyChipGroup(
        options: const [
          'Đi một mình', 'Cặp đôi', 'Nhóm bạn',
          'Gia đình', 'Công ty / team building'],
        selected: _q2, maxSelections: 1,
        icons: const {
          'Đi một mình': Icons.person_rounded,
          'Cặp đôi': Icons.favorite_rounded,
          'Nhóm bạn': Icons.group_rounded,
          'Gia đình': Icons.family_restroom_rounded,
          'Công ty / team building': Icons.business_rounded,
        },
        onChanged: (v) => setState(() { _q2..clear()..addAll(v); })),
    ],
  );

  // Page 3: Câu 3 — Sliders
  Widget _page3() => _pageWrap(
    section: _sectionLabels[2],
    children: [
      _questionTitle('Bạn muốn chuyến đi\nthiên về điều gì?'),
      _subLabel('Kéo thanh để chọn mức độ'),
      SurveyDualSlider(
        leftLabel: 'Nghỉ dưỡng', rightLabel: 'Khám phá',
        leftIcon: Icons.spa_rounded, rightIcon: Icons.explore_rounded,
        value: _answer.sliderRelaxExplore,
        onChanged: (v) => setState(() => _answer.sliderRelaxExplore = v)),
      SurveyDualSlider(
        leftLabel: 'Yên tĩnh', rightLabel: 'Sôi động',
        leftIcon: Icons.nights_stay_rounded, rightIcon: Icons.celebration_rounded,
        value: _answer.sliderQuietLively,
        onChanged: (v) => setState(() => _answer.sliderQuietLively = v)),
      SurveyDualSlider(
        leftLabel: 'Kế hoạch rõ ràng', rightLabel: 'Tự do ngẫu hứng',
        leftIcon: Icons.checklist_rounded, rightIcon: Icons.shuffle_rounded,
        value: _answer.sliderPlannedFree,
        onChanged: (v) => setState(() => _answer.sliderPlannedFree = v)),
      SurveyDualSlider(
        leftLabel: 'Thiên nhiên', rightLabel: 'Thành phố',
        leftIcon: Icons.forest_rounded, rightIcon: Icons.location_city_rounded,
        value: _answer.sliderNatureCity,
        onChanged: (v) => setState(() => _answer.sliderNatureCity = v)),
    ],
  );

  // Page 4: Câu 4 + 5
  Widget _page4() => _pageWrap(
    section: _sectionLabels[3],
    children: [
      _questionTitle('Ngân sách dự kiến\ncho toàn chuyến đi?'),
      SurveyChipGroup(
        options: const [
          'Dưới 2 triệu', '2–5 triệu', '5–10 triệu',
          '10–20 triệu', 'Trên 20 triệu'],
        selected: _q4, maxSelections: 1,
        icons: const {
          'Dưới 2 triệu': Icons.savings_rounded,
          '2–5 triệu': Icons.account_balance_wallet_rounded,
          '5–10 triệu': Icons.credit_card_rounded,
          '10–20 triệu': Icons.diamond_rounded,
          'Trên 20 triệu': Icons.workspace_premium_rounded,
        },
        onChanged: (v) => setState(() { _q4..clear()..addAll(v); })),
      _divider(),
      _questionTitle('Bạn dự định đi\ntrong bao lâu?'),
      SurveyChipGroup(
        options: const ['1 ngày', '2–3 ngày', '4–7 ngày', 'Trên 1 tuần'],
        selected: _q5, maxSelections: 1,
        icons: const {
          '1 ngày': Icons.today_rounded,
          '2–3 ngày': Icons.date_range_rounded,
          '4–7 ngày': Icons.calendar_month_rounded,
          'Trên 1 tuần': Icons.event_note_rounded,
        },
        onChanged: (v) => setState(() { _q5..clear()..addAll(v); })),
    ],
  );

  // Page 5: Câu 6 + 7
  Widget _page5() => _pageWrap(
    section: _sectionLabels[4],
    children: [
      _questionTitle('Bạn muốn đi\nvào thời điểm nào?'),
      SurveyChipGroup(
        options: const [
          'Cuối tuần', 'Dịp lễ', 'Mùa hè', 'Mùa đông', 'Không cố định'],
        selected: _q6, maxSelections: 1,
        onChanged: (v) => setState(() { _q6..clear()..addAll(v); })),
      _divider(),
      _questionTitle('Bạn thích hoạt động nào\nnhất khi du lịch?'),
      _subLabel('Chọn nhiều mục'),
      SurveyChipGroup(
        options: const [
          'Trekking', 'Tắm biển', 'Cafe chill', 'Chụp ảnh', 'Camping',
          'Khám phá văn hóa', 'Đi chợ đêm', 'Công viên giải trí',
          'Thử món ăn địa phương', 'Lặn biển', 'Leo núi',
          'Đi bar/pub', 'Tham quan lịch sử', 'Roadtrip'],
        selected: _q7,
        onChanged: (v) => setState(() { _q7..clear()..addAll(v); })),
    ],
  );

  // Page 6: Câu 8 + 9
  Widget _page6() => _pageWrap(
    section: _sectionLabels[5],
    children: [
      _questionTitle('Bạn ưu tiên điều gì\nnhất khi chọn nơi ở?'),
      SurveyChipGroup(
        options: const [
          'Giá rẻ', 'View đẹp', 'Gần trung tâm', 'Sang trọng',
          'Yên tĩnh', 'Nhiều tiện ích', 'Gần thiên nhiên'],
        selected: _q8, maxSelections: 1,
        icons: const {
          'Giá rẻ': Icons.savings_rounded,
          'View đẹp': Icons.panorama_rounded,
          'Gần trung tâm': Icons.location_on_rounded,
          'Sang trọng': Icons.star_rounded,
          'Yên tĩnh': Icons.nights_stay_rounded,
          'Nhiều tiện ích': Icons.room_service_rounded,
          'Gần thiên nhiên': Icons.park_rounded,
        },
        onChanged: (v) => setState(() { _q8..clear()..addAll(v); })),
      _divider(),
      _questionTitle('Bạn thích kiểu\nđịa điểm nào?'),
      _subLabel('Chọn nhiều mục'),
      SurveyChipGroup(
        options: const [
          'Biển', 'Núi', 'Thành phố hiện đại', 'Cổ kính / văn hóa',
          'Đồng quê', 'Đảo', 'Rừng', 'Sa mạc', 'Tuyết'],
        selected: _q9,
        icons: const {
          'Biển': Icons.beach_access_rounded,
          'Núi': Icons.terrain_rounded,
          'Thành phố hiện đại': Icons.location_city_rounded,
          'Cổ kính / văn hóa': Icons.temple_buddhist_rounded,
          'Đồng quê': Icons.grass_rounded,
          'Đảo': Icons.sailing_rounded,
          'Rừng': Icons.forest_rounded,
          'Sa mạc': Icons.wb_sunny_rounded,
          'Tuyết': Icons.ac_unit_rounded,
        },
        onChanged: (v) => setState(() { _q9..clear()..addAll(v); })),
    ],
  );

  // Page 7: Câu 10 + 11 + 12
  Widget _page7() => _pageWrap(
    section: _sectionLabels[6],
    children: [
      _questionTitle('Bạn thích lịch trình\nnhư thế nào?'),
      SurveyChipGroup(
        options: const [
          'Kín lịch, nhiều hoạt động', 'Cân bằng', 'Thư thả, ít điểm đến'],
        selected: _q10, maxSelections: 1,
        onChanged: (v) => setState(() { _q10..clear()..addAll(v); })),
      _divider(),
      _questionTitle('Bạn sẵn sàng di chuyển\nxa đến mức nào?'),
      SurveyChipGroup(
        options: const [
          'Dưới 2 giờ', '2–5 giờ', 'Bay nội địa', 'Bay quốc tế'],
        selected: _q11, maxSelections: 1,
        icons: const {
          'Dưới 2 giờ': Icons.directions_car_rounded,
          '2–5 giờ': Icons.directions_bus_rounded,
          'Bay nội địa': Icons.flight_rounded,
          'Bay quốc tế': Icons.public_rounded,
        },
        onChanged: (v) => setState(() { _q11..clear()..addAll(v); })),
      _divider(),
      _questionTitle('Bạn có thích thử\nnhững điều mới không?'),
      SurveyStarRating(
        label: 'Ăn món lạ',
        value: _answer.adventureFood,
        onChanged: (v) => setState(() => _answer.adventureFood = v)),
      SurveyStarRating(
        label: 'Trải nghiệm mạo hiểm',
        value: _answer.adventureExtreme,
        onChanged: (v) => setState(() => _answer.adventureExtreme = v)),
      SurveyStarRating(
        label: 'Khám phá nơi ít người biết',
        value: _answer.adventureHidden,
        onChanged: (v) => setState(() => _answer.adventureHidden = v)),
    ],
  );

  // Page 8: Câu 13 + 14
  Widget _page8() => _pageWrap(
    section: _sectionLabels[7],
    children: [
      _questionTitle('Bạn có điều gì muốn\ntránh trong chuyến đi?'),
      _subLabel('Chọn nhiều mục'),
      SurveyChipGroup(
        options: const [
          'Đông người', 'Quá đắt đỏ', 'Di chuyển nhiều',
          'Hoạt động mạo hiểm', 'Nơi quá nóng', 'Nơi quá lạnh',
          'Leo núi nhiều', 'Tiệc tùng ồn ào'],
        selected: _q13,
        onChanged: (v) => setState(() { _q13..clear()..addAll(v); })),
      _divider(),
      _questionTitle('Bạn có yêu cầu\nđặc biệt nào không?'),
      SurveyChipGroup(
        options: const [
          'Ăn chay', 'Có trẻ nhỏ', 'Người lớn tuổi đi cùng',
          'Dị ứng thức ăn', 'Cần internet mạnh', 'Không có yêu cầu'],
        selected: _q14,
        onChanged: (v) => setState(() { _q14..clear()..addAll(v); })),
    ],
  );

  // Page 9: Câu 15 + 16
  Widget _page9() => _pageWrap(
    section: _sectionLabels[8],
    children: [
      _questionTitle('Hãy chọn những bức ảnh\nkhiến bạn muốn đi ngay!'),
      SurveyImageGrid(
        items: const [
          SurveyImageItem(label: 'Bãi biển hoàng hôn', assetPath: 'assets/images/nha_trang.jpg'),
          SurveyImageItem(label: 'Thành phố đêm', assetPath: 'assets/images/da_nang.jpg'),
          SurveyImageItem(label: 'Núi sương mù', assetPath: 'assets/images/fansipan.jpg'),
          SurveyImageItem(label: 'Resort sang trọng', assetPath: 'assets/images/phan_thiet.jpg'),
          SurveyImageItem(label: 'Chợ đêm', assetPath: 'assets/images/Hoi An.jpg'),
          SurveyImageItem(label: 'Rừng thông', assetPath: 'assets/images/phongnhakebang.jpg'),
          SurveyImageItem(label: 'Phố cổ', assetPath: 'assets/images/hue.jpg'),
          SurveyImageItem(label: 'Du thuyền', assetPath: 'assets/images/ha_long_bay_sailing.jpg'),
          SurveyImageItem(label: 'Vịnh biển', assetPath: 'assets/images/Ha Long Bay.jpg'),
        ],
        selected: _q15,
        onChanged: (v) => setState(() { _q15..clear()..addAll(v); })),
      _divider(),
      _questionTitle('Bạn muốn chuyến đi này\ngiống vibe nào?'),
      SurveyChipGroup(
        options: const [
          'Chill chữa lành', 'Phiêu lưu khám phá', 'Luxury lifestyle',
          'Tuổi trẻ năng động', 'Romantic', 'Digital nomad', 'Backpacker'],
        selected: _q16, maxSelections: 1,
        icons: const {
          'Chill chữa lành': Icons.self_improvement_rounded,
          'Phiêu lưu khám phá': Icons.hiking_rounded,
          'Luxury lifestyle': Icons.diamond_rounded,
          'Tuổi trẻ năng động': Icons.surfing_rounded,
          'Romantic': Icons.favorite_rounded,
          'Digital nomad': Icons.laptop_mac_rounded,
          'Backpacker': Icons.backpack_rounded,
        },
        onChanged: (v) => setState(() { _q16..clear()..addAll(v); })),
    ],
  );
}
