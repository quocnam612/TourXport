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
  final _budgetController = TextEditingController(); // Custom budget numeric controller

  // Per-page selected sets for chip groups
  final _q1 = <String>{};
  final _q2 = <String>{};
  final _q5 = <String>{};
  final _q6 = <String>{};
  final _q7_9 = <String>{}; // Merged activities + placeTypes
  final _q8 = <String>{};
  final _q10 = <String>{};
  final _q11 = <String>{};
  final _q13 = <String>{};
  final _q14 = <String>{};
  final _q15 = <String>{};

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
    _budgetController.dispose();
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
        pageBuilder: (_, __, ___) => SurveyResultScreen(
          answer: _answer,
          authToken: widget.authToken,
        ),
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
    // Q1 + 16 merged: travelFeelings and vibeStyle
    _answer.travelFeelings = _q1.toList();
    _answer.vibeStyle = _q1.isEmpty ? null : _q1.first;
    
    _answer.groupType = _q2.isEmpty ? null : _q2.first;
    
    final customBudgetStr = _budgetController.text.trim();
    _answer.budget = customBudgetStr.isNotEmpty ? "$customBudgetStr đ" : null;
    
    _answer.duration = _q5.isEmpty ? null : _q5.first;
    _answer.timing = _q6.isEmpty ? null : _q6.first;
    
    // Q7 + 9 merged
    final activitiesList = <String>[];
    final placeTypesList = <String>[];

    for (var opt in _q7_9) {
      switch (opt) {
        case 'Du lịch biển (Tắm biển, lặn biển, đảo)':
          activitiesList.addAll(['Tắm biển', 'Lặn biển']);
          placeTypesList.addAll(['Biển', 'Đảo']);
          break;
        case 'Du lịch núi (Trekking, leo núi, cắm trại)':
          activitiesList.addAll(['Trekking', 'Leo núi', 'Camping']);
          placeTypesList.addAll(['Núi', 'Rừng']);
          break;
        case 'Đô thị sôi động (Thành phố, bar/pub)':
          activitiesList.addAll(['Đi bar/pub', 'Chụp ảnh']);
          placeTypesList.addAll(['Thành phố hiện đại']);
          break;
        case 'Văn hóa & Cổ kính (Tham quan lịch sử, di sản)':
          activitiesList.addAll(['Khám phá văn hóa', 'Tham quan lịch sử']);
          placeTypesList.addAll(['Cổ kính / văn hóa']);
          break;
        case 'Ẩm thực & Giải trí (Món ăn địa phương, chợ đêm, cafe)':
          activitiesList.addAll(['Thử món ăn địa phương', 'Đi chợ đêm', 'Cafe chill']);
          placeTypesList.addAll(['Thành phố hiện đại']);
          break;
        case 'Đồng quê & Rừng núi hoang sơ (Đồng hoang, rừng thông)':
          activitiesList.addAll(['Cafe chill', 'Camping']);
          placeTypesList.addAll(['Đồng quê', 'Rừng']);
          break;
      }
    }
    _answer.activities = activitiesList.toSet().toList();
    _answer.placeTypes = placeTypesList.toSet().toList();

    _answer.accommodationPriority = _q8.isEmpty ? null : _q8.first;
    _answer.scheduleStyle = _q10.isEmpty ? null : _q10.first;
    _answer.travelDistance = _q11.isEmpty ? null : _q11.first;
    _answer.avoidList = _q13.toList();
    _answer.specialNeeds = _q14.toList();
    _answer.inspirationImages = _q15.toList();
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

  // ── Premium Numerical Counter for Duration ──
  Widget _buildDurationCounter() {
    int days = 3;
    if (_answer.duration != null) {
      final clean = _answer.duration!.replaceAll(RegExp(r'[^0-9]'), '');
      days = int.tryParse(clean) ?? 3;
    } else {
      _answer.duration = "3 ngày";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: days > 1 ? () {
              setState(() {
                _answer.duration = "${days - 1} ngày";
              });
            } : null,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: days > 1 ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.02),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.remove_rounded, color: days > 1 ? Colors.white : Colors.white.withOpacity(0.3)),
            ),
          ),
          Text(
            '$days ngày',
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          GestureDetector(
            onTap: days < 30 ? () {
              setState(() {
                _answer.duration = "${days + 1} ngày";
              });
            } : null,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: days < 30 ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.02),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_rounded, color: days < 30 ? Colors.white : Colors.white.withOpacity(0.3)),
            ),
          ),
        ],
      ),
    );
  }

  // Page 1: Câu 1 + 16 Merged — Cảm giác & Phong cách (Vibe)
  Widget _page1() => _pageWrap(
    section: _sectionLabels[0],
    children: [
      _questionTitle('Bạn muốn chuyến đi này\nmang lại cảm giác & vibe nào?'),
      _subLabel('Chọn tối đa 3 mục để thiết lập tốt nhất'),
      SurveyChipGroup(
        options: const [
          'Thư giãn & Chữa lành',
          'Khám phá & Phiêu lưu',
          'Sang trọng & Thượng lưu',
          'Gắn kết gia đình & bạn bè',
          'Trẻ trung & Năng động',
          'Lãng mạn & Ngọt ngào',
          'Văn hóa & Ẩm thực',
          'Thiên nhiên hoang sơ',
          'Check-in sống ảo',
          'Làm việc từ xa (Digital nomad)',
        ],
        selected: _q1, maxSelections: 3,
        icons: const {
          'Thư giãn & Chữa lành': Icons.self_improvement_rounded,
          'Khám phá & Phiêu lưu': Icons.explore_rounded,
          'Sang trọng & Thượng lưu': Icons.diamond_rounded,
          'Gắn kết gia đình & bạn bè': Icons.groups_rounded,
          'Trẻ trung & Năng động': Icons.surfing_rounded,
          'Lãng mạn & Ngọt ngào': Icons.favorite_rounded,
          'Văn hóa & Ẩm thực': Icons.restaurant_rounded,
          'Thiên nhiên hoang sơ': Icons.forest_rounded,
          'Check-in sống ảo': Icons.camera_alt_rounded,
          'Làm việc từ xa (Digital nomad)': Icons.laptop_mac_rounded,
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

  // Page 4: Câu 4 + 5 — Ngân sách & Thời gian
  Widget _page4() => _pageWrap(
    section: _sectionLabels[3],
    children: [
      _questionTitle('Ngân sách dự kiến\ntối đa của bạn?'),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            const Icon(Icons.monetization_on_rounded, color: Color(0xFFD4AF7A), size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  hintText: 'Nhập số tiền (VD: 5000000)',
                  hintStyle: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            const Text(
              'VNĐ',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD4AF7A),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildBudgetSuggestion('2.000.000'),
          _buildBudgetSuggestion('5.000.000'),
          _buildBudgetSuggestion('10.000.000'),
          _buildBudgetSuggestion('20.000.000'),
        ],
      ),
      _divider(),
      _questionTitle('Bạn dự định đi\ntrong bao nhiêu ngày?'),
      _subLabel('Nhấp hoặc chọn số ngày cụ thể'),
      _buildDurationCounter(),
    ],
  );

  Widget _buildBudgetSuggestion(String amount) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _budgetController.text = amount.replaceAll('.', '');
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Text(
          '$amount đ',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  // Page 5: Câu 6 + 7/9 Merged — Thời điểm & Địa điểm/Hoạt động
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
      _questionTitle('Kiểu địa điểm & hoạt động\nbạn yêu thích?'),
      _subLabel('Chọn nhiều mục để thiết lập sở thích'),
      SurveyChipGroup(
        options: const [
          'Du lịch biển (Tắm biển, lặn biển, đảo)',
          'Du lịch núi (Trekking, leo núi, cắm trại)',
          'Đô thị sôi động (Thành phố, bar/pub)',
          'Văn hóa & Cổ kính (Tham quan lịch sử, di sản)',
          'Ẩm thực & Giải trí (Món ăn địa phương, chợ đêm, cafe)',
          'Đồng quê & Rừng núi hoang sơ (Đồng hoang, rừng thông)',
        ],
        selected: _q7_9,
        icons: const {
          'Du lịch biển (Tắm biển, lặn biển, đảo)': Icons.beach_access_rounded,
          'Du lịch núi (Trekking, leo núi, cắm trại)': Icons.terrain_rounded,
          'Đô thị sôi động (Thành phố, bar/pub)': Icons.location_city_rounded,
          'Văn hóa & Cổ kính (Tham quan lịch sử, di sản)': Icons.temple_buddhist_rounded,
          'Ẩm thực & Giải trí (Món ăn địa phương, chợ đêm, cafe)': Icons.restaurant_rounded,
          'Đồng quê & Rừng núi hoang sơ (Đồng hoang, rừng thông)': Icons.forest_rounded,
        },
        onChanged: (v) => setState(() { _q7_9..clear()..addAll(v); })),
    ],
  );

  // Page 6: Câu 8 — Ưu tiên nơi ở
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

  // Page 9: Câu 15 — Chọn ảnh cảm hứng
  Widget _page9() => _pageWrap(
    section: _sectionLabels[8],
    children: [
      _questionTitle('Hãy chọn những bức ảnh\nkhiến bạn muốn đi ngay!'),
      _subLabel('Chọn phong cảnh truyền cảm hứng cho bạn nhất'),
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
    ],
  );
}
