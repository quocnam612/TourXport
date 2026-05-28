import 'dart:ui';
import 'package:flutter/material.dart';

import '../models/destination.dart';
import '../models/saved_tour.dart';
import '../api/api.dart';

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
    this.initialTabIndex = 0,
    this.onSelectTour,
  });

  final Function(SavedTour tour)? onSelectTour;

  @override
  State<SavedPlacesSection> createState() => _SavedPlacesSectionState();
}

class _SavedPlacesSectionState extends State<SavedPlacesSection> {
  int _activeTab = 0; // 0: Places (Địa điểm), 1: Itineraries (Lịch trình)
  List<SavedTour> _savedTours = [];
  bool _isLoadingTours = false;
  String? _toursError;

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
        _toursError = 'Không thể tải lịch trình du lịch';
        _isLoadingTours = false;
      });
    } catch (e) {
      setState(() {
        _toursError = 'Lỗi kết nối đến máy chủ';
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
        title: const Text('Xóa lịch trình', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc chắn muốn xóa lịch trình này khỏi danh sách đã lưu?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Color(0xFFE74C3C), fontWeight: FontWeight.bold)),
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
            const SnackBar(content: Text('Đã xóa lịch trình thành công')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Xóa lịch trình thất bại')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi kết nối máy chủ')),
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
                      'Địa điểm',
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
                      'Lịch trình',
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
                  const Text(
                    'Danh sách đã lưu',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _activeTab == 0
                        ? '${widget.savedDestinations.length} địa điểm'
                        : '${_savedTours.length} lịch trình',
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
              _activeTab == 0 ? 'Những nơi bạn muốn đến' : 'Hành trình của riêng bạn',
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
        title: widget.isGuest ? 'Đăng nhập để sử dụng tính năng này' : 'Chưa có địa điểm nào được lưu',
        subtitle: 'Hãy thêm địa điểm bạn muốn đến vào lần tới',
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
                              dest.province,
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
        title: 'Đăng nhập để xem lịch trình',
        subtitle: 'Hãy đăng nhập tài khoản của bạn để lưu và quản lý các lịch trình du lịch cá nhân hóa.',
      );
    }

    if (_toursError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _toursError!,
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
              child: const Text('Thử lại', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    if (_savedTours.isEmpty) {
      return _buildEmptyStateView(
        icon: Icons.explore_outlined,
        title: 'Chưa có lịch trình nào',
        subtitle: 'Hãy thực hiện khảo sát thông minh để AI tạo riêng cho bạn một lịch trình du lịch tuyệt vời.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 110),
      itemCount: _savedTours.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final tour = _savedTours[index];

        return GestureDetector(
          onTap: () {
            if (widget.onSelectTour != null) {
              widget.onSelectTour!(tour);
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF12201C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  title: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Color(0xFFD4AF7A), size: 28),
                      SizedBox(width: 12),
                      Text(
                        'Kích hoạt lịch trình',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  content: Text(
                    'Đã chọn "${tour.title}" làm lịch trình hoạt động chính. Bạn sẽ nhận được các thông báo cập nhật thời gian thực ngay tại Trang chủ!',
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
                      child: const Text(
                        'Xem ngay',
                        style: TextStyle(
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
                            const SizedBox(height: 6),
                            Text(
                              'Thời gian: ${tour.totalDays} ngày ${tour.totalNights} đêm',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            if (tour.destinations.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Điểm đến: ${tour.destinations.join(", ")}',
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
                                'Chi phí dự tính: ${tour.estimatedCost!.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ',
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
