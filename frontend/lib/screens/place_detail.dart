import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../api/api.dart';
import '../models/destination.dart';
import 'create_review_screen.dart';
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

  String _translateTag(String tag) {
    if (_isVi) return tag;
    final maps = {
      'Điểm du lịch': 'Tourist Attraction',
      'Danh lam & Thắng cảnh': 'Sights & Landmarks',
      'Thiên nhiên & Công viên': 'Nature & Parks',
      'Nơi mua sắm': 'Shopping',
      'Hoạt động ngoài trời': 'Outdoor Activities',
      'Bảo tàng': 'Museums',
      'Thông tin cho khách du lịch': 'Traveler Resources',
      'Vui chơi & Giải trí': 'Fun & Games',
      'Chuyến tham quan': 'Tours',
      'Phương tiện giao thông': 'Transportation',
      'Công viên nước & giải trí': 'Water & Amusement Parks',
      'Sự kiện': 'Events',
      'Đồ ăn & Đồ uống': 'Food & Drink',
      'Lớp học & hội thảo': 'Classes & Workshops',
      'Hòa nhạc & chương trình biểu diễn': 'Concerts & Shows',
      'Sòng bạc & Đánh bạc': 'Casinos & Gambling',
      'Sở thú & Thủy cung': 'Zoos & Aquariums',
      'Chuyến tham quan bằng thuyền & thể thao dưới nước': 'Boat Tours & Water Sports',
      'Spa & Sức khỏe': 'Spas & Wellness',
      'Giải trí về đêm': 'Nightlife',
      'Khác': 'Other',
      'Khách sạn': 'Hotels',
      'Khách sạn / Nhà nghỉ': 'Hotel / Motel',
      'Khu nghỉ dưỡng': 'Resorts',
      'Khách sạn nhỏ': 'Small Hotels',
      'Nhà nghỉ': 'Motels',
      'Nhà trọ': 'Inns',
      'Cơ sở lưu trú đặc biệt': 'Specialty Lodging',
      'Khách sạn đặc biệt': 'Specialty Hotels',
      'Nhà khách': 'Guesthouses',
      'B&B': 'B&Bs',
      'Cơ sở kinh doanh có dịch vụ giới hạn': 'Limited Service Properties',
      'Nhà trọ đặc biệt': 'Specialty Inns',
      'Nhà ngoại ô': 'Suburban Lodging',
      'Biệt thự': 'Villas',
      'Khách sạn nhỏ sang trọng': 'Luxury Small Hotels',
      'B&B đặc biệt': 'Specialty B&Bs',
      'Nhà gỗ nhỏ/Khu cắm trại': 'Cabins / Campsites',
      'Khách sạn có căn hộ': 'Apartment Hotels',
      'Khu nghỉ dưỡng (Trọn gói)': 'All-Inclusive Resorts',
      'Nhà trại': 'Farm Lodging',
      'Nhà hàng': 'Restaurants',
      'Ngồi xuống': 'Table Service',
      'Quán cafe': 'Cafes',
      'Đồ ăn nhanh': 'Quick Bites',
    };
    return maps[tag] ?? tag;
  }

  bool _isLoadingReviews = false;
  bool _reviewsLoaded = false;
  String? _reviewsError;
  List<Map<String, dynamic>> _reviews = [];

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

  void _selectTab(int index) {
    setState(() => _selectedTab = index);
    if (index == 1) {
      _loadReviews();
    }
  }

  Future<void> _loadReviews() async {
    if (_isLoadingReviews || _reviewsLoaded) return;

    setState(() {
      _isLoadingReviews = true;
      _reviewsError = null;
    });

    final dest = widget.destination;

    try {
      String? locationId = dest.id;
      if (locationId == null || locationId.isEmpty) {
        locationId = await resolveLocationIdByName(
          dest.name,
          dest.type,
          token: widget.authToken,
        );
      }

      if (locationId == null || locationId.isEmpty) {
        throw Exception('Không tìm thấy địa điểm trên hệ thống');
      }

      final type = _reviewEndpointType(dest.type);
      final response = await apiGet(
        '/reviews/$type/${Uri.encodeComponent(locationId)}',
        token: widget.authToken,
      );
      final data = tryDecodeJsonObject(response.body);

      if (response.statusCode != 200 || data?['success'] != true) {
        throw Exception(data?['message'] ?? 'Không tải được nhận xét');
      }

      final reviewList = data?['data'];
      if (!mounted) return;
      setState(() {
        _reviews = reviewList is List
            ? reviewList
                .whereType<Map>()
                .map((review) => Map<String, dynamic>.from(review))
                .toList()
            : [];
        _reviewsLoaded = true;
        _isLoadingReviews = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _reviewsError = error.toString().replaceFirst('Exception: ', '');
        _isLoadingReviews = false;
      });
    }
  }

  Future<void> _openCreateReview() async {
    final token = widget.authToken?.trim();
    if (token == null || token.isEmpty) {
      _showMessage('Bạn cần đăng nhập để viết nhận xét');
      return;
    }

    final dest = widget.destination;

    try {
      String? locationId = dest.id;
      if (locationId == null || locationId.isEmpty) {
        locationId = await resolveLocationIdByName(
          dest.name,
          dest.type,
          token: token,
        );
      }

      if (!mounted) return;
      if (locationId == null || locationId.isEmpty) {
        _showMessage('Không tìm thấy thông tin địa điểm này trên hệ thống');
        return;
      }

      final resolvedLocationId = locationId;
      final created = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => CreateReviewScreen(
            locationId: resolvedLocationId,
            type: _reviewEndpointType(dest.type),
            authToken: token,
            locationName: dest.name,
          ),
        ),
      );

      if (!mounted || created != true) return;
      setState(() {
        _selectedTab = 1;
        _reviewsLoaded = false;
        _reviewsError = null;
      });
      await _loadReviews();
    } catch (_) {
      if (mounted) {
        _showMessage('Không thể mở màn hình viết nhận xét');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _sharePlace() {
    final String domain = kIsWeb ? Uri.base.origin : 'https://tourxport.vercel.app';
    final String targetId = widget.destination.id ?? widget.destination.sourceLocationId ?? '';
    if (targetId.isEmpty) {
      _showMessage(_isVi ? 'Không tìm thấy ID địa điểm để chia sẻ' : 'Location ID not found for sharing');
      return;
    }
    final String sharePath = Uri(
      path: '/location',
      queryParameters: {
        'id': targetId,
        'type': _placeTypeSlug(widget.destination.type),
      },
    ).toString();
    final String shareUrl = '$domain$sharePath';
    final String intro = _isVi
        ? 'Khám phá ${widget.destination.name} trên TourXport:'
        : 'Explore ${widget.destination.name} on TourXport:';
    final String shareText = '$intro\n$shareUrl';
    
    _showShareDialog(context, shareUrl, shareText, _isVi ? 'địa điểm' : 'place');
  }

  String _placeTypeSlug(String type) {
    final normalized = type.trim().toLowerCase();
    if (normalized.contains('restaurant') ||
        normalized.contains('nhà hàng') ||
        normalized.contains('nha hang')) {
      return 'restaurant';
    }
    if (normalized.contains('hotel') ||
        normalized.contains('khách sạn') ||
        normalized.contains('khach san')) {
      return 'hotel';
    }
    return 'place';
  }

  void _showShareDialog(
    BuildContext context,
    String shareUrl,
    String shareText,
    String title,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AlertDialog(
            backgroundColor: const Color(0xFF0F1E1B).withOpacity(0.92),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: Colors.white.withOpacity(0.12), width: 1.2),
            ),
            title: Text(
              _isVi ? 'Chia sẻ $title' : 'Share $title',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isVi
                      ? 'Chia sẻ qua ứng dụng khác hoặc sao chép liên kết bên dưới:'
                      : 'Share through another app or copy the link below:',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.10)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          shareUrl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, color: Color(0xFFD4AF7A), size: 20),
                        tooltip: _isVi ? 'Sao chép' : 'Copy',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: shareUrl));
                          _showMessage(_isVi
                              ? 'Đã sao chép liên kết chia sẻ vào khay nhớ tạm'
                              : 'Copied share link to clipboard');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton.icon(
                onPressed: () async {
                  final box = context.findRenderObject() as RenderBox?;
                  await Share.share(
                    shareText,
                    subject: _isVi ? 'Chia sẻ $title TourXport' : 'Share TourXport $title',
                    sharePositionOrigin:
                        box == null ? null : box.localToGlobal(Offset.zero) & box.size,
                  );
                },
                icon: const Icon(Icons.ios_share_rounded, color: Color(0xFFD4AF7A), size: 18),
                label: Text(
                  _isVi ? 'Chia sẻ' : 'Share',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    color: Color(0xFFD4AF7A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  _isVi ? 'Đóng' : 'Close',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    color: Color(0xFFD4AF7A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
        body: Stack(
          fit: StackFit.expand,
          children: [
            _buildDetailBackground(dest),
            SafeArea(child: _buildDesktopLayout(dest)),
          ],
        ),
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

  Widget _buildDesktopLayout(Destination dest) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1240),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.12,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                _buildHeaderActions(),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                              child: Destination.buildImage(
                                dest.imagePath,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _sectionTitle(_isVi ? 'Bộ sưu tập' : 'Gallery'),
                        const SizedBox(height: 12),
                        _buildGallery(dest),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                  Expanded(
                    flex: 5,
                    child: Card(
                      elevation: 0,
                      color: const Color(0xFF0D1B18).withOpacity(0.68),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                        side: BorderSide(color: Colors.white.withOpacity(0.10)),
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
                                _buildTabHeader(dest),
                                const SizedBox(height: 20),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 300),
                                      child: _selectedTab == 0
                                          ? _buildOverviewTabForDesktop(dest)
                                          : _buildReviewsTab(dest),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 28),
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
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.assistant_direction_rounded, color: Colors.white, size: 24),
                                        const SizedBox(width: 10),
                                        Text(
                                          _isVi ? 'Đường đi' : 'Directions',
                                          style: const TextStyle(
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
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTabForDesktop(Destination dest) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(_isVi ? 'Mô tả' : 'Description'),
        const SizedBox(height: 8),
        _buildAboutSection(dest),
        if (_quickInfoItems(dest).isNotEmpty) ...[
          const SizedBox(height: 24),
          _sectionTitle(_isVi ? 'Thông tin nhanh' : 'Quick info'),
          const SizedBox(height: 12),
          _buildQuickInfoGrid(dest),
        ],
        if (_openingHoursLines(dest).isNotEmpty) ...[
          const SizedBox(height: 24),
          _sectionTitle(_isVi ? 'Giờ mở cửa' : 'Opening hours'),
          const SizedBox(height: 12),
          _buildOpeningHoursSection(dest),
        ],
        const SizedBox(height: 24),
        _sectionTitle(_isVi ? 'Điểm nổi bật' : 'Highlights'),
        const SizedBox(height: 12),
        _buildHighlightChips(dest),
      ],
    );
  }

  Widget _buildDetailBackground(Destination dest) {
    final backgroundPath = dest.hasImage == true
        ? (dest.bgBlurPath.isNotEmpty ? dest.bgBlurPath : dest.imagePath)
        : 'assets/images/login_bg.jpg';
    return Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Transform.scale(
            scale: 1.04,
            child: Destination.buildImage(backgroundPath, fit: BoxFit.cover),
          ),
        ),
        Container(
          color: Colors.black.withOpacity(0.28),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0A1714).withOpacity(0.50),
                const Color(0xFF10241E).withOpacity(0.30),
                Colors.black.withOpacity(0.52),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickInfoGrid(Destination dest) {
    final items = _quickInfoItems(dest);
    if (items.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520 ? 2 : 1;
        final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items
              .map((item) => SizedBox(
                    width: width,
                    child: _quickInfoTile(
                      icon: item.$1,
                      label: item.$2,
                      value: item.$3,
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  List<(IconData, String, String)> _quickInfoItems(Destination dest) {
    final items = <(IconData, String, String)>[];
    if (dest.type.trim().isNotEmpty) {
      items.add((Icons.place_rounded, _isVi ? 'Loại hình' : 'Type', _translatePlaceType(dest.type)));
    }
    if (dest.category?.trim().isNotEmpty == true) {
      items.add((Icons.category_rounded, _isVi ? 'Danh mục' : 'Category', _translateCategory(dest.category!)));
    }
    if (dest.province.trim().isNotEmpty) {
      items.add((Icons.location_city_rounded, _isVi ? 'Khu vực' : 'Area', _translateProvince(dest.province)));
    }
    if (dest.ranking?.trim().isNotEmpty == true) {
      items.add((Icons.leaderboard_rounded, _isVi ? 'Xếp hạng' : 'Ranking', dest.ranking!.trim()));
    }
    if (dest.priceRange?.trim().isNotEmpty == true) {
      items.add((Icons.payments_rounded, _isVi ? 'Chi phí' : 'Price', dest.priceRange!.trim()));
    }
    return items;
  }

  Widget _buildOpeningHoursSection(Destination dest) {
    final dayEntries = _openingHourDayEntries(dest);
    final displayLines = dayEntries.isEmpty ? _openingHoursDisplayLines(dest) : const <String>[];

    if (dayEntries.isNotEmpty) {
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: dayEntries
            .map((entry) => _openingHourTile(day: entry.$1, hours: entry.$2))
            .toList(),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.09)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: displayLines
            .map((line) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.schedule_rounded, color: Color(0xFFD4AF7A), size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          line,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 13,
                            height: 1.45,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.82),
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _openingHourTile({
    required String day,
    required String hours,
  }) {
    return Container(
      width: 170,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.09)),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, color: Color(0xFFD4AF7A), size: 16),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.58),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hours,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.09)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFD4AF7A), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.56),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
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
        child: Align(
          alignment: Alignment.centerLeft,
          child: _glassCircle(Icons.arrow_back_ios_new, () => Navigator.pop(context, {
            'isSaved': _isSaved,
            'isLiked': _isLiked,
          })),
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
                      const Color(0xFF0D1B18).withOpacity(0.84),
                      const Color(0xFF08110F).withOpacity(0.92),
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              dest.name,
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildHeaderActions(spacing: 8),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Color(0xFFD4AF7A), size: 16),
                          const SizedBox(width: 4),
                           Text(_translateProvince(dest.province), style: const TextStyle(
                            fontFamily: 'Montserrat', fontSize: 14,
                            color: Colors.white70,
                          )),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildTabHeader(dest),
                      const SizedBox(height: 20),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _selectedTab == 0
                            ? _buildOverviewTab(dest)
                            : _buildReviewsTab(dest),
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

  Widget _buildTabHeader(Destination dest) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildTabBar()),
        const SizedBox(width: 12),
        _buildRatingInline(dest),
      ],
    );
  }

  Widget _buildTabBar() {
    return Row(
      children: [
        _tabItem(_isVi ? 'Tổng quan' : 'Overview', 0),
        const SizedBox(width: 24),
        _tabItem(_isVi ? 'Nhận xét' : 'Reviews', 1),
      ],
    );
  }

  Widget _buildRatingInline(Destination dest) {
    if (MediaQuery.of(context).size.width < 600) {
      return const SizedBox.shrink();
    }
    if (dest.totalScore == null && dest.reviewsCount == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFFFB74D), size: 19),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 190),
            child: Text(
              _ratingSummary(dest),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.82),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabItem(String label, int index) {
    final isActive = _selectedTab == index;
    return GestureDetector(
      onTap: () => _selectTab(index),
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
        _sectionTitle(_isVi ? 'Mô tả' : 'Description'),
        const SizedBox(height: 8),
        _buildAboutSection(dest),
        if (_quickInfoItems(dest).isNotEmpty) ...[
          const SizedBox(height: 24),
          _sectionTitle(_isVi ? 'Thông tin nhanh' : 'Quick info'),
          const SizedBox(height: 12),
          _buildQuickInfoGrid(dest),
        ],
        if (_openingHoursLines(dest).isNotEmpty) ...[
          const SizedBox(height: 24),
          _sectionTitle(_isVi ? 'Giờ mở cửa' : 'Opening hours'),
          const SizedBox(height: 12),
          _buildOpeningHoursSection(dest),
        ],
        const SizedBox(height: 24),
        _sectionTitle(_isVi ? 'Điểm nổi bật' : 'Highlights'),
        const SizedBox(height: 12),
        _buildHighlightChips(dest),
        const SizedBox(height: 24),
        _sectionTitle(_isVi ? 'Bộ sưu tập' : 'Gallery'),
        const SizedBox(height: 12),
        _buildGallery(dest),
      ],
    );
  }

  Widget _buildAboutSection(Destination dest) {
    final fullText = _getDescription(dest);
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
            _showFullDesc ? (_isVi ? 'Thu gọn' : 'Show less') : (_isVi ? 'Xem thêm' : 'Read more'),
            style: const TextStyle(
              fontFamily: 'Montserrat', fontSize: 13,
              fontWeight: FontWeight.w600, color: Color(0xFFD4AF7A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsTab(Destination dest) {
    Widget content;

    if (_isLoadingReviews) {
      content = const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF7A)),
          ),
        ),
      );
    } else if (_reviewsError != null) {
      content = Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          _reviewsError!,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 13,
            color: Colors.white.withOpacity(0.75),
            height: 1.5,
          ),
        ),
      );
    } else if (_reviews.isEmpty) {
      content = Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          _reviewsLoaded
              ? (_isVi ? 'Chưa có nhận xét cho địa điểm này.' : 'No reviews for this location yet.')
              : (_isVi ? 'Bấm vào thẻ Nhận xét để tải đánh giá.' : 'Tap on Reviews tab to load ratings.'),
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 13,
            color: Colors.white.withOpacity(0.75),
            height: 1.5,
          ),
        ),
      );
    } else {
      content = Column(
        children: _reviews
            .map((review) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildReviewCardFromData(review),
                ))
            .toList(),
      );
    }

    return Column(
      key: const ValueKey('reviews_tab'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWriteReviewButton(),
        const SizedBox(height: 16),
        content,
      ],
    );
  }

  Widget _buildWriteReviewButton() {
    return GestureDetector(
      onTap: _openCreateReview,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFB5956A), Color(0xFFD4AF7A)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4AF7A).withOpacity(0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              _isVi ? 'Viết nhận xét' : 'Write a review',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDescription(Destination dest) {
    final backendDescription = dest.description?.trim();
    if (backendDescription != null && backendDescription.isNotEmpty) {
      return backendDescription;
    }

    if (_isVi) {
      final descriptions = {
        'Hạ Long Bay': 'Hạ Long Bay là kỳ quan thiên nhiên thế giới với hơn 1.600 hòn đảo đá vôi nhô lên từ mặt biển xanh ngọc bích. Nơi đây mang vẻ đẹp huyền bí, lung linh qua từng buổi sớm mai và hoàng hôn.',
        'Hội An': 'Hội An là phố cổ mang đậm dấu ấn lịch sử và văn hóa, nổi tiếng với những ngôi nhà cổ, đèn lồng rực rỡ và ẩm thực đường phố phong phú.',
        'Đà Nẵng': 'Đà Nẵng là thành phố biển năng động với bãi biển Mỹ Khê tuyệt đẹp, cầu Rồng ấn tượng và Bà Nà Hills lãng mạn.',
        'Phong Nha': 'Phong Nha-Kẻ Bàng là vườn quốc gia sở hữu hệ thống hang động kỳ vĩ nhất thế giới, bao gồm Sơn Đoòng — hang động lớn nhất hành tinh.',
      };
      return descriptions[dest.name] ?? 'Một điểm đến tuyệt vời tại Việt Nam với cảnh quan thiên nhiên hùng vĩ và văn hóa đặc sắc.';
    } else {
      final descriptions = {
        'Hạ Long Bay': 'Ha Long Bay is a natural wonder of the world with over 1,600 limestone islands rising from the emerald green waters. It carries a mystical, sparkling beauty through every early morning and sunset.',
        'Hội An': 'Hoi An is an ancient town deeply marked by history and culture, famous for its old houses, brilliant lanterns and rich street food.',
        'Đà Nẵng': 'Da Nang is a dynamic coastal city with beautiful My Khe beach, impressive Dragon Bridge and romantic Ba Na Hills.',
        'Phong Nha': 'Phong Nha-Ke Bang is a national park possessing the most majestic cave systems in the world, including Son Doong — the largest cave on the planet.',
      };
      return descriptions[dest.name] ?? 'A wonderful destination in Vietnam with majestic natural landscapes and unique culture.';
    }
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
        itemBuilder: (context, i) => Container(
          width: 130,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: i == 0
                  ? const Color(0xFFD4AF7A).withOpacity(0.65)
                  : Colors.white.withOpacity(0.10),
              width: i == 0 ? 1.3 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Destination.buildImage(
                  images[i],
                  fit: BoxFit.cover,
                ),
                if (i != 0)
                  Container(color: const Color(0xFF0D1B18).withOpacity(0.16)),
              ],
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
              color: const Color(0xFF08110F).withOpacity(0.84),
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
                        color: const Color(0xFFD4AF7A),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFB5956A).withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.assistant_direction_rounded, color: Colors.white, size: 24),
                          const SizedBox(width: 10),
                          Text(
                            _isVi ? 'Đường đi' : 'Directions',
                            style: const TextStyle(
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

  Widget _buildHeaderActions({double spacing = 12}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _glassCircle(Icons.share_outlined, _sharePlace),
        SizedBox(width: spacing),
        _glassCircleAnimatedIcon(
          isActive: _isSaved,
          activeIcon: Icons.bookmark,
          inactiveIcon: Icons.bookmark_border,
          onTap: _toggleSaved,
          activeColor: const Color(0xFFD4AF7A),
        ),
      ],
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
              color: Colors.white.withOpacity(0.10),
              border: Border.all(color: Colors.white.withOpacity(0.16)),
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
              color: Colors.white.withOpacity(0.10),
              border: Border.all(color: Colors.white.withOpacity(0.16)),
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

  Widget _buildHighlightChips(Destination dest) {
    final backendTags = dest.tags.where((tag) => tag.trim().isNotEmpty).toList();
    final highlights = backendTags.isNotEmpty
        ? backendTags.map((tag) => (_iconForTag(tag), _translateTag(tag))).toList()
        : [
            (Icons.landscape_rounded, _isVi ? 'Thiên nhiên' : 'Nature'),
            (Icons.camera_alt_rounded, _isVi ? 'Chụp ảnh' : 'Photography'),
            (Icons.restaurant_rounded, _isVi ? 'Ẩm thực' : 'Cuisine'),
            (Icons.kayaking_rounded, _isVi ? 'Phiêu lưu' : 'Adventure'),
          ];
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: highlights.map((h) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.075),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(h.$1, size: 16, color: const Color(0xFFD4AF7A)),
            const SizedBox(width: 6),
            Text(h.$2, style: const TextStyle(
              fontFamily: 'Montserrat', fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            )),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildReviewCardFromData(Map<String, dynamic> review) {
    final user = review['user'];
    final avatar = user is Map ? user['avatar'] : null;
    final avatarUrl = avatar is Map ? (avatar['url'] ?? '').toString() : '';
    final name = user is Map
        ? (user['username'] ?? 'Người dùng').toString()
        : 'Người dùng';
    final ratingValue = review['rating'];
    final rating = ratingValue is num ? ratingValue.round().clamp(0, 5).toInt() : 0;
    final title = (review['title'] ?? '').toString().trim();
    final body = (review['text'] ?? '').toString().trim();
    final text = [
      if (title.isNotEmpty) title,
      if (body.isNotEmpty) body,
    ].join('\n\n');

    final images = review['images'];
    final imageList = <String>[];
    if (images is List) {
      for (final img in images) {
        if (img is Map) {
          final url = (img['url'] ?? '').toString();
          if (url.isNotEmpty) {
            imageList.add(url);
          }
        }
      }
    }

    return _buildReviewCard(
      name: name.isNotEmpty ? name : 'Người dùng',
      rating: rating,
      text: text.isNotEmpty ? text : 'Người dùng chưa để lại nội dung.',
      avatarUrl: avatarUrl,
      images: imageList,
    );
  }

  Widget _buildReviewCard({
    required String name,
    required int rating,
    required String text,
    String avatarUrl = '',
    List<String> images = const [],
  }) {
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
              backgroundImage: avatarUrl.startsWith('http') ? NetworkImage(avatarUrl) : null,
              child: avatarUrl.startsWith('http')
                  ? null
                  : Text(name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?', style: const TextStyle(
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
          if (images.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final imgUrl = images[index];
                  return GestureDetector(
                    onTap: () => _showFullScreenImage(context, imgUrl),
                    child: Container(
                      width: 70,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(imgUrl, fit: BoxFit.cover),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  imageUrl,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB5956A)),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _ratingSummary(Destination dest) {
    final score = dest.totalScore;
    final scoreText = score == null ? '--' : score.toStringAsFixed(1);
    return '$scoreText (${_compactReviewCount(dest.reviewsCount)} ${_isVi ? "nhận xét" : "reviews"})';
  }

  String _compactReviewCount(int? count) {
    final value = count ?? 0;
    if (value >= 1000000) {
      final millions = value / 1000000;
      return '${millions.toStringAsFixed(millions >= 10 ? 0 : 1)}m';
    }
    if (value >= 1000) {
      final thousands = value / 1000;
      return '${thousands.toStringAsFixed(thousands >= 10 ? 0 : 1)}k';
    }
    return value.toString();
  }

  String _reviewEndpointType(String type) {
    final normalized = type.trim().toLowerCase();
    if (normalized.contains('restaurant') ||
        normalized.contains('nhà hàng') ||
        normalized.contains('nha hang')) {
      return 'restaurants';
    }
    if (normalized.contains('hotel') ||
        normalized.contains('khách sạn') ||
        normalized.contains('khach san')) {
      return 'hotels';
    }
    return 'places';
  }

  String _translateCategory(String category) {
    final trimmed = category.trim();
    if (_isVi) return trimmed;
    final normalized = trimmed.toLowerCase();
    if (normalized.contains('điểm du lịch') || normalized.contains('diem du lich')) {
      return 'Tourist attraction';
    }
    if (normalized.contains('nhà hàng') || normalized.contains('nha hang')) {
      return 'Restaurant';
    }
    if (normalized.contains('khách sạn') || normalized.contains('khach san')) {
      return 'Hotel';
    }
    return trimmed;
  }

  String _translatePlaceType(String type) {
    final normalized = type.trim().toLowerCase();
    if (normalized.contains('restaurant') ||
        normalized.contains('nhà hàng') ||
        normalized.contains('nha hang')) {
      return _isVi ? 'Nhà hàng' : 'Restaurant';
    }
    if (normalized.contains('hotel') ||
        normalized.contains('khách sạn') ||
        normalized.contains('khach san')) {
      return _isVi ? 'Khách sạn' : 'Hotel';
    }
    return _isVi ? 'Địa điểm' : 'Place';
  }

  List<String> _openingHoursLines(Destination dest) {
    final dayEntries = _openingHourDayEntries(dest);
    if (dayEntries.isNotEmpty) {
      return dayEntries.map((entry) => '${entry.$1}: ${entry.$2}').toList();
    }
    return _openingHoursDisplayLines(dest);
  }

  List<String> _openingHoursDisplayLines(Destination dest) {
    final hours = dest.openingHours;
    if (hours == null || hours.isEmpty) return const [];

    final simple = hours['display'] ?? hours['text'] ?? hours['summary'];
    if (simple is String && simple.trim().isNotEmpty) {
      return [simple.trim()];
    }
    if (simple is List) {
      return simple
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return hours.entries
        .where((entry) =>
            entry.key != 'weekRanges' &&
            entry.value != null &&
            entry.value is! Map &&
            entry.value is! List &&
            entry.value.toString().trim().isNotEmpty)
        .map((entry) => '${entry.key}: ${entry.value}')
        .toList();
  }

  List<(String, String)> _openingHourDayEntries(Destination dest) {
    final hours = dest.openingHours;
    if (hours == null || hours.isEmpty) return const [];

    final weekRanges = hours['weekRanges'];
    if ((weekRanges is Map && weekRanges.isNotEmpty) ||
        (weekRanges is List && weekRanges.isNotEmpty)) {
      final labelsVi = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật'];
      final labelsEn = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final labels = _isVi ? labelsVi : labelsEn;
      final entries = <(String, String)>[];
      final rangeGroups = weekRanges is List
          ? weekRanges.whereType<List>().where((ranges) => ranges.isNotEmpty).toList()
          : List.generate(7, (index) => (weekRanges as Map)['$index'] ?? weekRanges[index])
              .whereType<List>()
              .where((ranges) => ranges.isNotEmpty)
              .toList();

      for (var dayIndex = 0; dayIndex < rangeGroups.length && dayIndex < labels.length; dayIndex++) {
        final formattedRanges = rangeGroups[dayIndex].map((range) {
          if (range is! Map) return '';
          final open = _formatOpeningMinute(range['open_time'] ?? range['openTime']);
          final close = _formatOpeningMinute(range['close_time'] ?? range['closeTime']);
          if (open == null || close == null) return '';
          return '$open - $close';
        }).where((range) => range.isNotEmpty).join(', ');

        if (formattedRanges.isNotEmpty) {
          entries.add((labels[dayIndex], formattedRanges));
        }
      }
      return entries;
    }

    return const [];
  }

  String? _formatOpeningMinute(dynamic value) {
    final minutes = value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');
    if (minutes == null || minutes < 0) return null;
    final hour = (minutes ~/ 60).clamp(0, 23);
    final minute = minutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  IconData _iconForTag(String tag) {
    final normalized = tag.toLowerCase();
    if (normalized.contains('ẩm thực') ||
        normalized.contains('am thuc') ||
        normalized.contains('đồ ăn') ||
        normalized.contains('do an') ||
        normalized.contains('restaurant')) {
      return Icons.restaurant_rounded;
    }
    if (normalized.contains('khách sạn') ||
        normalized.contains('khach san') ||
        normalized.contains('hotel')) {
      return Icons.hotel_rounded;
    }
    if (normalized.contains('biển') ||
        normalized.contains('bien') ||
        normalized.contains('beach')) {
      return Icons.beach_access_rounded;
    }
    if (normalized.contains('mua sắm') ||
        normalized.contains('mua sam') ||
        normalized.contains('shopping')) {
      return Icons.shopping_bag_rounded;
    }
    if (normalized.contains('bảo tàng') ||
        normalized.contains('bao tang') ||
        normalized.contains('museum')) {
      return Icons.museum_rounded;
    }
    if (normalized.contains('thiên nhiên') ||
        normalized.contains('thien nhien') ||
        normalized.contains('công viên') ||
        normalized.contains('cong vien')) {
      return Icons.landscape_rounded;
    }
    if (normalized.contains('giải trí') ||
        normalized.contains('giai tri')) {
      return Icons.attractions_rounded;
    }
    return Icons.place_rounded;
  }
}
