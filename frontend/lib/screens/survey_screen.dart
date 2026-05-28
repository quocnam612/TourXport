import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/survey_answer.dart';
import '../widgets/survey_chips.dart';
import 'survey_result_screen.dart';

class SurveyScreen extends StatefulWidget {
  final String? authToken;
  const SurveyScreen({super.key, this.authToken});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen>
    with TickerProviderStateMixin {
  static const _totalPages = 6;
  int _currentPage = 0;
  final _answer = SurveyAnswer();
  late final PageController _pageCtrl;
  late final AnimationController _entranceCtrl;
  late final Animation<double> _entranceFade;

  // Controller nhập ngân sách
  final _budgetController = TextEditingController();

  // Các tập hợp lựa chọn câu hỏi (Single & Multi-select)
  final _qDestination = <String>{};
  final _qMainGoal = <String>{};

  static const _destinationOptions = [
    'Tuyên Quang',
    'Cao Bằng',
    'Lai Châu',
    'Lào Cai',
    'Thái Nguyên',
    'Điện Biên',
    'Lạng Sơn',
    'Sơn La',
    'Phú Thọ',
    'TP. Hà Nội',
    'TP. Hải Phòng',
    'Bắc Ninh',
    'Quảng Ninh',
    'Hưng Yên',
    'Ninh Bình',
    'Thanh Hóa',
    'Nghệ An',
    'Hà Tĩnh',
    'Quảng Trị',
    'TP. Huế',
    'TP. Đà Nẵng',
    'Quảng Ngãi',
    'Gia Lai',
    'Đắk Lắk',
    'Khánh Hòa',
    'Lâm Đồng',
    'Đồng Tháp',
    'An Giang',
    'Vĩnh Long',
    'TP. Cần Thơ',
    'Cà Mau',
  ];
  final _qSpendPriority = <String>{};
  final _qActivities = <String>{};
  final _qPlaceVibe = <String>{};
  final _qTransport = <String>{};
  final _qRoutePriority = <String>{};
  final _qAccommodationType = <String>{};
  final _qAccommodationPriority = <String>{};
  final _qDietaryRequirements = <String>{};
  final _qDiningStyle = <String>{};

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
    // Validate Page 1: Bắt buộc chọn tỉnh/thành phố và ngày đi ngày về
    if (_currentPage == 0) {
      if (_qDestination.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Vui lòng chọn tỉnh/thành phố bạn muốn đi.',
              style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }
      if (_answer.startDate == null || _answer.endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Vui lòng chọn ngày đi và ngày về để tiếp tục.',
              style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }
    }

    if (_currentPage < _totalPages - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic);
      setState(() => _currentPage++);
    } else {
      _syncAnswers();
      Navigator.push(
        context,
        PageRouteBuilder(
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
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                    parent: anim, curve: Curves.easeOutCubic)),
                child: child,
              ),
            );
          },
        ),
      ).then((result) {
        if (mounted && result == 'go_to_saved_tours') {
          Navigator.pop(context, 'go_to_saved_tours');
        }
      });
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
    _answer.selectedDestination = _qDestination.isEmpty ? null : _qDestination.first;
    _answer.mainGoal = _qMainGoal.isEmpty ? null : _qMainGoal.first;

    final customBudgetStr = _budgetController.text.trim();
    if (customBudgetStr.isNotEmpty) {
      _answer.budgetPerPerson = double.tryParse(customBudgetStr);
    } else {
      _answer.budgetPerPerson = null;
    }

    _answer.spendPriority = _qSpendPriority.isEmpty ? null : _qSpendPriority.first;
    _answer.activities = _qActivities.toList();
    _answer.placeVibe = _qPlaceVibe.isEmpty ? null : _qPlaceVibe.first;
    _answer.transportMode = _qTransport.isEmpty ? null : _qTransport.first;
    _answer.routePriority = _qRoutePriority.isEmpty ? null : _qRoutePriority.first;
    _answer.accommodationType = _qAccommodationType.isEmpty ? null : _qAccommodationType.first;
    _answer.accommodationPriority = _qAccommodationPriority.isEmpty ? null : _qAccommodationPriority.first;
    _answer.dietaryRequirements = _qDietaryRequirements.toList();
    _answer.diningStyle = _qDiningStyle.isEmpty ? null : _qDiningStyle.first;
  }

  // Chọn DateRange
  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _answer.startDate != null && _answer.endDate != null
          ? DateTimeRange(start: _answer.startDate!, end: _answer.endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD4AF7A),
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _answer.startDate = picked.start;
        _answer.endDate = picked.end;
      });
    }
  }

  static const _sectionLabels = [
    'PHẦN 1 — THÔNG TIN CHUYẾN ĐI',
    'PHẦN 2 — NGÂN SÁCH & CHI TIÊU',
    'PHẦN 3 — SỞ THÍCH & TRẢI NGHIỆM',
    'PHẦN 4 — PHƯƠNG TIỆN & DI CHUYỂN',
    'PHẦN 5 — LƯU TRÚ',
    'PHẦN 6 — ĂN UỐNG',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset('assets/images/login_bg.jpg', fit: BoxFit.cover),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.black.withOpacity(0.6),
            ),
          ),
          // Content
          SafeArea(
            child: FadeTransition(
              opacity: _entranceFade,
              child: Column(
                children: [
                  _buildTopBar(),
                  _buildProgressBar(),
                  Expanded(
                    child: PageView(
                      controller: _pageCtrl,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _pageTripInfo(),
                        _pageBudgetAndSpending(),
                        _pageInterestsAndExperience(),
                        _pageTransportAndRoute(),
                        _pageAccommodation(),
                        _pageDining(),
                      ],
                    ),
                  ),
                  _buildBottomButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top Bar ──
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: _prevPage,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const Spacer(),
          Text(
            '${_currentPage + 1} / $_totalPages',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  // ── Progress Bar ──
  Widget _buildProgressBar() {
    final progress = (_currentPage + 1) / _totalPages;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 6,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(3),
        ),
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
                  colors: [Color(0xFFD4AF7A), Color(0xFFB5956A)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Bottom Button ──
  Widget _buildBottomButton() {
    final isLast = _currentPage == _totalPages - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: GestureDetector(
        onTap: _nextPage,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD4AF7A), Color(0xFFB5956A)],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF7A).withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isLast ? 'Xem kết quả' : 'Tiếp tục',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isLast ? Icons.auto_awesome_rounded : Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Page Wrapper ──
  Widget _pageWrap({
    required String section,
    required List<Widget> children,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: const Color(0xFFD4AF7A).withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _questionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _subLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 4),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _divider() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Divider(
          color: Colors.white.withOpacity(0.1),
          thickness: 1,
        ),
      );

  // ── Premium Date Range Selector Card ──
  Widget _buildDateRangePicker() {
    final hasDates = _answer.startDate != null && _answer.endDate != null;
    String label = "Chọn ngày đi, ngày về";
    if (hasDates) {
      final start = "${_answer.startDate!.day}/${_answer.startDate!.month}/${_answer.startDate!.year}";
      final end = "${_answer.endDate!.day}/${_answer.endDate!.month}/${_answer.endDate!.year}";
      label = "$start  ➡  $end (${_answer.totalDays} ngày)";
    }

    return GestureDetector(
      onTap: _selectDateRange,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasDates ? const Color(0xFFD4AF7A) : Colors.white.withOpacity(0.12),
            width: hasDates ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_rounded,
              color: hasDates ? const Color(0xFFD4AF7A) : Colors.white.withOpacity(0.5),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 15,
                  fontWeight: hasDates ? FontWeight.w600 : FontWeight.w400,
                  color: hasDates ? Colors.white : Colors.white.withOpacity(0.5),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  // Helper cho Ngân Sách gợi ý
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

  // ═══════════════════════════════════════════════
  //  PAGES DEFINITIONS (12 QUESTIONS IN 6 SECTIONS)
  // ═══════════════════════════════════════════════

  // Page 1: Thông tin chuyến đi
  Widget _pageTripInfo() => _pageWrap(
        section: _sectionLabels[0],
        children: [
          _questionTitle('1. Bạn muốn đi du lịch ở tỉnh/thành phố nào?'),
          _subLabel('Chọn một điểm đến bạn mong muốn khám phá nhất'),
          SurveyChipGroup(
            options: _destinationOptions,
            selected: _qDestination,
            maxSelections: 1,
            onChanged: (v) => setState(() {
              _qDestination
                ..clear()
                ..addAll(v);
            }),
          ),
          _divider(),
          _questionTitle('2. Bạn dự định đi du lịch trong khoảng thời gian nào?'),
          _subLabel('Nhấp để chọn ngày bắt đầu và kết thúc chuyến đi'),
          _buildDateRangePicker(),
          _divider(),
          _questionTitle('3. Mục tiêu chính của chuyến đi là gì?'),
          _subLabel('Chọn một lựa chọn phù hợp nhất'),
          SurveyChipGroup(
            options: const [
              'Nghỉ dưỡng',
              'Du lịch, khám phá',
              'Công tác',
            ],
            selected: _qMainGoal,
            maxSelections: 1,
            icons: const {
              'Nghỉ dưỡng': Icons.spa_rounded,
              'Du lịch, khám phá': Icons.explore_rounded,
              'Công tác': Icons.business_center_rounded,
            },
            onChanged: (v) => setState(() {
              _qMainGoal
                ..clear()
                ..addAll(v);
            }),
          ),
        ],
      );

  // Page 2: Ngân sách & chi tiêu
  Widget _pageBudgetAndSpending() => _pageWrap(
        section: _sectionLabels[1],
        children: [
          _questionTitle('4. Mức ngân sách mong muốn cho chuyến đi là bao nhiêu/người?'),
          _subLabel('Nhập số tiền ước tính của bạn'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on_rounded, color: Color(0xFFD4AF7A), size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _budgetController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Nhập số tiền (VD: 5000000)',
                      hintStyle: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 14,
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
                    fontSize: 16,
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
          _questionTitle('5. Bạn ưu tiên chi tiêu nhiều hơn cho điều gì?'),
          _subLabel('Chọn phần hoạt động bạn muốn đầu tư tài chính nhiều nhất'),
          SurveyChipGroup(
            options: const [
              'Khách sạn',
              'Ăn uống',
              'Trải nghiệm',
              'Di chuyển',
            ],
            selected: _qSpendPriority,
            maxSelections: 1,
            icons: const {
              'Khách sạn': Icons.hotel_rounded,
              'Ăn uống': Icons.restaurant_rounded,
              'Trải nghiệm': Icons.local_activity_rounded,
              'Di chuyển': Icons.directions_car_rounded,
            },
            onChanged: (v) => setState(() {
              _qSpendPriority
                ..clear()
                ..addAll(v);
            }),
          ),
        ],
      );

  // Page 3: Sở thích & trải nghiệm
  Widget _pageInterestsAndExperience() => _pageWrap(
        section: _sectionLabels[2],
        children: [
          _questionTitle('6. Bạn thích hoạt động nào trong chuyến đi?'),
          _subLabel('Có thể chọn nhiều hoạt động yêu thích'),
          SurveyChipGroup(
            options: const [
              'Ngắm cảnh',
              'Chụp ảnh',
              'Khám phá văn hóa',
              'Ăn uống địa phương',
              'Cà phê chill',
              'Chợ đêm',
              'Thiên nhiên/sông nước',
            ],
            selected: _qActivities,
            icons: const {
              'Ngắm cảnh': Icons.photo_size_select_actual_rounded,
              'Chụp ảnh': Icons.camera_alt_rounded,
              'Khám phá văn hóa': Icons.castle_rounded,
              'Ăn uống địa phương': Icons.restaurant_menu_rounded,
              'Cà phê chill': Icons.local_cafe_rounded,
              'Chợ đêm': Icons.nightlight_round,
              'Thiên nhiên/sông nước': Icons.waves_rounded,
            },
            onChanged: (v) => setState(() {
              _qActivities
                ..clear()
                ..addAll(v);
            }),
          ),
          _divider(),
          _questionTitle('7. Bạn thích địa điểm mang phong cách nào?'),
          _subLabel('Chọn kiểu không khí mong muốn'),
          SurveyChipGroup(
            options: const [
              'Đông vui',
              'Yên tĩnh',
              'Thiên nhiên',
              'Mang tính văn hóa/tâm linh',
            ],
            selected: _qPlaceVibe,
            maxSelections: 1,
            icons: const {
              'Đông vui': Icons.people_rounded,
              'Yên tĩnh': Icons.nights_stay_rounded,
              'Thiên nhiên': Icons.park_rounded,
              'Mang tính văn hóa/tâm linh': Icons.temple_buddhist_rounded,
            },
            onChanged: (v) => setState(() {
              _qPlaceVibe
                ..clear()
                ..addAll(v);
            }),
          ),
        ],
      );

  // Page 4: Phương tiện & di chuyển
  Widget _pageTransportAndRoute() => _pageWrap(
        section: _sectionLabels[3],
        children: [
          _questionTitle('8. Bạn dự định đi phương tiện nào?'),
          _subLabel('Chọn phương tiện di chuyển chính'),
          SurveyChipGroup(
            options: const [
              'Xe máy',
              'Ô tô',
              'Xe khách',
              'Máy bay',
            ],
            selected: _qTransport,
            maxSelections: 1,
            icons: const {
              'Xe máy': Icons.two_wheeler_rounded,
              'Ô tô': Icons.airport_shuttle_rounded,
              'Xe khách': Icons.directions_bus_rounded,
              'Máy bay': Icons.flight_rounded,
            },
            onChanged: (v) => setState(() {
              _qTransport
                ..clear()
                ..addAll(v);
            }),
          ),
          _divider(),
          _questionTitle('9. Bạn muốn ưu tiên tiêu chí nào hơn?'),
          _subLabel('Tùy chọn phong cách tuyến đường'),
          SurveyChipGroup(
            options: const [
              'Tuyến đường đẹp',
              'Di chuyển nhanh',
              'Ít đổi phương tiện',
            ],
            selected: _qRoutePriority,
            maxSelections: 1,
            icons: const {
              'Tuyến đường đẹp': Icons.landscape_rounded,
              'Di chuyển nhanh': Icons.speed_rounded,
              'Ít đổi phương tiện': Icons.alt_route_rounded,
            },
            onChanged: (v) => setState(() {
              _qRoutePriority
                ..clear()
                ..addAll(v);
            }),
          ),
        ],
      );

  // Page 5: Lưu trú
  Widget _pageAccommodation() => _pageWrap(
        section: _sectionLabels[4],
        children: [
          _questionTitle('10. Bạn muốn ở loại hình nào?'),
          _subLabel('Chọn kiểu lưu trú ưa thích'),
          SurveyChipGroup(
            options: const [
              'Khách sạn',
              'Homestay',
              'Resort',
              'Nhà nghỉ',
            ],
            selected: _qAccommodationType,
            maxSelections: 1,
            icons: const {
              'Khách sạn': Icons.hotel_rounded,
              'Homestay': Icons.home_rounded,
              'Resort': Icons.holiday_village_rounded,
              'Nhà nghỉ': Icons.night_shelter_rounded,
            },
            onChanged: (v) => setState(() {
              _qAccommodationType
                ..clear()
                ..addAll(v);
            }),
          ),
          _divider(),
          _questionTitle('11. Bạn ưu tiên nơi lưu trú thế nào?'),
          _subLabel('Chọn tiêu chí quan trọng khi chọn chỗ ở'),
          SurveyChipGroup(
            options: const [
              'Gần trung tâm',
              'View đẹp',
              'Giá rẻ',
              'Yên tĩnh',
            ],
            selected: _qAccommodationPriority,
            maxSelections: 1,
            icons: const {
              'Gần trung tâm': Icons.location_on_rounded,
              'View đẹp': Icons.photo_size_select_actual_rounded,
              'Giá rẻ': Icons.savings_rounded,
              'Yên tĩnh': Icons.spa_rounded,
            },
            onChanged: (v) => setState(() {
              _qAccommodationPriority
                ..clear()
                ..addAll(v);
            }),
          ),
        ],
      );

  // Page 6: Ăn uống
  Widget _pageDining() => _pageWrap(
        section: _sectionLabels[5],
        children: [
          _questionTitle('12. Bạn có yêu cầu ăn uống đặc biệt không?'),
          _subLabel('Có thể chọn nhiều mục nếu có ràng buộc'),
          SurveyChipGroup(
            options: const [
              'Ăn chay',
              'Không ăn hải sản',
              'Không ăn cay',
              'Dị ứng thực phẩm',
            ],
            selected: _qDietaryRequirements,
            icons: const {
              'Ăn chay': Icons.eco_rounded,
              'Không ăn hải sản': Icons.no_food_rounded,
              'Không ăn cay': Icons.hot_tub_rounded,
              'Dị ứng thực phẩm': Icons.warning_amber_rounded,
            },
            onChanged: (v) => setState(() {
              _qDietaryRequirements
                ..clear()
                ..addAll(v);
            }),
          ),
          _divider(),
          _questionTitle('13. Bạn thích các quán ăn kiểu nào?'),
          _subLabel('Chọn phong cách ẩm thực ưa thích'),
          SurveyChipGroup(
            options: const [
              'Quán local',
              'Nhà hàng nổi tiếng',
              'Quán view đẹp',
              'Quán bình dân',
            ],
            selected: _qDiningStyle,
            maxSelections: 1,
            icons: const {
              'Quán local': Icons.storefront_rounded,
              'Nhà hàng nổi tiếng': Icons.stars_rounded,
              'Quán view đẹp': Icons.panorama_rounded,
              'Quán bình dân': Icons.restaurant_rounded,
            },
            onChanged: (v) => setState(() {
              _qDiningStyle
                ..clear()
                ..addAll(v);
            }),
          ),
        ],
      );
}
