import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/survey_answer.dart';
import '../widgets/survey_chips.dart';
import 'survey_result_screen.dart';

class SurveyScreen extends StatefulWidget {
  final String? authToken;
  final String userName;
  final String? avatarUrl;
  final bool embedded;
  final ValueChanged<Object?>? onNavigate;

  const SurveyScreen({
    super.key,
    this.authToken,
    this.userName = 'Username',
    this.avatarUrl,
    this.embedded = false,
    this.onNavigate,
  });

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen>
    with TickerProviderStateMixin {
  static const _totalPages = 3;
  static const _maxTripDays = 7;
  static const _maxTripNights = 7;
  static const _maxTravelers = 5;
  static const _minBudgetPerTravelerDay = 200000;
  static const _maxBudgetPerTravelerDay = 200000000;
  int _currentPage = 0;
  bool _isSidebarCollapsed = false;
  final _answer = SurveyAnswer();
  late final PageController _pageCtrl;
  late final AnimationController _entranceCtrl;
  late final Animation<double> _entranceFade;

  // Controller nhập ngân sách
  final _budgetController = TextEditingController();

  // Các tập hợp lựa chọn câu hỏi (Single & Multi-select)
  final _qDestination = <String>{};
  // số ngày, số đêm, người lớn, trẻ em
  int _days = 3;
  int _nights = 2;
  int _adults = 1;
  int _children = 0;

  int get _totalTravelers => _adults + _children;
  int get _minBudget => _totalTravelers * _days * _minBudgetPerTravelerDay;
  int get _maxBudget => _totalTravelers * _days * _maxBudgetPerTravelerDay;

  double _normalizeBudget(double value) {
    return value.clamp(_minBudget, _maxBudget).toDouble();
  }

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
    'Đồng Nai',
    'Tây Ninh',
    'TP. Hồ Chí Minh',
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
  String? _tripPace; // 'fast','balanced','relaxed'

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
    // No strict requirement on Page1: destinations can be empty (means all)
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
          if (widget.embedded) {
            widget.onNavigate?.call(result);
          } else {
            Navigator.pop(context, 'go_to_saved_tours');
          }
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
    } else if (widget.embedded) {
      widget.onNavigate?.call('go_to_explore');
    } else {
      Navigator.pop(context);
    }
  }

  void _syncAnswers() {
    _answer.selectedDestinations = _qDestination.toList();
    _answer.days = _days;
    _answer.nights = _nights;
    _answer.adults = _adults;
    _answer.children = _children;
    // Map localized labels to normalized pace keys
    if (_tripPace == null) {
      _answer.pace = null;
    } else if (_tripPace == 'Nhanh') {
      _answer.pace = 'fast';
    } else if (_tripPace == 'Cân bằng') {
      _answer.pace = 'balanced';
    } else if (_tripPace == 'Thư giãn') {
      _answer.pace = 'relaxed';
    } else {
      _answer.pace = _tripPace;
    }

    final customBudgetStr = _budgetController.text.trim();
    if (customBudgetStr.isNotEmpty) {
      final parsedBudget = double.tryParse(customBudgetStr);
      _answer.budgetPerPerson =
          parsedBudget == null ? null : _normalizeBudget(parsedBudget);
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

  bool get _isVi => Localizations.localeOf(context).languageCode == 'vi';

  String _getSectionLabel(int index) {
    if (_isVi) {
      final list = [
        'PHẦN 1 — THÔNG TIN CHUYẾN ĐI',
        'PHẦN 2 — NGÂN SÁCH & NHỊP ĐỘ',
        'PHẦN 3 — SỞ THÍCH & TRẢI NGHIỆM',
        'PHẦN 4 — PHƯƠNG TIỆN & DI CHUYỂN',
        'PHẦN 5 — LƯU TRÚ',
        'PHẦN 6 — ĂN UỐNG',
      ];
      return list[index];
    } else {
      final list = [
        'PART 1 — TRIP INFORMATION',
        'PART 2 — BUDGET & PACE',
        'PART 3 — PREFERENCES & EXPERIENCES',
        'PART 4 — TRANSPORTATION',
        'PART 5 — ACCOMMODATION',
        'PART 6 — DINING',
      ];
      return list[index];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (widget.embedded) {
      return SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: _buildSurveyContent(),
          ),
        ),
      );
    }

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
              child: isDesktop
                  ? Row(
                      children: [
                        ClipRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: _buildAppSidebar(),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 820),
                              child: _buildSurveyContent(),
                            ),
                          ),
                        ),
                      ],
                    )
                  : _buildSurveyContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveyContent() {
    return Column(
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
            ],
          ),
        ),
        _buildBottomButton(),
      ],
    );
  }

  Widget _buildAppSidebar() {
    final isGuest = widget.authToken == null || widget.authToken!.isEmpty;
    final isVi = _isVi;

    return SizedBox(
      width: _isSidebarCollapsed ? 80 : 260,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF070E0D).withOpacity(0.45),
          border: const Border(
            right: BorderSide(color: Colors.white12, width: 1),
          ),
        ),
        child: Column(
          children: [
            // Toggle button – fixed left edge
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(
                    _isSidebarCollapsed
                        ? Icons.menu_rounded
                        : Icons.menu_open_rounded,
                    color: const Color(0xFFD4AF7A),
                    size: 24,
                  ),
                  tooltip: _isSidebarCollapsed
                      ? (isVi ? 'Mở rộng sidebar' : 'Expand Sidebar')
                      : (isVi ? 'Thu gọn sidebar' : 'Collapse Sidebar'),
                  onPressed: () =>
                      setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Logo
            if (_isSidebarCollapsed)
              SizedBox(
                width: 80,
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF7A).withOpacity(0.15),
                          blurRadius: 20,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF7A).withOpacity(0.15),
                            blurRadius: 20,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 48,
                        height: 48,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'TourXport',
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        softWrap: false,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFD4AF7A),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 28),

            // User Profile Card
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: _isSidebarCollapsed ? 8 : 12,
              ),
              child: Container(
                padding: EdgeInsets.all(_isSidebarCollapsed ? 8 : 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: Row(
                  mainAxisAlignment: _isSidebarCollapsed
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    _buildSidebarAvatar(
                      size: _isSidebarCollapsed ? 34 : 38,
                      iconSize: _isSidebarCollapsed ? 18 : 20,
                    ),
                    if (!_isSidebarCollapsed) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              isVi ? 'Thành viên' : 'Member',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Navigation Links
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: _isSidebarCollapsed ? 8 : 16,
                ),
                children: [
                  _buildAppSidebarItem(
                    icon: Icons.home_rounded,
                    label: isVi ? 'Khám phá' : 'Explore',
                    onTap: () => Navigator.pop(context, 'go_to_explore'),
                  ),
                  const SizedBox(height: 8),
                  _buildAppSidebarItem(
                    icon: Icons.search_rounded,
                    label: isVi ? 'Tìm kiếm' : 'Search',
                    onTap: () => Navigator.pop(context, 'go_to_search'),
                  ),
                  const SizedBox(height: 8),
                  _buildAppSidebarItem(
                    icon: Icons.bookmark_rounded,
                    label: isVi ? 'Đã lưu' : 'Saved',
                    onTap: () => Navigator.pop(context, 'go_to_saved'),
                  ),
                  const SizedBox(height: 8),
                  _buildAppSidebarItem(
                    icon: Icons.explore_rounded,
                    label: isVi ? 'Lên lịch' : 'Generate',
                    isActive: true,
                    onTap: () {},
                  ),
                  const SizedBox(height: 8),
                  _buildAppSidebarItem(
                    icon: Icons.person_rounded,
                    label: isVi ? 'Tài khoản' : 'Account',
                    onTap: () => Navigator.pop(context, 'go_to_account'),
                  ),
                ],
              ),
            ),

            // Logout / Login button
            Padding(
              padding: EdgeInsets.all(_isSidebarCollapsed ? 8 : 20),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(
                    context,
                    isGuest ? 'go_to_account' : 'logout',
                  ),
                  borderRadius: BorderRadius.circular(16),
                  hoverColor: isGuest
                      ? const Color(0xFFD4AF7A).withOpacity(0.1)
                      : const Color(0xFFE74C3C).withOpacity(0.1),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _isSidebarCollapsed ? 0 : 16,
                      vertical: 14,
                    ),
                    child: Row(
                      mainAxisAlignment: _isSidebarCollapsed
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                      children: [
                        Icon(
                          isGuest ? Icons.login_rounded : Icons.logout_rounded,
                          color: isGuest
                              ? const Color(0xFFD4AF7A)
                              : const Color(0xFFE74C3C),
                          size: 22,
                        ),
                        if (!_isSidebarCollapsed) ...[
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              isGuest
                                  ? (isVi ? 'Tài khoản' : 'Account')
                                  : (isVi ? 'Đăng xuất' : 'Log Out'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isGuest
                                    ? const Color(0xFFD4AF7A)
                                    : const Color(0xFFE74C3C),
                              ),
                            ),
                          ),
                        ],
                      ],
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

  Widget _buildAppSidebarItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor: Colors.white.withOpacity(0.05),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: _isSidebarCollapsed ? 0 : 16,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF2D6A4F).withOpacity(0.25)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? const Color(0xFFD4AF7A).withOpacity(0.65)
                  : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: _isSidebarCollapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: isActive
                    ? const Color(0xFFD4AF7A)
                    : Colors.white.withOpacity(0.65),
                size: 22,
              ),
              if (!_isSidebarCollapsed) ...[
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                      color: isActive
                          ? Colors.white
                          : Colors.white.withOpacity(0.65),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarAvatar({
    required double size,
    required double iconSize,
  }) {
    final avatarUrl = widget.avatarUrl?.trim() ?? '';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.2),
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: avatarUrl.isNotEmpty
            ? Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _buildSidebarAvatarPlaceholder(iconSize),
              )
            : _buildSidebarAvatarPlaceholder(iconSize),
      ),
    );
  }

  Widget _buildSidebarAvatarPlaceholder(double iconSize) {
    return ColoredBox(
      color: Colors.white.withOpacity(0.2),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          color: Colors.white.withOpacity(0.9),
          size: iconSize,
        ),
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
                isLast
                    ? (_isVi ? 'Xem kết quả' : 'View Results')
                    : (_isVi ? 'Tiếp tục' : 'Continue'),
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
    String label = _isVi ? "Chọn ngày đi, ngày về" : "Select travel dates";
    if (hasDates) {
      final start = "${_answer.startDate!.day}/${_answer.startDate!.month}/${_answer.startDate!.year}";
      final end = "${_answer.endDate!.day}/${_answer.endDate!.month}/${_answer.endDate!.year}";
      label = _isVi ? "$start  ➡  $end (${_answer.totalDays} ngày)" : "$start  ➡  $end (${_answer.totalDays} days)";
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
        final parsedAmount = double.tryParse(amount.replaceAll('.', ''));
        setState(() {
          _budgetController.text = parsedAmount == null
              ? amount.replaceAll('.', '')
              : _normalizeBudget(parsedAmount).round().toString();
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

  Widget _numberPickerCard(
    String title,
    int value,
    ValueChanged<int> onChanged, {
    int minValue = 0,
    int maxValue = 999,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.6),
              )),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: () => onChanged((value - 1).clamp(minValue, maxValue).toInt()),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.remove, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Center(
                  child: Text('$value',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      )),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => onChanged((value + 1).clamp(minValue, maxValue).toInt()),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  PAGES DEFINITIONS (12 QUESTIONS IN 6 SECTIONS)
  // ═══════════════════════════════════════════════

  // Page 1: Thông tin chuyến đi
  Widget _pageTripInfo() => _pageWrap(
        section: _getSectionLabel(0),
        children: [
          _questionTitle(_isVi ? '1. Bạn muốn đi du lịch ở tỉnh/thành phố nào?' : '1. Which province/city do you want to travel to?'),
          _subLabel(_isVi ? 'Chọn một hoặc nhiều tỉnh/thành (bỏ trống để tìm tất cả)' : 'Select one or more provinces/cities (leave empty to search all)'),
          SurveyChipGroup(
            options: _destinationOptions,
            selected: _qDestination,
            maxSelections: 5,
            onChanged: (v) => setState(() {
              _qDestination
                ..clear()
                ..addAll(v);
            }),
          ),
          _divider(),
          _questionTitle(_isVi ? '2. Bạn dự định đi trong bao nhiêu ngày, bao nhiêu đêm?' : '2. How many days and nights do you plan to travel?'),
          _subLabel(_isVi ? 'Tối đa 7 ngày và 7 đêm' : 'Maximum of 7 days and 7 nights'),
          Row(
            children: [
              Expanded(
                child: _numberPickerCard(_isVi ? 'Số ngày' : 'Days', _days, (v) => setState(() {
                  _days = v;
                  final minNights = (_days - 1).clamp(0, _maxTripNights).toInt();
                  final maxNights = (_days + 1).clamp(0, _maxTripNights).toInt();
                  if (_nights < minNights) _nights = minNights;
                  if (_nights > maxNights) _nights = maxNights;
                }), minValue: 1, maxValue: _maxTripDays),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _numberPickerCard(_isVi ? 'Số đêm' : 'Nights', _nights, (v) => setState(() {
                  _nights = v;
                  final minDays = (_nights - 1).clamp(1, _maxTripDays).toInt();
                  final maxDays = (_nights + 1).clamp(1, _maxTripDays).toInt();
                  if (_days < minDays) _days = minDays;
                  if (_days > maxDays) _days = maxDays;
                }), minValue: 0, maxValue: _maxTripNights),
              ),
            ],
          ),
          _divider(),
          _questionTitle(_isVi ? '3. Số người tham gia chuyến đi' : '3. Number of travelers'),
          _subLabel(_isVi ? 'Tổng số người lớn và trẻ em tối đa 5 người' : 'Total adults and children up to 5 people'),
          Row(
            children: [
              Expanded(child: _numberPickerCard(_isVi ? 'Người lớn' : 'Adults', _adults, (v) => setState(() {
                _adults = v;
                if (_adults + _children > _maxTravelers) {
                  _children = _maxTravelers - _adults;
                }
              }), minValue: 1, maxValue: _maxTravelers - _children)),
              const SizedBox(width: 12),
              Expanded(child: _numberPickerCard(_isVi ? 'Trẻ em' : 'Children', _children, (v) => setState(() {
                _children = v;
              }), minValue: 0, maxValue: _maxTravelers - _adults)),
            ],
          ),
        ],
      );

  // Page 2: Ngân sách & chi tiêu
  Widget _pageBudgetAndSpending() => _pageWrap(
        section: _getSectionLabel(1),
        children: [
          _questionTitle(_isVi ? '4. Mức ngân sách mong muốn cho cả chuyến đi là bao nhiêu?' : '4. What is your desired budget for the entire trip?'),
          _subLabel(_isVi ? 'Giới hạn theo số người và số ngày: từ $_minBudget đến $_maxBudget VNĐ' : 'Limits based on travelers and days: from $_minBudget to $_maxBudget VND'),
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
                      hintText: _isVi ? 'Nhập số tiền (VD: 5000000)' : 'Enter amount (e.g., 5000000)',
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
                Text(
                  _isVi ? 'VNĐ' : 'VND',
                  style: const TextStyle(
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
          _questionTitle(_isVi ? '5. Nhịp độ chuyến đi' : '5. Trip pace'),
          _subLabel(_isVi ? 'Chọn nhịp độ mong muốn' : 'Choose your preferred pace'),
          SurveyChipGroup(
            options: const ['Nhanh', 'Cân bằng', 'Thư giãn'],
            selected: _tripPace == null ? <String>{} : <String>{_tripPace!},
            maxSelections: 1,
            icons: const {
              'Nhanh': Icons.speed_rounded,
              'Cân bằng': Icons.timeline_rounded,
              'Thư giãn': Icons.self_improvement_rounded,
            },
            onChanged: (v) => setState(() {
              _tripPace = v.isEmpty ? null : v.first;
            }),
          ),
          _divider(),
          _questionTitle(_isVi ? '6. Bạn dự định đi phương tiện nào?' : '6. Which transportation mode do you plan to use?'),
          _subLabel(_isVi ? 'Chọn phương tiện di chuyển chính' : 'Choose primary mode of transport'),
          SurveyChipGroup(
            options: const [
              'Xe máy',
              'Ô tô',
              'Xe khách',
              'Máy bay',
              'Tự động',
            ],
            selected: _qTransport,
            maxSelections: 1,
            icons: const {
              'Xe máy': Icons.two_wheeler_rounded,
              'Ô tô': Icons.airport_shuttle_rounded,
              'Xe khách': Icons.directions_bus_rounded,
              'Máy bay': Icons.flight_rounded,
              'Tự động': Icons.autorenew_rounded,
            },
            onChanged: (v) => setState(() {
              _qTransport
                ..clear()
                ..addAll(v);
            }),
          ),
        ],
      );

  // Page 3: Sở thích & trải nghiệm
  Widget _pageInterestsAndExperience() => _pageWrap(
        section: _getSectionLabel(2),
        children: [
          _questionTitle(_isVi ? '7. Bạn ưu tiên chi tiêu nhiều hơn cho điều gì?' : '7. What do you prioritize spending more on?'),
          _subLabel(_isVi ? 'Chọn phần hoạt động bạn muốn đầu tư tài chính nhiều nhất' : 'Choose the category you want to invest in the most'),
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
          _divider(),
          _questionTitle(_isVi ? '8. Bạn thích địa điểm mang phong cách nào?' : '8. What vibe do you prefer for your destinations?'),
          _subLabel(_isVi ? 'Chọn kiểu không khí mong muốn' : 'Choose preferred atmosphere'),
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
          _divider(),
          _questionTitle(_isVi ? '9. Bạn thích hoạt động nào trong chuyến đi?' : '9. What activities do you enjoy during the trip?'),
          _subLabel(_isVi ? 'Có thể chọn nhiều hoạt động yêu thích' : 'You can select multiple favorite activities'),
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
        ],
      );

  // Page 4: Phương tiện & di chuyển
  Widget _pageTransportAndRoute() => _pageWrap(
        section: _getSectionLabel(3),
        children: [
          _questionTitle(_isVi ? '8. Bạn dự định đi phương tiện nào?' : '8. Which transportation mode do you plan to use?'),
          _subLabel(_isVi ? 'Chọn phương tiện di chuyển chính' : 'Choose primary mode of transport'),
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
          _questionTitle(_isVi ? '9. Bạn muốn ưu tiên tiêu chí nào hơn?' : '9. Which criterion do you prioritize?'),
          _subLabel(_isVi ? 'Tùy chọn phong cách tuyến đường' : 'Route style options'),
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
        section: _getSectionLabel(4),
        children: [
          _questionTitle(_isVi ? '10. Bạn muốn ở loại hình nào?' : '10. What type of accommodation do you prefer?'),
          _subLabel(_isVi ? 'Chọn kiểu lưu trú ưa thích' : 'Select preferred accommodation type'),
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
          _questionTitle(_isVi ? '11. Bạn ưu tiên nơi lưu trú thế nào?' : '11. How do you prioritize accommodation?'),
          _subLabel(_isVi ? 'Chọn tiêu chí quan trọng khi chọn chỗ ở' : 'Choose key criteria for selecting accommodation'),
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
        section: _getSectionLabel(5),
        children: [
          _questionTitle(_isVi ? '12. Bạn có yêu cầu ăn uống đặc biệt không?' : '12. Do you have any dietary requirements?'),
          _subLabel(_isVi ? 'Có thể chọn nhiều mục nếu có ràng buộc' : 'Select multiple if applicable'),
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
          _questionTitle(_isVi ? '13. Bạn thích các quán ăn kiểu nào?' : '13. What dining style do you prefer?'),
          _subLabel(_isVi ? 'Chọn phong cách ẩm thực ưa thích' : 'Select preferred dining style'),
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
