import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/destination.dart';
import '../models/saved_tour.dart';
import '../api/api.dart';
import 'saved_tour_detail.dart';

class SavedPlacesSection extends StatefulWidget {
  final Animation<double> entranceAnimation;
  final List<Destination> savedDestinations;
  final Set<String> updatingSavedNames;
  final bool isLoading;
  final VoidCallback onBack;
  final Future<void> Function(Destination dest, BuildContext cardContext)
      onOpenDetail;
  final Future<bool> Function(Destination dest) onToggleSaved;
  final bool isGuest;
  final String? authToken;
  final String userName;
  final String? avatarUrl;
  final int initialTabIndex;

  const SavedPlacesSection({
    super.key,
    required this.entranceAnimation,
    required this.savedDestinations,
    required this.updatingSavedNames,
    required this.isLoading,
    required this.onBack,
    required this.onOpenDetail,
    required this.onToggleSaved,
    this.isGuest = false,
    this.authToken,
    this.userName = 'Username',
    this.avatarUrl,
    this.initialTabIndex = 0,
    this.onSelectTour,
    this.onNavigateMain,
  });

  final Function(SavedTour tour)? onSelectTour;
  final ValueChanged<String>? onNavigateMain;

  @override
  State<SavedPlacesSection> createState() => _SavedPlacesSectionState();
}

class _SavedPlacesSectionState extends State<SavedPlacesSection> {
  int _activeTab = 0; // 0: Places (Địa điểm), 1: Itineraries (Lịch trình)
  List<SavedTour> _savedTours = [];
  bool _isLoadingTours = false;
  String? _toursError;

  bool get _isVi => Localizations.localeOf(context).languageCode == 'vi';

  String _translateProvince(String prov) {
    if (_isVi) return prov;
    final maps = {
      'Đà Nẵng': 'Da Nang',
      'Hà Nội': 'Hanoi',
      'TP. Hồ Chí Minh': 'Ho Chi Minh City',
      'Quảng Nam': 'Quang Nam',
      'Quảng Ninh': 'Quang Ninh',
      'Thừa Thiên Huế': 'Thua Thien Hue',
      'Khánh Hòa': 'Khanh Hoa',
      'Lào Cai': 'Lao Cai',
      'Ninh Bình': 'Ninh Binh',
      'Bình Thuận': 'Binh Thuan',
      'Kiên Giang': 'Kien Giang',
      'Bà Rịa - Vũng Tàu': 'Ba Ria - Vung Tau',
      'Quảng Bình': 'Quang Binh',
      'An Giang': 'An Giang',
      'Bạc Liêu': 'Bac Lieu',
      'Bắc Giang': 'Bac Giang',
      'Bắc Kạn': 'Bac Kan',
      'Bắc Ninh': 'Bac Ninh',
      'Bến Tre': 'Ben Tre',
      'Bình Dương': 'Binh Duong',
      'Bình Định': 'Binh Dinh',
      'Bình Phước': 'Binh Phước',
      'Cà Mau': 'Ca Mau',
      'Cao Bằng': 'Cao Bang',
      'Cần Thơ': 'Can Tho',
      'Đắk Lắk': 'Dak Lak',
      'Đắk Nông': 'Dak Nong',
      'Điện Biên': 'Dien Bien',
      'Đồng Nai': 'Dong Nai',
      'Đồng Tháp': 'Dong Thap',
      'Gia Lai': 'Gia Lai',
      'Hà Giang': 'Ha Giang',
      'Hà Nam': 'Ha Nam',
      'Hà Tĩnh': 'Ha Tinh',
      'Hải Dương': 'Hai Duong',
      'Hải Phòng': 'Hai Phong',
      'Hậu Giang': 'Hau Giang',
      'Hòa Bình': 'Hoa Binh',
      'Hưng Yên': 'Hung Yen',
      'Kon Tum': 'Kon Tum',
      'Lai Châu': 'Lai Chau',
      'Lạng Sơn': 'Lang Son',
      'Lâm Đồng': 'Lam Dong',
      'Long An': 'Long An',
      'Nam Định': 'Nam Dinh',
      'Nghệ An': 'Nghe An',
      'Ninh Thuận': 'Ninh Thuan',
      'Phú Thọ': 'Phu Tho',
      'Phú Yên': 'Phu Yen',
      'Quảng Ngãi': 'Quang Ngai',
      'Quảng Trị': 'Quang Tri',
      'Sóc Trăng': 'Soc Trang',
      'Sơn La': 'Son La',
      'Tây Ninh': 'Tay Ninh',
      'Thái Bình': 'Thai Binh',
      'Thái Nguyên': 'Thai Nguyen',
      'Thanh Hóa': 'Thanh Hoa',
      'Tiền Giang': 'Tien Giang',
      'Trà Vinh': 'Tra Vinh',
      'Tuyên Quang': 'Tuyen Quang',
      'Vĩnh Long': 'Vinh Long',
      'Vĩnh Phúc': 'Vinh Phuc',
      'Yên Bái': 'Yen Bai',
    };
    return maps[prov] ?? prov;
  }

  IconData _visibilityIcon(String visibility) {
    switch (visibility.toLowerCase()) {
      case 'private':
      case 'hidden':
        return Icons.lock_rounded;
      case 'protected':
      case 'shared':
        return Icons.groups_rounded;
      default:
        return Icons.public_rounded;
    }
  }

  String _visibilityLabel(String visibility) {
    switch (visibility.toLowerCase()) {
      case 'private':
      case 'hidden':
        return _isVi ? 'Riêng tư' : 'Private';
      case 'protected':
      case 'shared':
        return _isVi ? 'Chia sẻ' : 'Shared';
      default:
        return _isVi ? 'Công khai' : 'Public';
    }
  }

  void _updateTourDetailRoute(String tourId) {
    if (!kIsWeb || tourId.isEmpty) return;
    SystemNavigator.routeInformationUpdated(
      location: Uri(path: '/tour', queryParameters: {'id': tourId}).toString(),
      replace: false,
    );
  }

  void _restoreSavedRoute() {
    if (!kIsWeb) return;
    SystemNavigator.routeInformationUpdated(
      location: '/saved',
      replace: true,
    );
  }

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTabIndex;
    if (!widget.isGuest && widget.authToken != null) {
      _fetchSavedTours();
    }
  }

  @override
  void didUpdateWidget(covariant SavedPlacesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTabIndex != oldWidget.initialTabIndex) {
      setState(() {
        _activeTab = widget.initialTabIndex;
      });
      if (_activeTab == 1 && !widget.isGuest && widget.authToken != null) {
        _fetchSavedTours();
      }
    }
  }

  Future<void> _fetchSavedTours() async {
    if (widget.isGuest || widget.authToken == null) return;
    setState(() {
      _isLoadingTours = true;
      _toursError = null;
    });

    try {
      final response = await apiGet('/tours/my-tours', token: widget.authToken);
      if (response.statusCode == 200) {
        final decoded = tryDecodeJsonObject(response.body);
        if (decoded != null && decoded['success'] == true) {
          final list = decoded['data'] as List? ?? [];
          setState(() {
            _savedTours = list.map((item) => SavedTour.fromJson(item)).toList();
            _isLoadingTours = false;
          });
          return;
        }
      }
      setState(() {
        _toursError = 'error_loading';
        _isLoadingTours = false;
      });
    } catch (e) {
      setState(() {
        _toursError = 'error_connection';
        _isLoadingTours = false;
      });
    }
  }

  Future<void> _deleteSavedTour(String id) async {
    if (widget.authToken == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B2321),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(_isVi ? 'Xóa lịch trình' : 'Delete Itinerary', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(_isVi ? 'Bạn có chắc chắn muốn xóa lịch trình này khỏi danh sách đã lưu?' : 'Are you sure you want to delete this itinerary from your saved list?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_isVi ? 'Hủy' : 'Cancel', style: const TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_isVi ? 'Xóa' : 'Delete', style: const TextStyle(color: Color(0xFFE74C3C), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await apiDeleteJson('/tours/my-tours/$id', {}, token: widget.authToken);
      if (response.statusCode == 200) {
        setState(() {
          _savedTours.removeWhere((t) => t.id == id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isVi ? 'Đã xóa lịch trình thành công' : 'Itinerary deleted successfully')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isVi ? 'Xóa lịch trình thất bại' : 'Failed to delete itinerary')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isVi ? 'Lỗi kết nối máy chủ' : 'Server connection error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        key: const ValueKey<String>('saved_tab'),
        children: [
          _buildTopBar(),
          const SizedBox(height: 8),
          _buildTitle(),
          const SizedBox(height: 16),
          _buildCustomTabBar(),
          const SizedBox(height: 16),
          Expanded(
            child: _activeTab == 0
                ? widget.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : _buildSavedPlacesView()
                : _isLoadingTours
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : _buildSavedToursView(),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return FadeTransition(
      opacity: widget.entranceAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _activeTab = 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _activeTab == 0
                          ? const Color(0xFFD4AF7A)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _isVi ? 'Địa điểm' : 'Places',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _activeTab == 0
                            ? const Color(0xFF0C1412)
                            : Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _activeTab = 1);
                    _fetchSavedTours();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: _activeTab == 1
                          ? const Color(0xFFD4AF7A)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _isVi ? 'Lịch trình' : 'Itineraries',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _activeTab == 1
                            ? const Color(0xFF0C1412)
                            : Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return FadeTransition(
      opacity: widget.entranceAnimation,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 6),
        child: Row(
          children: [
            GestureDetector(
              onTap: widget.onBack,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.14),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.14),
                ),
              ),
              child: const Icon(
                Icons.bookmark_rounded,
                color: Color(0xFFD4AF7A),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isVi ? 'Danh sách đã lưu' : 'Saved List',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _activeTab == 0
                        ? (_isVi ? '${widget.savedDestinations.length} địa điểm' : '${widget.savedDestinations.length} places')
                        : (_isVi ? '${_savedTours.length} lịch trình' : '${_savedTours.length} itineraries'),
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.72),
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

  Widget _buildTitle() {
    return FadeTransition(
      opacity: widget.entranceAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(widget.entranceAnimation),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _activeTab == 0 
                  ? (_isVi ? 'Những nơi bạn muốn đến' : 'Places you want to visit') 
                  : (_isVi ? 'Hành trình của riêng bạn' : 'Your own itineraries'),
              style: const TextStyle(
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

  Widget _buildSavedPlacesView() {
    if (widget.savedDestinations.isEmpty) {
      return _buildEmptyStateView(
        icon: Icons.bookmark_border_rounded,
        title: widget.isGuest 
            ? (_isVi ? 'Đăng nhập để sử dụng tính năng này' : 'Sign in to use this feature') 
            : (_isVi ? 'Chưa có địa điểm nào được lưu' : 'No saved places yet'),
        subtitle: _isVi ? 'Hãy thêm địa điểm bạn muốn đến vào lần tới' : 'Add places you want to visit next time',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 110),
      itemCount: widget.savedDestinations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final dest = widget.savedDestinations[index];
        final isBusy = widget.updatingSavedNames.contains(dest.name);

        return Builder(
          builder: (cardContext) {
            return GestureDetector(
              onTap: () => widget.onOpenDetail(dest, cardContext),
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.28),
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
                      Destination.buildImage(
                        dest.imagePath,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.12),
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 14,
                        right: 14,
                        child: GestureDetector(
                          onTap: isBusy ? null : () => widget.onToggleSaved(dest),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.18),
                              ),
                            ),
                            child: isBusy
                                ? const Padding(
                                    padding: EdgeInsets.all(11),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.bookmark_remove_rounded,
                                    color: Color(0xFFD4AF7A),
                                  ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.pin_drop_rounded,
                                  color: Color(0xFFB5956A),
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    dest.name,
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _translateProvince(dest.province),
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.92),
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
      },
    );
  }

  Widget _buildSavedToursView() {
    if (widget.isGuest) {
      return _buildEmptyStateView(
        icon: Icons.explore_off_rounded,
        title: _isVi ? 'Đăng nhập để xem lịch trình' : 'Sign in to view itineraries',
        subtitle: _isVi 
            ? 'Hãy đăng nhập tài khoản của bạn để lưu và quản lý các lịch trình du lịch cá nhân hóa.'
            : 'Please sign in to your account to save and manage personalized travel itineraries.',
      );
    }

    if (_toursError != null) {
      final errorText = _toursError == 'error_connection'
          ? (_isVi ? 'Lỗi kết nối đến máy chủ' : 'Server connection error')
          : (_isVi ? 'Không thể tải lịch trình du lịch' : 'Cannot load travel itineraries');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              errorText,
              style: const TextStyle(color: Colors.white70, fontFamily: 'Montserrat', fontSize: 16),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchSavedTours,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF7A),
                foregroundColor: const Color(0xFF0C1412),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(_isVi ? 'Thử lại' : 'Retry', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    if (_savedTours.isEmpty) {
      return _buildEmptyStateView(
        icon: Icons.explore_outlined,
        title: _isVi ? 'Chưa có lịch trình nào' : 'No itineraries yet',
        subtitle: _isVi 
            ? 'Hãy thực hiện khảo sát thông minh để AI tạo riêng cho bạn một lịch trình du lịch tuyệt vời.'
            : 'Take the smart survey to let AI generate an amazing travel itinerary just for you.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 110),
      itemCount: _savedTours.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final tour = _savedTours[index];
        return GestureDetector(
          onTap: () async {
            // Fetch full tour detail and open detail screen
            if (widget.authToken == null) return;
            try {
              // saved tours are private; fetch via authenticated user's my-tours endpoint
              final resp = await apiGet('/tours/my-tours/${tour.id}', token: widget.authToken);
              if (resp.statusCode == 200) {
                final decoded = tryDecodeJsonObject(resp.body);
                if (decoded != null) {
                  final data = decoded['data'] ?? decoded;
                  _updateTourDetailRoute(tour.id);
                  final result = await Navigator.of(context).push<String>(
                    MaterialPageRoute(
                      builder: (_) => SavedTourDetailScreen(
                        tourTitle: tour.title,
                        tourJson: data is Map<String, dynamic> ? data : {},
                        authToken: widget.authToken,
                        userName: widget.userName,
                        avatarUrl: widget.avatarUrl,
                      ),
                    ),
                  );
                  _restoreSavedRoute();
                  if (result != null) {
                    widget.onNavigateMain?.call(result);
                  }
                  return;
                }
              }
              // fallback: open activation dialog if detail not available
            } catch (e) {
              // ignore and fallback
            }

            if (widget.onSelectTour != null) {
              widget.onSelectTour!(tour);
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF12201C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  title: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFFD4AF7A), size: 28),
                      const SizedBox(width: 12),
                      Text(
                        _isVi ? 'Kích hoạt lịch trình' : 'Activate Itinerary',
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  content: Text(
                    _isVi 
                        ? 'Đã chọn "${tour.title}" làm lịch trình hoạt động chính. Bạn sẽ nhận được các thông báo cập nhật thời gian thực ngay tại Trang chủ!'
                        : 'Selected "${tour.title}" as your primary itinerary. You will receive real-time updates directly on the Home Screen!',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onBack();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFD4AF7A),
                      ),
                      child: Text(
                        _isVi ? 'Xem ngay' : 'View Now',
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.32),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF7A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFD4AF7A).withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.route_rounded,
                          color: Color(0xFFD4AF7A),
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tour.title,
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4AF7A).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(0xFFD4AF7A).withOpacity(0.28),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _visibilityIcon(tour.visibility),
                                    color: const Color(0xFFD4AF7A),
                                    size: 13,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _visibilityLabel(tour.visibility),
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFD4AF7A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isVi 
                                  ? 'Thời gian: ${tour.totalDays} ngày ${tour.totalNights} đêm'
                                  : 'Duration: ${tour.totalDays} days ${tour.totalNights} nights',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            if (tour.destinations.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                (_isVi ? 'Điểm đến: ' : 'Destinations: ') + tour.destinations.map((d) => _translateProvince(d)).join(", "),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                            ],
                            if (tour.estimatedCost != null && tour.estimatedCost! > 0) ...[
                              const SizedBox(height: 8),
                              Text(
                                (_isVi ? 'Chi phí dự tính: ' : 'Estimated Cost: ') + '${tour.estimatedCost!.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} ' + (_isVi ? 'đ' : 'VND'),
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFD4AF7A),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _deleteSavedTour(tour.id),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.12),
                            ),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: Color(0xFFE74C3C),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyStateView({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 72,
              color: Colors.white.withOpacity(0.75),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                color: Colors.white.withOpacity(0.75),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
