import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';

import '../api/api.dart';
import '../utils/auth_storage.dart';
import '../widgets/weather_widget.dart';
import '../widgets/responsive_builder.dart';
import '../models/destination.dart';
import '../widgets/anim_builder.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'help_support_screen.dart';
import 'language_settings_screen.dart';
import 'notification_settings_screen.dart';
import 'phone_settings_screen.dart';
import 'security_settings_screen.dart';
import 'place_detail.dart';
import 'profile_section.dart';
import 'saved_place.dart';
import 'survey_screen.dart';
import 'sign_in.dart';
import 'app_reviews_screen.dart';
import '../models/travel_notification.dart';

class _DestinationPageResult {
  final List<Destination> items;
  final int total;
  final int page;
  final int totalPages;

  const _DestinationPageResult({
    required this.items,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  static const empty = _DestinationPageResult(
    items: [],
    total: 0,
    page: 1,
    totalPages: 1,
  );
}

class HomeScreen extends StatefulWidget {
  final String userName;
  final String? authToken;
  final int initialTabIndex;

  const HomeScreen({
    super.key,
    this.userName = 'Username',
    this.authToken,
    this.initialTabIndex = 0,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  static const int _tabExplore = 0;
  static const int _tabSearch = 1;
  static const int _tabSaved = 2;
  static const int _tabSurvey = 3;
  static const int _tabProfile = 4;
  static const Map<int, String> _tabRoutes = {
    _tabExplore: '/home',
    _tabSearch: '/search',
    _tabSaved: '/saved',
    _tabSurvey: '/generate',
    _tabProfile: '/account',
  };
  static const List<Shadow> _heroTextShadows = [
    Shadow(
      color: Color(0x99000000),
      offset: Offset(0, 1.5),
      blurRadius: 4,
    ),
    Shadow(
      color: Color(0x66000000),
      offset: Offset(0, 0),
      blurRadius: 10,
    ),
  ];
  static const List<Shadow> _heroTitleShadows = [
    Shadow(
      color: Color(0xB0000000),
      offset: Offset(0, 3),
      blurRadius: 8,
    ),
    Shadow(
      color: Color(0x80000000),
      offset: Offset(0, 0),
      blurRadius: 18,
    ),
  ];

  bool get _isVi => Localizations.localeOf(context).languageCode == 'vi';

  int _normalizedTabIndex(int index) =>
      index >= _tabExplore && index <= _tabProfile ? index : _tabExplore;

  void _updateTabRoute(int tabIndex) {
    if (!kIsWeb) return;
    final route = _tabRoutes[_normalizedTabIndex(tabIndex)];
    if (route == null) return;
    SystemNavigator.routeInformationUpdated(
      location: route,
      replace: true,
    );
  }

  void _showMainTab(int tabIndex) {
    final normalizedIndex = _normalizedTabIndex(tabIndex);
    setState(() {
      _navIndex = normalizedIndex;
      _savedPlacesInitialTab = 0;
    });
    _updateTabRoute(normalizedIndex);
    if (normalizedIndex == _tabExplore) {
      _startAutoPlay();
    } else {
      _stopAutoPlay();
    }
  }

  String? _placeDetailRoute(Destination dest) {
    final targetId = dest.id ?? dest.sourceLocationId ?? '';
    if (targetId.isEmpty) return null;

    return Uri(
      path: '/location',
      queryParameters: {
        'id': targetId,
        'type': _placeTypeSlug(dest.type),
      },
    ).toString();
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

  void _updatePlaceDetailRoute(Destination dest) {
    if (!kIsWeb) return;
    final route = _placeDetailRoute(dest);
    if (route == null) return;

    SystemNavigator.routeInformationUpdated(
      location: route,
      replace: false,
    );
  }

  String _translateProvince(String prov) {
    if (_isVi) return prov;
    final maps = {
      'Toàn quốc': 'All',
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

  String _translateType(String type) {
    if (_isVi) return type;
    final maps = {
      'Địa điểm': 'Places',
      'Khách sạn': 'Hotels',
      'Nhà hàng': 'Restaurants',
      'Tất cả': 'All',
      'Du lịch': 'Explore',
      'Chỗ ở': 'Stay',
      'Ăn uống': 'Dining',
    };
    return maps[type] ?? type;
  }

  String _translateTypeLabel(String value) {
    switch (value) {
      case 'all':
        return 'All';
      case 'hotels':
        return 'Stay';
      case 'restaurants':
        return 'Dining';
      case 'places':
      default:
        return 'Explore';
    }
  }

  String _translateTag(String tag) {
    if (_isVi) return tag;
    final maps = {
      // Place Tags
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
      'Chuyến tham quan bằng thuyền & thể thao dưới nước':
          'Boat Tours & Water Sports',
      'Spa & Sức khỏe': 'Spas & Wellness',
      'Giải trí về đêm': 'Nightlife',
      'Khác': 'Other',
      // Hotel Tags
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
      // Restaurant Tags
      'Nhà hàng': 'Restaurants',
      'Ngồi xuống': 'Table Service',
      'Quán cafe': 'Cafes',
      'Đồ ăn nhanh': 'Quick Bites',
    };
    return maps[tag] ?? tag;
  }

  String _getLocalizedDisplay(String val) {
    if (_isVi) return val;
    final prov = _translateProvince(val);
    if (prov != val) return prov;
    final type = _translateType(val);
    if (type != val) return type;
    final tag = _translateTag(val);
    if (tag != val) return tag;
    return val;
  }

  String _translateCategoryHeader(String cat) {
    if (_isVi) return cat.toLowerCase();
    final maps = {
      'VỊNH BIỂN': 'bays & beaches',
      'NÚI RỪNG': 'mountains & forests',
      'DI SẢN': 'heritage sites',
      'ĐÔ THỊ': 'urban centers',
    };
    return maps[cat] ?? cat.toLowerCase();
  }

  int _currentIndex = 0;
  int _previousIndex = 0;
  int _searchCurrentIndex = 0;
  int _navIndex = _tabExplore;
  int _savedPlacesInitialTab = 0;
  int _surveyAiWarmupToken = 0;
  bool _isSurveyAiReady = false;
  bool _showLikedOnly = false;
  String _searchQuery = '';
  String? _selectedCity;
  String _sortBy = 'reviewsCount';
  String _sortOrder = 'desc';
  String _selectedLocationKind = 'places';
  String? _selectedCategory;
  final Set<String> _selectedTags = {};
  RangeValues _scoreRange = const RangeValues(0, 5);
  String? _filterTime;
  String? _filterDate;
  int _filterLimit = 10;
  bool _nearbyEnabled = false;
  double _radius = 5000.0;
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  String _currentBgPath = 'assets/images/halong.jpg';
  String _previousBgPath = 'assets/images/halong.jpg';

  final Set<String> _savedNames = {};
  final Set<String> _likedNames = {};
  final Set<String> _updatingSavedNames = {};
  List<Destination> _savedDestinations = const [];
  bool _isLoadingSavedPlaces = false;

  List<Destination> _realDestinations = [];
  List<Destination> _allDatabaseDestinations = [];
  bool _isLoadingDestinations = false;

  Map<String, dynamic>? _userData;
  bool _isLoadingProfile = false;
  String _currentUserName = '';
  final ImagePicker _picker = ImagePicker();

  // Notification center state
  List<TravelNotification> _notifications = [];
  int _selectedNotificationTab = 0; // 0: Cá nhân, 1: Xu hướng Hot
  String _selectedTrendFilter = 'day'; // 'day', 'week', 'month'

  late final AnimationController _bgFadeController;
  late final Animation<double> _bgFade;
  late final AnimationController _entranceController;
  late final Animation<double> _cardEntrance;
  late final Animation<Offset> _searchBarSlide;
  late final PageController _pageController;
  late final PageController _searchPageController;
  Timer? _autoPlayTimer;
  Timer? _searchDebounceTimer;
  List<Destination> _searchResults = [];
  List<Destination> _searchSuggestions = [];

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechEnabled = false;

  int _exploreBackendPage = 1;
  int _exploreTotalItems = 0;
  int _exploreTotalPages = 1;
  int _searchBackendPage = 1;
  int _searchTotalItems = 0;
  int _searchTotalPages = 1;
  bool _isChangingCarouselPage = false;
  final Map<String, _DestinationPageResult> _cityCache = {};
  double _gpsLat = 21.0285; // Fallback to Hanoi
  double _gpsLon = 105.8542;
  bool _hasGps = false;

  Future<void> _initGps() async {
    try {
      final permission = await Permission.locationWhenInUse.status;
      if (permission == PermissionStatus.granted) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 3),
        );
        if (!mounted) return;
        setState(() {
          _gpsLat = position.latitude;
          _gpsLon = position.longitude;
          _hasGps = true;
        });
      }
      // Không tự động request quyền lúc khởi động nữa
    } catch (_) {}
  }

  Future<void> _initSpeech() async {
    try {
      _speechEnabled = await _speech.initialize(
        onError: (val) => debugPrint('Speech onError: $val'),
        onStatus: (val) => debugPrint('Speech onStatus: $val'),
      );
    } catch (e) {
      _speechEnabled = false;
      debugPrint('Speech initialization failed: $e');
    }
  }

  void _showVoiceSearchDialog() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      _showMessage(_isVi
          ? 'Ứng dụng chưa được cấp quyền truy cập microphone'
          : 'Microphone permission not granted');
      return;
    }

    if (!_speechEnabled) {
      await _initSpeech();
    }

    if (!_speechEnabled) {
      _showMessage(_isVi
          ? 'Nhận diện giọng nói không hỗ trợ trên thiết bị này'
          : 'Speech recognition is not supported on this device');
      return;
    }

    String words = '';
    bool listening = true;

    if (!mounted) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'VoiceSearch',
      barrierColor: Colors.black.withOpacity(0.75),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (listening && !_speech.isListening) {
              _speech.listen(
                onResult: (val) {
                  setDialogState(() {
                    words = val.recognizedWords;
                    if (val.finalResult) {
                      listening = false;
                      Future.delayed(const Duration(milliseconds: 800), () {
                        if (mounted) {
                          setState(() {
                            _searchController.text = words;
                            _onSearchChanged(words);
                          });
                        }
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      });
                    }
                  });
                },
                localeId: _isVi ? 'vi_VN' : 'en_US',
              );
            }

            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Scaffold(
                backgroundColor: Colors.transparent,
                body: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: const Color(0xFF162521).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF7A).withOpacity(0.1),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isVi ? 'Tìm kiếm bằng giọng nói' : 'Voice Search',
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 32),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 1.0, end: listening ? 1.15 : 1.0),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeInOut,
                          onEnd: () {
                            if (listening) {
                              setDialogState(() {});
                            }
                          },
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: listening
                                      ? const Color(0xFFD4AF7A).withOpacity(0.2)
                                      : Colors.white.withOpacity(0.06),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: listening
                                        ? const Color(0xFFD4AF7A)
                                        : Colors.white24,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  listening
                                      ? Icons.mic_rounded
                                      : Icons.mic_off_rounded,
                                  color: listening
                                      ? const Color(0xFFD4AF7A)
                                      : Colors.white54,
                                  size: 36,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                        Text(
                          listening
                              ? (_isVi ? 'Đang lắng nghe...' : 'Listening...')
                              : (_isVi ? 'Đang xử lý...' : 'Processing...'),
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(minHeight: 60),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            words.isEmpty
                                ? (_isVi
                                    ? 'Hãy nói gì đó...'
                                    : 'Say something...')
                                : words,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton(
                              onPressed: () {
                                _speech.stop();
                                Navigator.pop(context);
                              },
                              child: Text(
                                _isVi ? 'Hủy' : 'Cancel',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                            ),
                            if (listening)
                              ElevatedButton(
                                onPressed: () {
                                  _speech.stop();
                                  setDialogState(() {
                                    listening = false;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFFE74C3C).withOpacity(0.2),
                                  foregroundColor: const Color(0xFFE74C3C),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(_isVi ? 'Dừng' : 'Stop'),
                              ),
                            if (!listening && words.isNotEmpty)
                              ElevatedButton(
                                onPressed: () {
                                  if (mounted) {
                                    setState(() {
                                      _searchController.text = words;
                                      _onSearchChanged(words);
                                    });
                                  }
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD4AF7A),
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(_isVi ? 'Tìm kiếm' : 'Search'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: child,
        );
      },
    );
  }

  static const List<String> vietnameseProvinces = [
    'Toàn quốc',
    'Đà Nẵng',
    'Hà Nội',
    'TP. Hồ Chí Minh',
    'Quảng Nam',
    'Quảng Ninh',
    'Thừa Thiên Huế',
    'Khánh Hòa',
    'Lào Cai',
    'Ninh Bình',
    'Bình Thuận',
    'Kiên Giang',
    'Bà Rịa - Vũng Tàu',
    'Quảng Bình',
    'An Giang',
    'Bạc Liêu',
    'Bắc Giang',
    'Bắc Kạn',
    'Bắc Ninh',
    'Bến Tre',
    'Bình Dương',
    'Bình Định',
    'Bình Phước',
    'Cà Mau',
    'Cao Bằng',
    'Cần Thơ',
    'Đắk Lắk',
    'Đắk Nông',
    'Điện Biên',
    'Đồng Nai',
    'Đồng Tháp',
    'Gia Lai',
    'Hà Giang',
    'Hà Nam',
    'Hà Tĩnh',
    'Hải Dương',
    'Hải Phòng',
    'Hậu Giang',
    'Hòa Bình',
    'Hưng Yên',
    'Kon Tum',
    'Lai Châu',
    'Lạng Sơn',
    'Lâm Đồng',
    'Long An',
    'Nam Định',
    'Nghệ An',
    'Ninh Thuận',
    'Phú Thọ',
    'Phú Yên',
    'Quảng Ngãi',
    'Quảng Trị',
    'Sóc Trăng',
    'Sơn La',
    'Tây Ninh',
    'Thái Bình',
    'Thái Nguyên',
    'Thanh Hóa',
    'Tiền Giang',
    'Trà Vinh',
    'Tuyên Quang',
    'Vĩnh Long',
    'Vĩnh Phúc',
    'Yên Bái',
  ];

  static const List<Map<String, String>> _locationKindOptions = [
    {'label': 'Tất cả', 'value': 'all'},
    {'label': 'Du lịch', 'value': 'places'},
    {'label': 'Chỗ ở', 'value': 'hotels'},
    {'label': 'Ăn uống', 'value': 'restaurants'},
  ];

  static const List<String> _placeTags = [
    'Điểm du lịch',
    'Danh lam & Thắng cảnh',
    'Thiên nhiên & Công viên',
    'Nơi mua sắm',
    'Hoạt động ngoài trời',
    'Bảo tàng',
    'Thông tin cho khách du lịch',
    'Khác',
    'Vui chơi & Giải trí',
    'Chuyến tham quan',
    'Phương tiện giao thông',
    'Công viên nước & giải trí',
    'Sự kiện',
    'Đồ ăn & Đồ uống',
    'Lớp học & hội thảo',
    'Hòa nhạc & chương trình biểu diễn',
    'Sòng bạc & Đánh bạc',
    'Sở thú & Thủy cung',
    'Chuyến tham quan bằng thuyền & thể thao dưới nước',
    'Spa & Sức khỏe',
    'Giải trí về đêm',
  ];

  static const List<String> _hotelTags = [
    'Khách sạn',
    'Khách sạn / Nhà nghỉ',
    'Khu nghỉ dưỡng',
    'Khách sạn nhỏ',
    'Nhà nghỉ',
    'Nhà trọ',
    'Cơ sở lưu trú đặc biệt',
    'Khách sạn đặc biệt',
    'Nhà khách',
    'B&B',
    'Cơ sở kinh doanh có dịch vụ giới hạn',
    'Nhà trọ đặc biệt',
    'Nhà ngoại ô',
    'Biệt thự',
    'Khách sạn nhỏ sang trọng',
    'B&B đặc biệt',
    'Nhà trọ',
    'Nhà gỗ nhỏ/Khu cắm trại',
    'Khách sạn có căn hộ',
    'Khu nghỉ dưỡng (Trọn gói)',
    'Nhà trại',
  ];

  static const List<String> _restaurantTags = [
    'Nhà hàng',
    'Ngồi xuống',
    'Quán cafe',
    'Đồ ăn nhanh',
  ];

  static const Map<String, int> _fakeLikeSeeds = {
    'Hạ Long Bay': 1243,
    'Hội An': 987,
    'Đà Nẵng': 1765,
    'Phong Nha': 842,
  };

  @override
  void initState() {
    super.initState();

    _navIndex = _normalizedTabIndex(widget.initialTabIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_navIndex == _tabSurvey &&
          MediaQuery.of(context).size.width < 800) {
        _openSurveyForCurrentLayout();
      } else {
        _updateTabRoute(_navIndex);
      }
    });
    _currentUserName = widget.userName;
    _selectedCity = vietnameseProvinces[0];
    _initMockNotifications();
    _initSpeech();
    _pageController = PageController(viewportFraction: 0.82, initialPage: 1000);
    _searchPageController =
        PageController(viewportFraction: 0.82, initialPage: 0);
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        _fetchSuggestionsPool();
      }
      setState(() {});
    });

    // Set initial background image paths
    final activeList = sampleDestinations;
    if (activeList.isNotEmpty) {
      _currentBgPath = activeList[0].bgBlurPath;
      _previousBgPath = activeList[0].bgBlurPath;
    }

    _bgFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bgFade = CurvedAnimation(
      parent: _bgFadeController,
      curve: Curves.easeInOut,
    );

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _cardEntrance = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _searchBarSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(_cardEntrance);
    _entranceController.forward();

    _loadSavedPlaces();
    _loadProfile();
    _fetchDestinations();
    _startAutoPlay();
    if (_navIndex == _tabSurvey) {
      _stopAutoPlay();
      _startSurveyAiWarmup();
    }
    _initGps();
  }

  @override
  void dispose() {
    _stopAutoPlay();
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _bgFadeController.dispose();
    _entranceController.dispose();
    _pageController.dispose();
    _searchPageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _stopAutoPlay();
    if (_navIndex != _tabExplore) return;

    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      if (_navIndex != _tabExplore) {
        _stopAutoPlay();
        return;
      }

      final destinations = _exploreDestinations;
      if (destinations.isEmpty) return;

      if (_pageController.hasClients) {
        int nextPage = (_pageController.page ?? 1000.0).round() + 1;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
  }

  void _onPageChanged(int index, {bool useSearchResults = false}) {
    final activeList =
        useSearchResults ? _searchDestinations : _exploreDestinations;
    if (index >= 0 && index < activeList.length) {
      final nextPath = activeList[index].bgBlurPath;
      if (nextPath != _currentBgPath) {
        setState(() {
          _previousBgPath = _currentBgPath;
          _currentBgPath = nextPath;
          _previousIndex = _currentIndex;
          if (useSearchResults) {
            _searchCurrentIndex = index;
          } else {
            _currentIndex = index;
          }
        });
        _bgFadeController.forward(from: 0);
      } else {
        setState(() {
          if (useSearchResults) {
            _searchCurrentIndex = index;
          } else {
            _currentIndex = index;
          }
        });
      }
    }
  }

  Future<void> _loadSavedPlaces({bool showError = false}) async {
    final token = widget.authToken?.trim();
    if (token == null || token.isEmpty) {
      return;
    }

    setState(() => _isLoadingSavedPlaces = true);

    try {
      final responses = await Future.wait([
        apiGet('/auth/profile/saved-places', token: token),
        apiGet('/auth/profile/saved-restaurants', token: token),
        apiGet('/auth/profile/saved-hotels', token: token),
      ]);

      if (!mounted) return;

      final allSucceeded =
          responses.every((response) => response.statusCode == 200);
      if (allSucceeded) {
        final payload = <String, dynamic>{
          'savedPlaces':
              tryDecodeJsonObject(responses[0].body)?['savedPlaces'] ?? [],
          'savedRestaurants':
              tryDecodeJsonObject(responses[1].body)?['savedRestaurants'] ?? [],
          'savedHotels':
              tryDecodeJsonObject(responses[2].body)?['savedHotels'] ?? [],
        };
        _applySavedPlacesPayload(payload);
      } else if (showError) {
        _showMessage('Không tải được danh sách đã lưu');
      }
    } catch (_) {
      if (mounted && showError) {
        _showMessage('Không kết nối được server để tải địa điểm đã lưu');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingSavedPlaces = false);
      }
    }
  }

  String get _selectedLocationEndpoint {
    switch (_selectedLocationKind) {
      case 'all':
        return '/locations';
      case 'hotels':
        return '/hotels';
      case 'restaurants':
        return '/restaurants';
      case 'places':
      default:
        return '/locations';
    }
  }

  String get _selectedLocationLabel {
    switch (_selectedLocationKind) {
      case 'all':
        return _isVi ? 'Tất cả' : 'All';
      case 'hotels':
        return _isVi ? 'Khách sạn' : 'Hotel';
      case 'restaurants':
        return _isVi ? 'Nhà hàng' : 'Restaurant';
      case 'places':
      default:
        return _isVi ? 'Địa điểm' : 'Place';
    }
  }

  List<String> get _activeTagOptions {
    switch (_selectedLocationKind) {
      case 'hotels':
        return _hotelTags;
      case 'restaurants':
        return _restaurantTags;
      case 'places':
      default:
        return _placeTags;
    }
  }

  String _selectedLocationKindLabel(String value) {
    switch (value) {
      case 'all':
        return _isVi ? 'Tất cả' : 'All';
      case 'hotels':
        return _isVi ? 'Chỗ ở' : 'Stay';
      case 'restaurants':
        return _isVi ? 'Ăn uống' : 'Dining';
      case 'places':
      default:
        return _isVi ? 'Du lịch' : 'Explore';
    }
  }

  String _tagsSummary(Set<String> tags) {
    if (tags.isEmpty) {
      return _isVi ? 'Chọn tags' : 'Select tags';
    }
    final displayTags = tags.map((t) => _getLocalizedDisplay(t));
    if (tags.length <= 2) {
      return displayTags.join(', ');
    }
    return _isVi
        ? '${tags.length} tags đã chọn'
        : '${tags.length} tags selected';
  }

  Future<String?> _showSingleSelectPopup({
    required String title,
    required List<String> options,
    required String? selectedValue,
    String? clearLabel,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF070E0D).withOpacity(0.95),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: options.length + (clearLabel == null ? 0 : 1),
                      separatorBuilder: (_, __) => Divider(
                          color: Colors.white.withOpacity(0.06), height: 1),
                      itemBuilder: (context, index) {
                        if (clearLabel != null && index == 0) {
                          final isSelected = selectedValue == null;
                          return ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            title: Text(
                              clearLabel,
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSelected
                                    ? const Color(0xFFD4AF7A)
                                    : Colors.white,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_rounded,
                                    color: Color(0xFFD4AF7A))
                                : null,
                            onTap: () => Navigator.pop(context, null),
                          );
                        }

                        final optionIndex =
                            clearLabel == null ? index : index - 1;
                        final option = options[optionIndex];
                        final isSelected = selectedValue != null &&
                            _getLocalizedDisplay(option) ==
                                _getLocalizedDisplay(selectedValue);
                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          title: Text(
                            _getLocalizedDisplay(option),
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected
                                  ? const Color(0xFFD4AF7A)
                                  : Colors.white,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_rounded,
                                  color: Color(0xFFD4AF7A))
                              : null,
                          onTap: () => Navigator.pop(context, option),
                        );
                      },
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

  Future<Set<String>?> _showMultiSelectPopup({
    required String title,
    required List<String> options,
    required Set<String> selectedValues,
  }) async {
    return showModalBottomSheet<Set<String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) {
        final tempSelection = {...selectedValues};

        return StatefulBuilder(
          builder: (context, setPopupState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.78,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF070E0D).withOpacity(0.95),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 46,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _isVi
                                ? 'Chọn một hoặc nhiều mục'
                                : 'Select one or more items',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.55),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: options.map((option) {
                              final isSelected = tempSelection.contains(option);
                              return GestureDetector(
                                onTap: () {
                                  setPopupState(() {
                                    if (isSelected) {
                                      tempSelection.remove(option);
                                    } else {
                                      tempSelection.add(option);
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFD4AF7A)
                                        : Colors.white.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFFD4AF7A)
                                          : Colors.white.withOpacity(0.08),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isSelected) ...[
                                        const Icon(
                                          Icons.check_rounded,
                                          size: 14,
                                          color: Colors.black,
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(
                                        _getLocalizedDisplay(option),
                                        style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected
                                              ? Colors.black
                                              : Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4AF7A),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () =>
                                Navigator.pop(context, tempSelection),
                            child: Text(
                              _isVi ? 'Chọn xong' : 'Done',
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
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
          },
        );
      },
    );
  }

  String _destinationCacheKey(String? city) {
    return [
      _selectedLocationKind,
      city ?? '__all__',
      _selectedCategory ?? '',
      _selectedTags.join('|'),
      _scoreRange.start.toStringAsFixed(1),
      _scoreRange.end.toStringAsFixed(1),
      _sortBy,
      _sortOrder,
      _filterLimit.toString(),
      _filterTime ?? '',
      _filterDate ?? '',
      _nearbyEnabled ? _radius.round().toString() : '',
    ].join('::');
  }

  Map<String, List<String>> _buildLocationQueryParams({
    String? query,
    String? city,
    int? limit,
    int page = 1,
  }) {
    final params = <String, List<String>>{};

    void add(String key, String? value) {
      final clean = value?.trim();
      if (clean != null && clean.isNotEmpty) {
        params[key] = [clean];
      }
    }

    add('query', query);
    if (city != 'Toàn quốc' && city != 'All') {
      add('city', city);
    }
    add('limit', (limit ?? _filterLimit).toString());
    add('page', page.toString());
    add('category', _selectedCategory);
    if (_selectedTags.isNotEmpty) {
      params['tag'] = _selectedTags.toList();
    }
    if (_scoreRange.start > 0) {
      add('minScore', _scoreRange.start.toStringAsFixed(1));
    }
    if (_scoreRange.end < 5) {
      add('maxScore', _scoreRange.end.toStringAsFixed(1));
    }
    add('sortBy', _sortBy);
    add('order', _sortOrder);
    add('time', _filterTime);
    add('date', _filterDate);

    if (_nearbyEnabled) {
      params['gps'] = ['108.26409,16.002966'];
      params['radius'] = [_radius.round().toString()];
    }

    return params;
  }

  Future<_DestinationPageResult> _fetchFilteredDestinationPage(
    String? city, {
    String? query,
    int? limit,
    int page = 1,
  }) async {
    final params = _buildLocationQueryParams(
      query: query,
      city: city,
      limit: limit,
      page: page,
    );
    final queryString = Uri(queryParameters: params).query;
    final path = queryString.isNotEmpty
        ? '$_selectedLocationEndpoint?$queryString'
        : _selectedLocationEndpoint;
    final response = await apiGet(path);
    final data = tryDecodeJsonObject(response.body);
    if (response.statusCode != 200 || data?['success'] != true) {
      return _DestinationPageResult.empty;
    }

    final rawList = data!['data'];
    if (rawList is! List) return _DestinationPageResult.empty;

    final List<Destination> loaded = [];
    for (final item in rawList) {
      try {
        final map = Map<String, dynamic>.from(item);
        map['type'] = _selectedLocationLabel;
        loaded.add(Destination.fromJson(map));
      } catch (e) {
        debugPrint('Error parsing filtered destination item: $e');
      }
    }
    final total =
        data['total'] is num ? (data['total'] as num).toInt() : loaded.length;
    final responsePage =
        data['page'] is num ? (data['page'] as num).toInt() : page;
    final totalPages = data['totalPages'] is num
        ? (data['totalPages'] as num).toInt()
        : (total / (limit ?? _filterLimit)).ceil();
    return _DestinationPageResult(
      items: loaded,
      total: total,
      page: responsePage < 1 ? 1 : responsePage,
      totalPages: totalPages < 1 ? 1 : totalPages,
    );
  }

  Future<List<Destination>> _fetchFilteredDestinationsForCity(
    String? city, {
    String? query,
    int? limit,
    int page = 1,
  }) async {
    final result = await _fetchFilteredDestinationPage(
      city,
      query: query,
      limit: limit,
      page: page,
    );
    return result.items;
  }

  Future<void> _fetchDestinations() async {
    if (mounted) {
      setState(() => _isLoadingDestinations = true);
    }
    try {
      // 1. Fetch top destinations for the selected city and location type
      final city = _selectedCity;
      final pageResult = await _fetchFilteredDestinationPage(city);
      final loaded = pageResult.items;

      if (mounted) {
        _cityCache[_destinationCacheKey(city)] = pageResult;
        setState(() {
          _realDestinations = loaded;
          _exploreBackendPage = pageResult.page;
          _exploreTotalItems = pageResult.total;
          _exploreTotalPages = pageResult.totalPages;
          _searchBackendPage = pageResult.page;
          _searchTotalItems = pageResult.total;
          _searchTotalPages = pageResult.totalPages;
          final list = _exploreDestinations;
          if (list.isNotEmpty) {
            _currentBgPath = list[0].bgBlurPath;
            _previousBgPath = list[0].bgBlurPath;
          }
        });
        _resetCarouselPosition();
        _startAutoPlay();
      }

      // 2. Fetch up to 150 locations from the actual backend database for rich autocomplete search suggestions
      final suggestionsResponse =
          await apiGet('/locations?limit=150&sortBy=reviewsCount&order=desc');
      final suggestionsData = tryDecodeJsonObject(suggestionsResponse.body);
      if (suggestionsResponse.statusCode == 200 &&
          suggestionsData?['success'] == true) {
        final rawSuggestions = suggestionsData!['data'];
        if (rawSuggestions is List) {
          final List<Destination> loadedSuggestions = [];
          for (var item in rawSuggestions) {
            try {
              loadedSuggestions
                  .add(Destination.fromJson(Map<String, dynamic>.from(item)));
            } catch (e) {
              debugPrint('Error parsing suggestion item: $e');
            }
          }
          if (mounted) {
            setState(() {
              _allDatabaseDestinations = loadedSuggestions;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching destinations: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingDestinations = false);
      }
    }
  }

  Future<void> _selectCity(String city, {bool clearSearch = true}) async {
    final cacheKey = _destinationCacheKey(city);
    if (_selectedCity == city &&
        _realDestinations.isNotEmpty &&
        (!clearSearch || _searchQuery.isEmpty)) {
      return;
    }

    if (_cityCache.containsKey(cacheKey)) {
      final cachedPage = _cityCache[cacheKey]!;
      setState(() {
        _selectedCity = city;
        _isLoadingDestinations = false;
        _currentIndex = 0;
        _searchCurrentIndex = 0;
        _searchResults = [];
        if (clearSearch) {
          _searchController.clear();
          _searchQuery = '';
        } else {
          _searchQuery = _searchController.text;
        }
        _realDestinations = cachedPage.items;
        _exploreBackendPage = cachedPage.page;
        _exploreTotalItems = cachedPage.total;
        _exploreTotalPages = cachedPage.totalPages;
        _searchBackendPage = cachedPage.page;
        _searchTotalItems = cachedPage.total;
        _searchTotalPages = cachedPage.totalPages;
        final list = _exploreDestinations;
        if (list.isNotEmpty) {
          _currentBgPath = list[0].bgBlurPath;
          _previousBgPath = list[0].bgBlurPath;
        } else {
          _currentBgPath = 'assets/images/halong.jpg';
          _previousBgPath = 'assets/images/halong.jpg';
        }
      });
      _resetCarouselPosition();
      _resetCarouselPosition(useSearchResults: true);
      _startAutoPlay();
      return;
    }

    setState(() {
      _selectedCity = city;
      _isLoadingDestinations = true;
      _currentIndex = 0;
      _searchCurrentIndex = 0;
      _searchResults = [];
      if (clearSearch) {
        _searchController.clear();
        _searchQuery = '';
      } else {
        _searchQuery = _searchController.text;
      }
      // Keep _realDestinations as-is so the UI stays stable while loading
    });

    try {
      final pageResult = await _fetchFilteredDestinationPage(city);
      final loaded = pageResult.items;

      if (mounted && _selectedCity == city) {
        _cityCache[cacheKey] = pageResult;
        setState(() {
          _realDestinations = loaded;
          _exploreBackendPage = pageResult.page;
          _exploreTotalItems = pageResult.total;
          _exploreTotalPages = pageResult.totalPages;
          _searchBackendPage = pageResult.page;
          _searchTotalItems = pageResult.total;
          _searchTotalPages = pageResult.totalPages;
          final list = _exploreDestinations;
          if (list.isNotEmpty) {
            _currentBgPath = list[0].bgBlurPath;
            _previousBgPath = list[0].bgBlurPath;
          } else {
            _currentBgPath = 'assets/images/halong.jpg';
            _previousBgPath = 'assets/images/halong.jpg';
          }
        });
        _resetCarouselPosition();
        _resetCarouselPosition(useSearchResults: true);
        _startAutoPlay();
      }
    } catch (e) {
      debugPrint('Error fetching destinations for city $city: $e');
    } finally {
      if (mounted && _selectedCity == city) {
        setState(() => _isLoadingDestinations = false);
      }
    }
  }

  Future<void> _fetchSuggestionsPool() async {
    if (_allDatabaseDestinations.isNotEmpty) return;
    try {
      final suggestionsResponse =
          await apiGet('/locations?limit=100&sortBy=reviewsCount&order=desc');
      final suggestionsData = tryDecodeJsonObject(suggestionsResponse.body);
      if (suggestionsResponse.statusCode == 200 &&
          suggestionsData?['success'] == true) {
        final rawSuggestions = suggestionsData!['data'];
        if (rawSuggestions is List) {
          final List<Destination> loadedSuggestions = [];
          for (var item in rawSuggestions) {
            try {
              loadedSuggestions
                  .add(Destination.fromJson(Map<String, dynamic>.from(item)));
            } catch (e) {
              debugPrint('Error parsing suggestion item: $e');
            }
          }
          if (mounted) {
            setState(() {
              _allDatabaseDestinations = loadedSuggestions;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching suggestions pool: $e');
    }
  }

  void _applySavedPlacesPayload(Map<String, dynamic> data) {
    List<Destination> parseItems(dynamic rawItems, String type) {
      if (rawItems is! List) return const [];
      return rawItems
          .whereType<Map>()
          .map((item) {
            final map = Map<String, dynamic>.from(item);
            map['type'] = type;
            return Destination.fromJson(map);
          })
          .where((item) => item.name.isNotEmpty)
          .toList();
    }

    final places = [
      ...parseItems(data['savedPlaces'], 'Địa điểm'),
      ...parseItems(data['savedRestaurants'], 'Nhà hàng'),
      ...parseItems(data['savedHotels'], 'Khách sạn'),
    ].where((item) => item.name.isNotEmpty).toList();

    setState(() {
      _savedDestinations = places;
      _savedNames
        ..clear()
        ..addAll(places.map((item) => item.name));
    });
  }

  Future<void> _loadProfile() async {
    final token = widget.authToken?.trim();
    if (token == null || token.isEmpty) return;

    setState(() => _isLoadingProfile = true);

    try {
      final response = await apiGet('/auth/profile', token: token);
      final data = tryDecodeJsonObject(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 && data?['success'] == true) {
        setState(() {
          final userMap = Map<String, dynamic>.from(data!['user']);
          if (userMap.containsKey('avatar') && userMap['avatar'] != null) {
            userMap['avatarUrl'] = userMap['avatar'];
          }
          _userData = userMap;
          if (_userData?['name'] != null) {
            _currentUserName = _userData!['name'];
          }
        });
      }
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
        _showMessage('Lỗi tải thông tin cá nhân');
      }
    }
  }

  String get _currentAvatarUrl {
    final rawAvatar = _userData?['avatarUrl'] ?? _userData?['avatar'];

    if (rawAvatar is String) {
      return rawAvatar.trim();
    }

    if (rawAvatar is Map && rawAvatar['url'] is String) {
      return (rawAvatar['url'] as String).trim();
    }

    return '';
  }

  Widget _buildAvatarPlaceholder(double iconSize) {
    return ColoredBox(
      color: Colors.white.withValues(alpha: 0.2),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          color: Colors.white.withValues(alpha: 0.9),
          size: iconSize,
        ),
      ),
    );
  }

  Widget _buildHomeAvatar({
    required double size,
    required double iconSize,
    double borderWidth = 1.5,
  }) {
    final avatarUrl = _currentAvatarUrl;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.2),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: borderWidth,
        ),
      ),
      child: ClipOval(
        child: avatarUrl.isNotEmpty
            ? Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(iconSize),
              )
            : _buildAvatarPlaceholder(iconSize),
      ),
    );
  }

  Future<bool> _requestPhotoPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;

    PermissionStatus status = PermissionStatus.denied;

    try {
      final photosStatus = await Permission.photos.status;
      if (photosStatus.isGranted || photosStatus.isLimited) {
        return true;
      }

      final storageStatus = await Permission.storage.status;
      if (storageStatus.isGranted) {
        return true;
      }

      status = await Permission.photos.request();
      if (status.isGranted || status.isLimited) {
        return true;
      }

      status = await Permission.storage.request();
      if (status.isGranted) {
        return true;
      }
    } catch (e) {
      debugPrint('Error requesting permission: $e');
    }

    if (status.isPermanentlyDenied) {
      if (mounted) {
        _showPermissionDeniedDialog();
      }
      return false;
    }

    return false;
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1B2321).withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withOpacity(0.12)),
          ),
          title: const Text(
            'Quyền truy cập ảnh bị từ chối',
            style: TextStyle(fontFamily: 'Montserrat', color: Colors.white),
          ),
          content: Text(
            'Ứng dụng cần quyền truy cập thư viện ảnh để tải lên avatar của bạn. Vui lòng cho phép trong cài đặt ứng dụng.',
            style: TextStyle(
              fontFamily: 'Montserrat',
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Hủy',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text(
                'Mở Cài đặt',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  color: Color(0xFFD4AF7A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(bool isAvatar) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final hasPermission = await _requestPhotoPermission();
      if (!hasPermission) {
        _showMessage('Ứng dụng chưa được cấp quyền truy cập thư viện ảnh');
        return;
      }
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isLoadingProfile = true);

      final imageBytes = await image.readAsBytes();
      final filename =
          image.name.isNotEmpty ? image.name : image.path.split('/').last;

      if (isAvatar) {
        final response = await apiPutMultipartBytes(
          '/auth/profile/avatar',
          'avatar',
          imageBytes,
          filename: filename,
          token: widget.authToken,
        );

        final responseStr = await response.stream.bytesToString();
        final data = tryDecodeJsonObject(responseStr);

        if (response.statusCode == 200 &&
            data != null &&
            data['success'] == true) {
          _loadProfile();
          _showMessage('Đã cập nhật ảnh đại diện thành công');
        } else {
          _showMessage(data?['message'] ?? 'Cập nhật avatar thất bại');
        }
      } else {
        final response = await apiPostMultipartBytes(
          '/auth/upload',
          'image',
          imageBytes,
          filename: filename,
          token: widget.authToken,
        );

        final responseStr = await response.stream.bytesToString();
        final data = tryDecodeJsonObject(responseStr);

        if (data != null && data['success'] == true) {
          final newUrl = data['imageUrl'];
          await _updateProfileImage(isAvatar, newUrl);
        } else {
          _showMessage(data?['message'] ?? 'Upload ảnh bìa thất bại');
        }
      }
    } catch (e) {
      _showMessage('Lỗi khi tải ảnh lên');
      debugPrint('Error picking/uploading image: $e');
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _updateProfileImage(bool isAvatar, String url) async {
    final token = widget.authToken?.trim();
    if (token == null || token.isEmpty) return;

    try {
      final response = await apiPutJson(
        '/auth/profile',
        isAvatar ? {'avatarUrl': url} : {'coverUrl': url},
        token: token,
      );
      final data = tryDecodeJsonObject(response.body);

      if (response.statusCode == 200 && data?['success'] == true) {
        _loadProfile(); // Refresh profile data
        _showMessage(
            isAvatar ? 'Đã cập nhật ảnh đại diện' : 'Đã cập nhật ảnh bìa');
      } else {
        _showMessage(data?['message'] ?? 'Cập nhật thất bại');
      }
    } catch (e) {
      _showMessage('Lỗi kết nối server');
    }
  }

  void _showEditImageDialog(bool isAvatar) {
    final TextEditingController urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1B2321).withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: Colors.white.withOpacity(0.12)),
          ),
          title: Text(
            isAvatar ? 'Cập nhật ảnh đại diện' : 'Cập nhật ảnh bìa',
            style: const TextStyle(
              fontFamily: 'Montserrat',
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Option 1: Pick from Gallery
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(isAvatar);
                },
                icon: const Icon(Icons.photo_library_rounded,
                    color: Colors.white),
                label: const Text(
                  'Chọn từ thư viện',
                  style: TextStyle(
                      fontFamily: 'Montserrat', fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB5956A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  shadowColor: const Color(0xFFB5956A).withOpacity(0.4),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                      child: Divider(color: Colors.white.withOpacity(0.1))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Hoặc nhập URL',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                      child: Divider(color: Colors.white.withOpacity(0.1))),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: TextField(
                  controller: urlController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'https://example.com/image.jpg',
                    hintStyle: TextStyle(color: Colors.white30),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Hủy',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final url = urlController.text.trim();
                if (url.isNotEmpty) {
                  Navigator.pop(context);
                  _updateProfileImage(isAvatar, url);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB5956A).withOpacity(0.2),
                foregroundColor: const Color(0xFFB5956A),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Lưu URL',
                style: TextStyle(
                    fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _logout() {
    final token = widget.authToken?.trim();
    if (token == null || token.isEmpty) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const SignInScreen(),
          transitionDuration: const Duration(milliseconds: 600),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1B2321).withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withOpacity(0.12)),
          ),
          title: const Text(
            'Đăng xuất?',
            style: TextStyle(fontFamily: 'Montserrat', color: Colors.white),
          ),
          content: Text(
            'Bạn có chắc chắn muốn đăng xuất khỏi TourXport?',
            style: TextStyle(
              fontFamily: 'Montserrat',
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Hủy',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                await AuthStorage.clearSession();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const SignInScreen(),
                    transitionDuration: const Duration(milliseconds: 600),
                    reverseTransitionDuration:
                        const Duration(milliseconds: 400),
                    transitionsBuilder: (_, animation, __, child) {
                      return FadeTransition(
                        opacity: CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeInOut,
                        ),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.05),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          )),
                          child: child,
                        ),
                      );
                    },
                  ),
                  (route) => false,
                );
              },
              child: const Text(
                'Đăng xuất',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  color: const Color(0xFFE74C3C),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSurveyResult(Object? result) {
    if (!mounted) return;

    switch (result) {
      case 'go_to_saved_tours':
        setState(() {
          _savedPlacesInitialTab = 1;
          _navIndex = _tabSaved;
        });
        _updateTabRoute(_tabSaved);
        _stopAutoPlay();
        break;
      case 'go_to_saved':
        _showMainTab(_tabSaved);
        break;
      case 'go_to_explore':
        _showMainTab(_tabExplore);
        break;
      case 'go_to_search':
        _showMainTab(_tabSearch);
        break;
      case 'go_to_account':
        _showMainTab(_tabProfile);
        break;
      case 'go_to_survey':
        _showSurveyTab();
        break;
      case 'logout':
        _logout();
        break;
    }
  }

  Future<void> _handleMainNavigationResult(String result) async {
    if (result == 'go_to_survey') {
      await _openSurveyForCurrentLayout();
      return;
    }

    _handleSurveyResult(result);
  }

  void _showSurveyTab() {
    setState(() {
      _savedPlacesInitialTab = 0;
      _navIndex = _tabSurvey;
    });
    _updateTabRoute(_tabSurvey);
    _stopAutoPlay();
    _startSurveyAiWarmup();
  }

  Future<bool> _pingAiBackend() async {
    try {
      final response = await apiAiGet('/', timeout: const Duration(seconds: 8));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  void _startSurveyAiWarmup() {
    final token = ++_surveyAiWarmupToken;
    setState(() {
      _isSurveyAiReady = false;
    });
    unawaited(_waitForSurveyAiBackend(token));
  }

  Future<void> _waitForSurveyAiBackend(int token) async {
    while (
        mounted && token == _surveyAiWarmupToken && _navIndex == _tabSurvey) {
      if (await _pingAiBackend()) {
        if (!mounted ||
            token != _surveyAiWarmupToken ||
            _navIndex != _tabSurvey) return;
        setState(() {
          _isSurveyAiReady = true;
        });
        return;
      }

      await Future<void>.delayed(const Duration(seconds: 3));
    }
  }

  Future<Object?> _openSurveyForCurrentLayout() async {
    _updateTabRoute(_tabSurvey);
    if (MediaQuery.of(context).size.width >= 800) {
      _showSurveyTab();
      return null;
    }

    _stopAutoPlay();
    final result = await _openSurveyScreen();
    _startAutoPlay();
    _handleSurveyResult(result);
    return result;
  }

  Future<Object?> _openSurveyScreen() {
    return Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => _SurveyAiWarmupGate(
          authToken: widget.authToken,
          userName: _currentUserName,
          avatarUrl: _currentAvatarUrl,
        ),
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Future<void> _editHelpSupport() async {
    final userData = _userData ?? {};
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            HelpSupportScreen(userData: userData, authToken: widget.authToken),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Future<void> _editLanguage() async {
    if (_userData == null) return;
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            LanguageSettingsScreen(userData: _userData!),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Future<void> _editPhone() async {
    if (_userData == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhoneSettingsScreen(
          userData: _userData!,
          authToken: widget.authToken!,
        ),
      ),
    );

    if (result == true) {
      _loadProfile();
    }
  }

  Future<void> _editSecurity() async {
    if (_userData == null) {
      // _showMessage('Vui lòng đợi cấu hình bảo mật đang tải...');
      return;
    }

    // _showMessage('Đang mở cài đặt bảo mật...');
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SecuritySettingsScreen(
          userData: _userData!,
          authToken: widget.authToken!,
        ),
      ),
    );
  }

  void _initMockNotifications() {
    _notifications = [
      TravelNotification(
        id: 'notif_1',
        title: 'Kế hoạch du lịch Đà Nẵng',
        description:
            'Lịch trình tham quan Đà Nẵng 3 ngày 2 đêm của bạn đã sẵn sàng! Chạm để xem ngay các địa điểm tối ưu.',
        icon: Icons.map_rounded,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        type: 'itinerary',
      ),
      TravelNotification(
        id: 'notif_2',
        title: 'Cảnh báo thời tiết',
        description:
            'Dự báo thời tiết Đà Nẵng hôm nay: 26°C, trời nắng đẹp, gió mát mẻ, rất lý tưởng để đi biển hoặc ghé Bà Nà Hills.',
        icon: Icons.wb_sunny_rounded,
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        type: 'weather',
      ),
      TravelNotification(
        id: 'notif_3',
        title: 'Cập nhật ngân sách chuyến đi',
        description:
            'Tổng chi tiêu dự kiến hiện tại là 1.250.000đ. Bạn đang kiểm soát ngân sách rất tốt (đạt 62% hạn mức tự đặt).',
        icon: Icons.account_balance_wallet_rounded,
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        type: 'expense',
      ),
      TravelNotification(
        id: 'notif_4',
        title: 'Mẹo du lịch hữu ích',
        description:
            'Kinh nghiệm đắt giá: Nên di chuyển lên Cầu Vàng lúc 8h sáng để chụp hình không vướng người và ngắm trọn mây ngàn.',
        icon: Icons.lightbulb_rounded,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        type: 'tip',
      ),
    ];
  }

  List<AppTrendRecommendation> _getAppTrendRecommendations() {
    final pool = _allDatabaseDestinations.isNotEmpty
        ? _allDatabaseDestinations
        : (_realDestinations.isNotEmpty
            ? _realDestinations
            : sampleDestinations);

    if (pool.isEmpty) return [];

    List<Destination> periodDestinations = [];
    String periodTag = '';
    String periodLabel = '';

    if (_selectedTrendFilter == 'day') {
      periodTag = _isVi ? 'HOT HÔM NAY' : 'HOT TODAY';
      periodLabel = 'day';
      for (int i = 0; i < pool.length; i++) {
        if (i % 3 == 0) periodDestinations.add(pool[i]);
      }
    } else if (_selectedTrendFilter == 'week') {
      periodTag = _isVi ? 'XU HƯỚNG TUẦN' : 'WEEK TRENDING';
      periodLabel = 'week';
      for (int i = 0; i < pool.length; i++) {
        if (i % 3 == 1) periodDestinations.add(pool[i]);
      }
    } else {
      periodTag = _isVi ? 'ĐỀ XUẤT THÁNG' : 'MONTH SUGGESTED';
      periodLabel = 'month';
      for (int i = 0; i < pool.length; i++) {
        if (i % 3 == 2) periodDestinations.add(pool[i]);
      }
    }

    if (periodDestinations.isEmpty) {
      periodDestinations = pool.take(3).toList();
    }

    return periodDestinations.take(10).map((dest) {
      final name = dest.name;
      final prov = dest.province;
      final price = dest.price.isNotEmpty
          ? dest.price
          : (_isVi ? 'Chỉ từ 1.5 triệu đồng' : 'From 1.5 million VND');

      String reason = '';
      String tag = periodTag;
      double rating = 4.7 + ((dest.name.length % 3) * 0.1);
      int reviews = 800 + (dest.name.length * 77) % 2500;

      if (name.toLowerCase().contains('hạ long') ||
          name.toLowerCase().contains('ha long')) {
        reason = _isVi
            ? 'Thời tiết tại Vịnh ${prov} tuần này vô cùng dịu mát, nước biển trong xanh lý tưởng để trải nghiệm du thuyền 5 sao đẳng cấp.'
            : 'The weather in ${_translateProvince(prov)} Bay this week is exceptionally cool, with clear blue waters perfect for a luxury 5-star cruise experience.';
        tag = _isVi ? 'DU THUYỀN 5 SAO' : '5-STAR CRUISE';
      } else if (name.toLowerCase().contains('đà nẵng') ||
          name.toLowerCase().contains('da nang')) {
        reason = _isVi
            ? 'Nhiệt độ hoàn hảo 26°C. Lễ hội pháo hoa quốc tế vừa diễn ra thu hút đông đảo du khách ghé thăm các cây cầu huyền thoại.'
            : 'Perfect temperature of 26°C. The international fireworks festival recently held is drawing crowds to visit the legendary bridges.';
        tag = _isVi ? 'PHÁO HOA QUỐC TẾ' : 'FIREWORKS FESTIVAL';
      } else if (name.toLowerCase().contains('hội an') ||
          name.toLowerCase().contains('hoi an')) {
        reason = _isVi
            ? 'Khí hậu bắt đầu vào mùa khô ráo tuyệt đẹp. Phố đèn lồng lung linh lộng lẫy và lễ hội hoa đăng bên sông Hoài đang diễn ra rất náo nhiệt.'
            : 'The dry season starts with beautiful weather. The lanternlit streets are gorgeous and the flower lantern festival by Hoai River is bustling.';
        tag = _isVi ? 'PHỐ CỔ HOÀI CỔ' : 'ANCIENT TOWN';
      } else if (name.toLowerCase().contains('phong nha') ||
          name.toLowerCase().contains('quảng bình') ||
          name.toLowerCase().contains('quang binh')) {
        reason = _isVi
            ? 'Thời tiết khô ráo rất thích hợp để thám hiểm hệ thống hang động thạch nhũ tráng lệ bậc nhất thế giới.'
            : 'Dry weather is highly suitable for exploring the world\'s most magnificent stalactite cave systems.';
        tag = _isVi ? 'KHÁM PHÁ HANG ĐỘNG' : 'CAVE EXPLORATION';
      } else if (name.toLowerCase().contains('phú quốc') ||
          name.toLowerCase().contains('phu quoc')) {
        reason = _isVi
            ? 'Biển cực kỳ êm, nắng vàng rực rỡ và nước biển trong vắt như pha lê, hoàn hảo cho tour lặn biển ngắm san hô.'
            : 'The sea is extremely calm, with golden sunshine and crystal-clear water, perfect for coral reef diving tours.';
        tag = _isVi ? 'THIÊN ĐƯỜNG BIỂN' : 'BEACH PARADISE';
      } else if (name.toLowerCase().contains('sapa')) {
        reason = _isVi
            ? 'Đỉnh Fansipan xuất hiện biển mây cực đẹp vào sáng sớm, nhiệt độ se lạnh lý tưởng để thưởng thức ẩm thực Tây Bắc.'
            : 'Fansipan peak features a beautiful sea of clouds in the early morning, with cool temperatures ideal for Northwest cuisine.';
        tag = _isVi ? 'SĂN MÂY TÂY BẮC' : 'CLOUD HUNTING';
      } else if (name.toLowerCase().contains('đà lạt') ||
          name.toLowerCase().contains('da lat')) {
        reason = _isVi
            ? 'Mùa hoa dã quỳ vàng rực rỡ khắp các triền đồi, không khí mát mẻ dễ chịu vô cùng thích hợp cho cắm trại đêm.'
            : 'Wild sunflowers bloom in brilliant yellow across the hills, with cool pleasant air perfect for night camping.';
      } else {
        reason = _isVi
            ? 'Điểm đến đang nhận được sự quan tâm đột biến từ cộng đồng du lịch nhờ khí hậu thuận lợi và nhiều ưu đãi dịch vụ hấp dẫn trong thời gian này.'
            : 'This destination is receiving surging interest from the travel community due to favorable climate and attractive deals.';
        tag = _isVi ? 'ĐIỂM ĐẾN VÀNG' : 'GOLDEN DESTINATION';
      }

      final translatedPrice = _isVi
          ? price
          : price
              .replaceAll('Chỉ từ', 'From')
              .replaceAll('triệu đồng', 'm VND')
              .replaceAll('triệu', 'm');

      return AppTrendRecommendation(
        title: _isVi
            ? '$name - Khám phá vẻ đẹp kỳ diệu'
            : '$name - Discover Magical Beauty',
        province: _translateProvince(prov),
        price: translatedPrice,
        imagePath: dest.imagePath,
        rating: rating,
        reviewsCount: reviews,
        tag: tag,
        trendingReason: reason,
        period: periodLabel,
        destination: dest,
      );
    }).toList();
  }

  void _showNotificationCenter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final unreadCount = _notifications.where((n) => !n.isRead).length;

            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.85,
                decoration: BoxDecoration(
                  color: const Color(0xFF070E0D).withOpacity(0.85),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(32)),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Handle bar
                    const SizedBox(height: 12),
                    Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Header Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Trung tâm thông báo',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (unreadCount > 0)
                            GestureDetector(
                              onTap: () {
                                setSheetState(() {
                                  for (var n in _notifications) {
                                    n.isRead = true;
                                  }
                                });
                                setState(() {});
                              },
                              child: Text(
                                'Đọc tất cả ($unreadCount)',
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFD4AF7A),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Beautiful Sliding Segmented Tabs
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            // Tab 1: Cá nhân
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setSheetState(() {
                                    _selectedNotificationTab = 0;
                                  });
                                  setState(() {});
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _selectedNotificationTab == 0
                                        ? const Color(0xFFD4AF7A)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.person_outline_rounded,
                                        size: 16,
                                        color: _selectedNotificationTab == 0
                                            ? Colors.black
                                            : Colors.white60,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Cá nhân',
                                        style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: _selectedNotificationTab == 0
                                              ? Colors.black
                                              : Colors.white60,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Tab 2: Xu hướng Hot
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setSheetState(() {
                                    _selectedNotificationTab = 1;
                                  });
                                  setState(() {});
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _selectedNotificationTab == 1
                                        ? const Color(0xFFD4AF7A)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.local_fire_department_rounded,
                                        size: 16,
                                        color: _selectedNotificationTab == 1
                                            ? Colors.black
                                            : Colors.white60,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Xu hướng Hot',
                                        style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: _selectedNotificationTab == 1
                                              ? Colors.black
                                              : Colors.white60,
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
                    const SizedBox(height: 16),

                    // Tab Views
                    Expanded(
                      child: _selectedNotificationTab == 0
                          ? _buildPersonalTab(setSheetState)
                          : _buildTrendsTab(setSheetState),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPersonalTab(StateSetter setSheetState) {
    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_none_rounded,
                color: Colors.white24, size: 64),
            const SizedBox(height: 16),
            Text(
              _isVi
                  ? 'Chưa có thông báo nào dành cho bạn'
                  : 'No notifications for you yet',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 15,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: _notifications.length > 10 ? 10 : _notifications.length,
      itemBuilder: (context, index) {
        final item = _notifications[index];
        final typeColors = {
          'itinerary': const Color(0xFF3498DB),
          'weather': const Color(0xFFF1C40F),
          'expense': const Color(0xFF2ECC71),
          'tip': const Color(0xFFE67E22),
          'system': const Color(0xFF95A5A6),
        };
        final iconBg = typeColors[item.type] ?? const Color(0xFFD4AF7A);

        return GestureDetector(
          onTap: () {
            setSheetState(() {
              item.isRead = true;
            });
            setState(() {});
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: item.isRead
                  ? Colors.white.withOpacity(0.03)
                  : const Color(0xFFD4AF7A).withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: item.isRead
                    ? Colors.white.withOpacity(0.06)
                    : const Color(0xFFD4AF7A).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                if (!item.isRead)
                                  Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE74C3C),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: item.isRead
                                          ? Colors.white
                                          : const Color(0xFFD4AF7A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatTimestamp(item.timestamp),
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.35),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.description,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 13,
                          height: 1.4,
                          color: Colors.white
                              .withOpacity(item.isRead ? 0.6 : 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else {
      return 'Hôm qua';
    }
  }

  Widget _buildTrendsTab(StateSetter setSheetState) {
    final trends = _getAppTrendRecommendations();

    return Column(
      children: [
        // Horizontal sliding segmented filters
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              _buildTrendFilterButton(
                  'day', _isVi ? 'Hôm nay' : 'Today', setSheetState),
              const SizedBox(width: 8),
              _buildTrendFilterButton(
                  'week', _isVi ? 'Tuần này' : 'This Week', setSheetState),
              const SizedBox(width: 8),
              _buildTrendFilterButton(
                  'month', _isVi ? 'Tháng này' : 'This Month', setSheetState),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Scrollable list of recommendations
        Expanded(
          child: trends.isEmpty
              ? Center(
                  child: Text(
                    _isVi
                        ? 'Không có đề xuất nào cho khoảng thời gian này.'
                        : 'No recommendations for this period.',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: trends.length,
                  itemBuilder: (context, index) {
                    final rec = trends[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          children: [
                            // Place image background
                            AspectRatio(
                              aspectRatio: 1.5,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1E1E1E),
                                ),
                                child: Destination.buildImage(
                                  rec.imagePath,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            // Gradient overlay
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.1),
                                      Colors.black.withOpacity(0.4),
                                      Colors.black.withOpacity(0.95),
                                    ],
                                    stops: const [0.0, 0.4, 1.0],
                                  ),
                                ),
                              ),
                            ),
                            // Card details
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Top row
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFFD4AF7A),
                                                Color(0xFFB5956A)
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFD4AF7A)
                                                    .withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            rec.tag,
                                            style: const TextStyle(
                                              fontFamily: 'Montserrat',
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.black,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withOpacity(0.6),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                                color: Colors.white24,
                                                width: 0.8),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.star_rounded,
                                                  color: Color(0xFFF1C40F),
                                                  size: 14),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${rec.rating}',
                                                style: const TextStyle(
                                                  fontFamily: 'Montserrat',
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Bottom section
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    rec.province.toUpperCase(),
                                                    style: const TextStyle(
                                                      fontFamily: 'Montserrat',
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFFD4AF7A),
                                                      letterSpacing: 1.0,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    rec.title,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontFamily: 'Montserrat',
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                      letterSpacing: -0.2,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              rec.price,
                                              style: const TextStyle(
                                                fontFamily: 'Montserrat',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          rec.trendingReason,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontSize: 12.5,
                                            height: 1.4,
                                            color:
                                                Colors.white.withOpacity(0.8),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '⭐ ${rec.rating} · ${rec.reviewsCount} lượt quan tâm',
                                              style: TextStyle(
                                                fontFamily: 'Montserrat',
                                                fontSize: 12,
                                                color: Colors.white
                                                    .withOpacity(0.5),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.pop(context);
                                                _openPlaceDetail(
                                                    rec.destination, context);
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  border: Border.all(
                                                      color: const Color(
                                                          0xFFD4AF7A),
                                                      width: 1.5),
                                                ),
                                                child: const Row(
                                                  children: [
                                                    Text(
                                                      'Lên lịch ngay',
                                                      style: TextStyle(
                                                        fontFamily:
                                                            'Montserrat',
                                                        fontSize: 12.5,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Color(0xFFD4AF7A),
                                                      ),
                                                    ),
                                                    SizedBox(width: 4),
                                                    Icon(
                                                        Icons
                                                            .arrow_forward_rounded,
                                                        color:
                                                            Color(0xFFD4AF7A),
                                                        size: 14),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTrendFilterButton(
      String key, String title, StateSetter setSheetState) {
    final isActive = _selectedTrendFilter == key;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setSheetState(() {
            _selectedTrendFilter = key;
          });
          setState(() {});
        },
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFD4AF7A).withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? const Color(0xFFD4AF7A) : Colors.white12,
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12.5,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? const Color(0xFFD4AF7A) : Colors.white60,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editNotifications() async {
    if (_userData == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationSettingsScreen(
          userData: _userData!,
          authToken: widget.authToken!,
        ),
      ),
    );
  }

  Future<bool> _toggleSaved(Destination dest) async {
    final token = widget.authToken?.trim();
    if (token == null || token.isEmpty) {
      _showMessage('Bạn cần đăng nhập để lưu địa điểm');
      return false;
    }

    if (_updatingSavedNames.contains(dest.name)) {
      return _savedNames.contains(dest.name);
    }

    final currentlySaved = _savedNames.contains(dest.name);
    setState(() => _updatingSavedNames.add(dest.name));

    try {
      String? placeId = dest.id;
      if (placeId == null || placeId.isEmpty) {
        final savedMatch = _savedDestinations.firstWhere(
          (item) => item.name.toLowerCase() == dest.name.toLowerCase(),
          orElse: () => const Destination(
              name: '', province: '', price: '', imagePath: '', bgBlurPath: ''),
        );
        if (savedMatch.name.isNotEmpty) {
          placeId = savedMatch.id;
        }
      }

      if ((placeId == null || placeId.isEmpty) && !currentlySaved) {
        placeId =
            await resolveLocationIdByName(dest.name, dest.type, token: token);
      }

      if (placeId == null || placeId.isEmpty) {
        _showMessage('Không tìm thấy thông tin địa điểm này trên hệ thống');
        return currentlySaved;
      }

      final savedEndpoint = savedLocationEndpointForType(dest.type);
      final savedBodyKey = savedLocationBodyKeyForType(dest.type);
      final response = currentlySaved
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
      if (!mounted) return currentlySaved;

      if (response.statusCode == 200 && data?['success'] == true) {
        await _loadSavedPlaces();
        _showMessage(
          currentlySaved ? 'Đã bỏ lưu ${dest.name}' : 'Đã lưu ${dest.name}',
        );
      } else {
        _showMessage(data?['message'] as String? ??
            'Không cập nhật được địa điểm đã lưu');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Không kết nối được server để cập nhật địa điểm đã lưu');
      }
    } finally {
      if (mounted) {
        setState(() => _updatingSavedNames.remove(dest.name));
      }
    }

    return _savedNames.contains(dest.name);
  }

  void _applySavedStateFromDetail(Destination dest, bool isSaved) {
    setState(() {
      if (isSaved) {
        _savedNames.add(dest.name);
        final exists = _savedDestinations.any((item) => item.name == dest.name);
        if (!exists) {
          _savedDestinations = [..._savedDestinations, dest];
        }
      } else {
        _savedNames.remove(dest.name);
        _savedDestinations =
            _savedDestinations.where((item) => item.name != dest.name).toList();
      }
    });
  }

  void _toggleLike(Destination dest) {
    setState(() {
      if (_likedNames.contains(dest.name)) {
        _likedNames.remove(dest.name);
      } else {
        _likedNames.add(dest.name);
      }
    });
  }

  int _fakeLikeCountFor(Destination dest, {required bool isLiked}) {
    final seeded = _fakeLikeSeeds[dest.name] ?? (700 + (dest.name.length * 37));
    return isLiked ? seeded + 1 : seeded;
  }

  Future<void> _openPlaceDetail(
      Destination dest, BuildContext cardContext) async {
    final useSimpleTransition = _navIndex == _tabSaved;
    Rect? cardRect;

    if (!useSimpleTransition) {
      final renderBox = cardContext.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final offset = renderBox.localToGlobal(Offset.zero);
        cardRect = offset & renderBox.size;
      }
    }

    _stopAutoPlay();
    _updatePlaceDetailRoute(dest);

    final result = await Navigator.push<Map<String, bool>>(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => PlaceDetailScreen(
          destination: dest,
          cardRect: cardRect,
          isSaved: _savedNames.contains(dest.name),
          isLiked: _likedNames.contains(dest.name),
          authToken: widget.authToken,
          useSimpleTransition: useSimpleTransition,
        ),
        transitionDuration: Duration(
          milliseconds: useSimpleTransition ? 480 : 800,
        ),
        reverseTransitionDuration: Duration(
          milliseconds: useSimpleTransition ? 360 : 800,
        ),
        transitionsBuilder: (_, animation, __, child) {
          if (!useSimpleTransition) return child;

          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          );
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(fade);

          return FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: slide,
              child: child,
            ),
          );
        },
      ),
    );

    if (mounted && kIsWeb) {
      _updateTabRoute(_navIndex);
    }

    _startAutoPlay();

    if (!mounted || result == null) return;
    final isSaved = result['isSaved'];
    final isLiked = result['isLiked'];
    if (isSaved != null) {
      _applySavedStateFromDetail(dest, isSaved);
      _loadSavedPlaces();
    }
    if (isLiked != null) {
      setState(() {
        if (isLiked) {
          _likedNames.add(dest.name);
        } else {
          _likedNames.remove(dest.name);
        }
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _jumpToRegion(String region) {
    final destinations = _exploreDestinations;
    final idx =
        destinations.indexWhere((d) => _citiesMatch(d.province, region));
    if (idx >= 0 && idx != _currentIndex) {
      if (_pageController.hasClients) {
        final currentPage = _pageController.page?.round() ?? 1000;
        final currentListIndex = currentPage % destinations.length;
        final offset = idx - currentListIndex;
        _pageController.animateToPage(
          currentPage + offset,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    } else if (idx < 0) {
      _showMessage('Không có địa điểm phù hợp bộ lọc hiện tại');
    }
  }

  String _stripDiacritics(String str) {
    var withDiacritics =
        'àáảãạăắằẳẵặâấầẩẫậèéẻẽẹêếềểễệìíỉĩịòóỏõọôốồổỗộơớờởỡợùúủũụưứừửữựỳýỷỹỵđĐ';
    var withoutDiacritics =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyydd';
    var result = str.toLowerCase();
    result = result.replaceAll(RegExp(r'[\u0300-\u036f]'), '');
    for (int i = 0; i < withDiacritics.length; i++) {
      result = result.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }
    return result.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _cleanCityName(String str) {
    var clean = _stripDiacritics(str);
    clean = clean
        .replaceAll('thanh pho ', '')
        .replaceAll('tp. ', '')
        .replaceAll('tp ', '')
        .replaceAll('tinh ', '');
    return clean.trim();
  }

  bool _citiesMatch(String cityA, String cityB) {
    final a = _cleanCityName(cityA);
    final b = _cleanCityName(cityB);
    return a == b || a.contains(b) || b.contains(a);
  }

  List<Destination> get _exploreDestinations {
    final list = List<Destination>.from(_realDestinations);
    if (_showLikedOnly) {
      return list.where((d) => _likedNames.contains(d.name)).toList();
    }
    return list;
  }

  List<Destination> get _searchDestinations {
    if (_searchQuery.isNotEmpty || _nearbyEnabled) {
      var list = _searchResults;
      if (_showLikedOnly) {
        list = list.where((d) => _likedNames.contains(d.name)).toList();
      }
      return list;
    }

    // 1. Use ALL real database destinations directly (the API already filtered by city)
    final List<Destination> list = List<Destination>.from(_realDestinations);

    var filteredList = list;
    if (_showLikedOnly) {
      filteredList = list.where((d) => _likedNames.contains(d.name)).toList();
    }
    return filteredList;
  }

  String _normalizeString(String str) {
    const withSign =
        'aáàảãạâấầẩẫậăắằẳẵặeéèẻẽẹêếềểễệiíìỉĩịoóòỏõọôốồổỗộơớờởỡợuúùủũụưứừửữựyýỳỷỹỵđĐ';
    const noSign =
        'aaaaaaaaaaaaaaaaaaeeeeeeeeeeeeiiiiiioooooooooooooooooouuuuuuuuuuuuyyyyyydd';
    var result = str.toLowerCase().trim();
    for (var i = 0; i < withSign.length; i++) {
      result = result.replaceAll(withSign[i], noSign[i]);
    }
    return result;
  }

  void _onSearchChanged(String value) {
    final cleanVal = _normalizeString(value);
    if (cleanVal.isNotEmpty) {
      String? matchedProv;
      for (final prov in vietnameseProvinces) {
        if (prov == 'Toàn quốc' || prov == 'All') continue;
        final cleanProv = _normalizeString(prov);
        final cleanTranslated = _normalizeString(_translateProvince(prov));
        final isExact = (cleanVal == cleanProv || cleanVal == cleanTranslated);
        final isPartial = (cleanVal.length >= 5 &&
            (cleanProv.contains(cleanVal) ||
                cleanTranslated.contains(cleanVal) ||
                cleanVal.contains(cleanProv) ||
                cleanVal.contains(cleanTranslated)));
        if (isExact || isPartial) {
          matchedProv = prov;
          break;
        }
      }

      if (matchedProv != null) {
        _selectCity(matchedProv, clearSearch: false);
        setState(() {
          _searchQuery = value;
          _searchResults = [];
        });
        _searchDebounceTimer?.cancel();
        _searchDebounceTimer =
            Timer(const Duration(milliseconds: 300), () async {
          await _performBackendSearch(value);
        });
        return;
      }
    }

    setState(() {
      _searchQuery = value;
      _searchCurrentIndex = 0;
      _searchSuggestions = [];
    });

    _searchDebounceTimer?.cancel();
    if (value.trim().isEmpty && !_nearbyEnabled) {
      setState(() {
        _searchResults = [];
        _searchSuggestions = [];
        _searchBackendPage = _exploreBackendPage;
        _searchTotalItems = _exploreTotalItems;
        _searchTotalPages = _exploreTotalPages;
      });
      _resetCarouselPosition(useSearchResults: true);
      final list = _searchDestinations;
      if (list.isNotEmpty) {
        setState(() {
          _currentBgPath = list[0].bgBlurPath;
          _previousBgPath = list[0].bgBlurPath;
        });
      }
      return;
    }

    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () async {
      await _performBackendSearch(value);
    });
  }

  Future<void> _performBackendSearch(String query) async {
    try {
      final pageResult = await _fetchFilteredDestinationPage(
        _selectedCity,
        query: query,
        limit: _filterLimit,
      );
      final loaded = pageResult.items;
      if (mounted && _searchQuery == query) {
        setState(() {
          _searchResults = loaded;
          _searchSuggestions = loaded.take(5).toList();
          _searchCurrentIndex = 0;
          _searchBackendPage = pageResult.page;
          _searchTotalItems = pageResult.total;
          _searchTotalPages = pageResult.totalPages;

          if (_searchResults.isNotEmpty) {
            _currentBgPath = _searchResults[0].bgBlurPath;
            _previousBgPath = _searchResults[0].bgBlurPath;
          }
        });
        _resetCarouselPosition(useSearchResults: true);
      }
    } catch (e) {
      debugPrint('Error performing backend search: $e');
    }
  }

  Future<void> _applyCurrentFilters() async {
    if (_searchQuery.trim().isNotEmpty || _nearbyEnabled) {
      await _performBackendSearch(_searchQuery);
      return;
    }

    final city = _selectedCity;
    setState(() {
      _isLoadingDestinations = true;
      _currentIndex = 0;
      _searchCurrentIndex = 0;
      _searchResults = [];
      _searchSuggestions = [];
    });

    try {
      final pageResult = await _fetchFilteredDestinationPage(city);
      final loaded = pageResult.items;
      if (!mounted) return;
      _cityCache[_destinationCacheKey(city)] = pageResult;
      setState(() {
        _realDestinations = loaded;
        _exploreBackendPage = pageResult.page;
        _exploreTotalItems = pageResult.total;
        _exploreTotalPages = pageResult.totalPages;
        _searchBackendPage = pageResult.page;
        _searchTotalItems = pageResult.total;
        _searchTotalPages = pageResult.totalPages;
        final list = _exploreDestinations;
        if (list.isNotEmpty) {
          _currentBgPath = list[0].bgBlurPath;
          _previousBgPath = list[0].bgBlurPath;
        }
      });
      _resetCarouselPosition();
      _resetCarouselPosition(useSearchResults: true);
    } catch (e) {
      debugPrint('Error applying filters: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingDestinations = false);
      }
    }
  }

  void _resetCarouselPosition({bool useSearchResults = false}) {
    final controller =
        useSearchResults ? _searchPageController : _pageController;
    if (controller.hasClients) {
      final list =
          useSearchResults ? _searchDestinations : _exploreDestinations;
      if (list.length > 3) {
        controller.jumpToPage(1000 - (1000 % list.length));
      } else {
        controller.jumpToPage(0);
      }
    }
  }

  int _carouselGlobalIndex({required bool useSearchResults}) {
    final list = useSearchResults ? _searchDestinations : _exploreDestinations;
    if (list.isEmpty) return 0;

    final page = useSearchResults ? _searchBackendPage : _exploreBackendPage;
    final localIndex = useSearchResults ? _searchCurrentIndex : _currentIndex;
    final total = useSearchResults ? _searchTotalItems : _exploreTotalItems;
    final value = ((page - 1) * _filterLimit) + localIndex + 1;
    return total <= 0 ? value : value.clamp(1, total).toInt();
  }

  int _carouselTotalCount({required bool useSearchResults}) {
    final total = useSearchResults ? _searchTotalItems : _exploreTotalItems;
    final list = useSearchResults ? _searchDestinations : _exploreDestinations;
    return total > 0 ? total : list.length;
  }

  Future<void> _animateCarouselToIndex(
    int targetIndex, {
    required bool useSearchResults,
  }) async {
    final list = useSearchResults ? _searchDestinations : _exploreDestinations;
    if (targetIndex < 0 || targetIndex >= list.length) return;

    final controller =
        useSearchResults ? _searchPageController : _pageController;
    if (!controller.hasClients) {
      _onPageChanged(targetIndex, useSearchResults: useSearchResults);
      return;
    }

    final page = controller.page?.round() ?? 0;
    final targetPage = list.length > 3
        ? page + (targetIndex - (page % list.length))
        : targetIndex;
    await controller.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _jumpCarouselToIndex(
    int targetIndex, {
    required bool useSearchResults,
  }) {
    final list = useSearchResults ? _searchDestinations : _exploreDestinations;
    if (targetIndex < 0 || targetIndex >= list.length) return;

    final controller =
        useSearchResults ? _searchPageController : _pageController;
    _onPageChanged(targetIndex, useSearchResults: useSearchResults);
    if (!controller.hasClients) return;

    final targetPage = list.length > 3
        ? (1000 - (1000 % list.length)) + targetIndex
        : targetIndex;
    controller.jumpToPage(targetPage);
  }

  Future<void> _loadCarouselBackendPage(
    int page, {
    required bool useSearchResults,
    bool jumpToLast = false,
  }) async {
    final query = useSearchResults ? _searchQuery : null;
    final pageResult = await _fetchFilteredDestinationPage(
      _selectedCity,
      query: query,
      limit: _filterLimit,
      page: page,
    );
    if (!mounted || pageResult.items.isEmpty) return;

    setState(() {
      if (useSearchResults) {
        final hasSearchFilter =
            _searchQuery.trim().isNotEmpty || _nearbyEnabled;
        if (hasSearchFilter) {
          _searchResults = pageResult.items;
          _searchSuggestions = pageResult.items.take(5).toList();
        } else {
          _realDestinations = pageResult.items;
          _exploreBackendPage = pageResult.page;
          _exploreTotalItems = pageResult.total;
          _exploreTotalPages = pageResult.totalPages;
          if (pageResult.page == 1) {
            _cityCache[_destinationCacheKey(_selectedCity)] = pageResult;
          }
        }
        _searchBackendPage = pageResult.page;
        _searchTotalItems = pageResult.total;
        _searchTotalPages = pageResult.totalPages;
        _searchCurrentIndex = jumpToLast ? pageResult.items.length - 1 : 0;
      } else {
        _realDestinations = pageResult.items;
        _exploreBackendPage = pageResult.page;
        _exploreTotalItems = pageResult.total;
        _exploreTotalPages = pageResult.totalPages;
        _currentIndex = jumpToLast ? pageResult.items.length - 1 : 0;
        if (pageResult.page == 1) {
          _cityCache[_destinationCacheKey(_selectedCity)] = pageResult;
        }
      }
    });
    _jumpCarouselToIndex(
      jumpToLast ? pageResult.items.length - 1 : 0,
      useSearchResults: useSearchResults,
    );
  }

  Future<void> _goToCarouselPage(
    int direction, {
    required bool useSearchResults,
  }) async {
    if (_isChangingCarouselPage || direction == 0) return;

    final list = useSearchResults ? _searchDestinations : _exploreDestinations;
    if (list.isEmpty) return;

    final currentIndex = useSearchResults ? _searchCurrentIndex : _currentIndex;
    final nextIndex = currentIndex + direction;
    final backendPage =
        useSearchResults ? _searchBackendPage : _exploreBackendPage;
    final totalPages =
        useSearchResults ? _searchTotalPages : _exploreTotalPages;

    _isChangingCarouselPage = true;
    try {
      if (nextIndex >= 0 && nextIndex < list.length) {
        await _animateCarouselToIndex(
          nextIndex,
          useSearchResults: useSearchResults,
        );
      } else if (direction > 0 && backendPage < totalPages) {
        await _loadCarouselBackendPage(
          backendPage + 1,
          useSearchResults: useSearchResults,
        );
      } else if (direction < 0 && backendPage > 1) {
        await _loadCarouselBackendPage(
          backendPage - 1,
          useSearchResults: useSearchResults,
          jumpToLast: true,
        );
      }
    } finally {
      _isChangingCarouselPage = false;
    }
  }

  Future<void> _openSearchToolsSheet() async {
    final cities = vietnameseProvinces;
    final sortOptions = [
      {'label': 'Lượt review', 'field': 'reviewsCount', 'order': 'desc'},
      {'label': 'Điểm số', 'field': 'totalScore', 'order': 'desc'},
      {'label': 'Tên A-Z', 'field': 'title', 'order': 'asc'},
      {'label': 'Thành phố', 'field': 'city', 'order': 'asc'},
      {'label': 'Mới nhất', 'field': 'createdAt', 'order': 'desc'},
      {'label': 'Vừa cập nhật', 'field': 'updatedAt', 'order': 'desc'},
    ];
    final limitOptions = [10, 20, 50];

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF131D1A).withOpacity(0.98),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(
                    color: Colors.white.withOpacity(0.08), width: 1.5),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 26,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 46,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isVi ? 'Bộ lọc' : 'Filters',
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (_selectedCity != vietnameseProvinces[0] ||
                            _nearbyEnabled ||
                            _sortBy != 'reviewsCount' ||
                            _selectedLocationKind != 'places' ||
                            _selectedCategory != null ||
                            _selectedTags.isNotEmpty ||
                            _scoreRange.start > 0 ||
                            _scoreRange.end < 5 ||
                            _filterTime != null ||
                            _filterDate != null ||
                            _filterLimit != 10)
                          GestureDetector(
                            onTap: () {
                              setSheetState(() {
                                _selectedCity = vietnameseProvinces[0];
                                _selectedLocationKind = 'places';
                                _selectedCategory = null;
                                _selectedTags.clear();
                                _scoreRange = const RangeValues(0, 5);
                                _filterTime = null;
                                _filterDate = null;
                                _filterLimit = 10;
                                _nearbyEnabled = false;
                                _sortBy = 'reviewsCount';
                                _sortOrder = 'desc';
                              });
                              setState(() {});
                              _applyCurrentFilters();
                            },
                            child: Text(
                              _isVi ? 'Đặt lại' : 'Reset',
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD4AF7A),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // SECTION 1: LOCATION TYPE
                    Text(
                      _isVi ? 'Loại địa điểm' : 'Location Type',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.4),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _popupSelectionField(
                      title: _isVi ? 'Loại địa điểm' : 'Location Type',
                      value: _selectedLocationKindLabel(_selectedLocationKind),
                      hint: _isVi
                          ? 'Chạm để chọn loại địa điểm'
                          : 'Tap to select location type',
                      onTap: () async {
                        final selected = await _showSingleSelectPopup(
                          title: _isVi ? 'Loại địa điểm' : 'Location Type',
                          options: _locationKindOptions
                              .map((option) => option['label']!)
                              .toList(),
                          selectedValue:
                              _selectedLocationKindLabel(_selectedLocationKind),
                        );
                        if (selected == null) return;
                        final selectedValue = _locationKindOptions.firstWhere(
                          (option) => option['label'] == selected,
                        )['value']!;
                        setSheetState(() {
                          _selectedLocationKind = selectedValue;
                          _selectedCategory = null;
                          _selectedTags.clear();
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // SECTION 2: CHOOSE CITY
                    Text(
                      _isVi ? 'Lọc theo Thành phố' : 'Filter by City',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.4),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _popupSelectionField(
                      title: _isVi ? 'Thành phố' : 'City',
                      value: _selectedCity != null
                          ? _translateProvince(_selectedCity!)
                          : (_isVi ? 'Tất cả thành phố' : 'All Cities'),
                      hint: _isVi
                          ? 'Chạm để chọn thành phố'
                          : 'Tap to select city',
                      onTap: () async {
                        final selected = await _showSingleSelectPopup(
                          title:
                              _isVi ? 'Lọc theo Thành phố' : 'Filter by City',
                          options: cities,
                          selectedValue: _selectedCity,
                          clearLabel: _isVi ? 'Tất cả thành phố' : 'All Cities',
                        );
                        setSheetState(() {
                          _selectedCity = selected;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    if (_selectedLocationKind != 'all') ...[
                      // SECTION 3: CATEGORY
                      Text(
                        _isVi ? 'Danh mục' : 'Category',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.4),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _choiceChip(
                              label: _isVi ? 'Tất cả' : 'All',
                              isSelected: _selectedCategory == null,
                              onTap: () {
                                setSheetState(() {
                                  _selectedCategory = null;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            ..._activeTagOptions.map((category) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _choiceChip(
                                  label: _getLocalizedDisplay(category),
                                  isSelected: _selectedCategory == category,
                                  onTap: () {
                                    setSheetState(() {
                                      _selectedCategory = category;
                                    });
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    if (_selectedLocationKind != 'all') ...[
                      // SECTION 4: TAGS
                      Text(
                        _isVi ? 'Tags' : 'Tags',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.4),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _popupSelectionField(
                        title: _isVi ? 'Tags' : 'Tags',
                        value: _tagsSummary(_selectedTags),
                        hint:
                            _isVi ? 'Chạm để chọn tags' : 'Tap to select tags',
                        onTap: () async {
                          final selected = await _showMultiSelectPopup(
                            title: _isVi ? 'Tags' : 'Tags',
                            options: _activeTagOptions,
                            selectedValues: _selectedTags,
                          );
                          if (selected == null) return;
                          setSheetState(() {
                            _selectedTags
                              ..clear()
                              ..addAll(selected);
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    // SECTION 5: SORT BY
                    Text(
                      _isVi ? 'Sắp xếp theo' : 'Sort by',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.4),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: sortOptions.map((opt) {
                        final isSelected = _sortBy == opt['field'];
                        return _choiceChip(
                          label: _isVi
                              ? opt['label']!
                              : (opt['field'] == 'rating'
                                  ? 'Rating'
                                  : (opt['field'] == 'reviewsCount'
                                      ? 'Reviews'
                                      : 'Name')),
                          isSelected: isSelected,
                          centerText: true,
                          onTap: () {
                            setSheetState(() {
                              _sortBy = opt['field']!;
                              _sortOrder = opt['order']!;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // SECTION 6: ORDER
                    Text(
                      _isVi ? 'Thứ tự' : 'Order',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.4),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _choiceChip(
                            label: _isVi ? 'Giảm dần' : 'Descending',
                            isSelected: _sortOrder == 'desc',
                            centerText: true,
                            onTap: () {
                              setSheetState(() {
                                _sortOrder = 'desc';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _choiceChip(
                            label: _isVi ? 'Tăng dần' : 'Ascending',
                            isSelected: _sortOrder == 'asc',
                            centerText: true,
                            onTap: () {
                              setSheetState(() {
                                _sortOrder = 'asc';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // SECTION 7: LIMIT
                    Text(
                      _isVi ? 'Số lượng' : 'Limit',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.4),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: limitOptions.map((limit) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _choiceChip(
                              label: '$limit',
                              isSelected: _filterLimit == limit,
                              centerText: true,
                              onTap: () {
                                setSheetState(() {
                                  _filterLimit = limit;
                                });
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // SECTION 8: SCORE
                    Text(
                      _isVi ? 'Điểm đánh giá' : 'Rating Score',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.4),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_scoreRange.start.toStringAsFixed(1)} - ${_scoreRange.end.toStringAsFixed(1)} ${_isVi ? 'sao' : 'stars'}',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.72),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    RangeSlider(
                      activeColor: const Color(0xFFD4AF7A),
                      inactiveColor: Colors.white.withOpacity(0.12),
                      min: 0,
                      max: 5,
                      divisions: 10,
                      values: _scoreRange,
                      onChanged: (value) {
                        setSheetState(() {
                          _scoreRange = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // SECTION 9: OPENING TIME
                    Text(
                      _isVi ? 'Thời gian mở cửa' : 'Opening Hours',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.4),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _filterValueButton(
                            icon: Icons.access_time_rounded,
                            label: _filterTime ??
                                (_isVi ? 'Giờ bất kỳ' : 'Anytime'),
                            onTap: () async {
                              final initial = _filterTime?.split(':');
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: initial != null &&
                                        initial.length == 2
                                    ? TimeOfDay(
                                        hour: int.tryParse(initial[0]) ?? 8,
                                        minute: int.tryParse(initial[1]) ?? 0,
                                      )
                                    : const TimeOfDay(hour: 8, minute: 0),
                              );
                              if (picked == null) return;
                              setSheetState(() {
                                _filterTime =
                                    '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                              });
                            },
                            onClear: _filterTime == null
                                ? null
                                : () {
                                    setSheetState(() {
                                      _filterTime = null;
                                    });
                                  },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _filterValueButton(
                            icon: Icons.calendar_today_rounded,
                            label: _filterDate ??
                                (_isVi ? 'Ngày bất kỳ' : 'Anyday'),
                            onTap: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: now,
                                firstDate: DateTime(now.year - 1),
                                lastDate: DateTime(now.year + 1),
                              );
                              if (picked == null) return;
                              setSheetState(() {
                                _filterDate =
                                    '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                              });
                            },
                            onClear: _filterDate == null
                                ? null
                                : () {
                                    setSheetState(() {
                                      _filterDate = null;
                                    });
                                  },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // SECTION 10: NEARBY / GPS
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.my_location_rounded,
                                    color: _nearbyEnabled
                                        ? const Color(0xFFD4AF7A)
                                        : Colors.white60,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _isVi
                                        ? 'Tìm kiếm xung quanh (GPS)'
                                        : 'Nearby Search (GPS)',
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              Switch.adaptive(
                                activeColor: const Color(0xFFD4AF7A),
                                activeTrackColor:
                                    const Color(0xFFD4AF7A).withOpacity(0.3),
                                value: _nearbyEnabled,
                                onChanged: (val) {
                                  setSheetState(() {
                                    _nearbyEnabled = val;
                                  });
                                },
                              ),
                            ],
                          ),
                          if (_nearbyEnabled) ...[
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  (_isVi ? 'Bán kính: ' : 'Radius: ') +
                                      '${_radius >= 1000 ? "${(_radius / 1000).toStringAsFixed(1)} km" : "${_radius.round()} m"}',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.7),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              activeColor: const Color(0xFFD4AF7A),
                              inactiveColor: Colors.white.withOpacity(0.12),
                              min: 1000.0,
                              max: 20000.0,
                              divisions: 19,
                              value: _radius,
                              onChanged: (val) {
                                setSheetState(() {
                                  _radius = val;
                                });
                              },
                              onChangeEnd: (val) {
                                setSheetState(() {
                                  _radius = val;
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF7A),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          setState(() {});
                          Navigator.pop(context);
                          _applyCurrentFilters();
                        },
                        child: Text(
                          _isVi ? 'Áp dụng' : 'Apply',
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _filterValueButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFD4AF7A), size: 17),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            if (onClear != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.white.withOpacity(0.65),
                  size: 16,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _choiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool centerText = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFD4AF7A)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFD4AF7A)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: isSelected && !centerText
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_rounded,
                      color: Colors.black, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ],
              )
            : Text(
                label,
                textAlign: centerText ? TextAlign.center : null,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.black : Colors.white70,
                ),
              ),
      ),
    );
  }

  Widget _popupSelectionField({
    required String title,
    required String value,
    required String hint,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF7A).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFFD4AF7A),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.45),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.expand_more_rounded,
              color: Colors.white.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    if (_isLoadingDestinations && _realDestinations.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F1E1B),
        body: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Header Shimmer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerWidget(
                          width: 140,
                          height: 24,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        const SizedBox(height: 8),
                        ShimmerWidget(
                          width: 80,
                          height: 14,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                    ShimmerWidget(
                      width: 46,
                      height: 46,
                      borderRadius: BorderRadius.circular(23),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Search Bar Shimmer
                ShimmerWidget(
                  width: double.infinity,
                  height: 54,
                  borderRadius: BorderRadius.circular(16),
                ),
                const SizedBox(height: 32),
                // Categories Shimmer
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: Row(
                    children: List.generate(
                        4,
                        (index) => Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: ShimmerWidget(
                                width: 90,
                                height: 36,
                                borderRadius: BorderRadius.circular(18),
                              ),
                            )),
                  ),
                ),
                const SizedBox(height: 32),
                // Large Card Shimmer
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2E2A).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: const Color(0xFFD4AF7A).withValues(alpha: 0.15),
                        width: 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Spacer(),
                          ShimmerWidget(
                            width: 220,
                            height: 28,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          const SizedBox(height: 12),
                          ShimmerWidget(
                            width: 130,
                            height: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Bottom indicators Shimmer
                Center(
                  child: ShimmerWidget(
                    width: 60,
                    height: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      );
    }

    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: const Color(0xFF0C1412),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Background images stretch full screen under the sidebar!
            _buildPreviousBackground(),
            _buildCurrentBackground(),
            _buildDarkOverlay(),

            // Foreground UI structure
            Row(
              children: [
                // Left sidebar navigation with BackdropFilter glass blur
                ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: _buildSidebar(),
                  ),
                ),

                // Right active tab content area
                Expanded(
                  child: _buildUIContent(size),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildPreviousBackground(),
          _buildCurrentBackground(),
          _buildDarkOverlay(),
          _buildUIContent(size),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: 24,
            right: 24,
            bottom: _navIndex == _tabProfile
                ? -100
                : MediaQuery.paddingOf(context).bottom + 20,
            child: _buildBottomNav(),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final isGuest = widget.authToken == null || widget.authToken!.isEmpty;
    final menuItems = [
      (Icons.home_rounded, AppLocalizations.of(context)!.explore),
      (Icons.search_rounded, AppLocalizations.of(context)!.search),
      (Icons.bookmark_rounded, AppLocalizations.of(context)!.saved),
      (Icons.explore_rounded, AppLocalizations.of(context)!.survey),
      (Icons.person_rounded, AppLocalizations.of(context)!.account),
    ];

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: const Color(0xFF070E0D).withOpacity(
            0.45), // Semi-transparent dark green/black background for glass effect
        border:
            const Border(right: BorderSide(color: Colors.white12, width: 1)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 36),
          // Logo header (horizontal Row for large compact logo)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
                  width: 64,
                  height: 64,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'TourXport',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFD4AF7A),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // User Profile Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  _buildHomeAvatar(size: 38, iconSize: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentUserName,
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
                          _isVi ? 'Thành viên' : 'Member',
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
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Navigation Links
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: menuItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final item = menuItems[i];
                final isActive = _navIndex == i;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      if (i == _tabSurvey) {
                        await _openSurveyForCurrentLayout();
                      } else {
                        _showMainTab(i);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    hoverColor: Colors.white.withOpacity(0.05),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF2D6A4F).withOpacity(0.25)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive
                              ? const Color(0xFFD4AF7A).withOpacity(
                                  0.65) // Subtle glowing gold border for active item
                              : Colors.transparent,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.$1,
                            color: isActive
                                ? const Color(0xFFD4AF7A)
                                : Colors.white.withOpacity(
                                    0.65), // Crisp contrast for inactive icons
                            size: 22,
                          ),
                          const SizedBox(width: 14),
                          Text(
                            item.$2,
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 14,
                              fontWeight:
                                  isActive ? FontWeight.bold : FontWeight.w600,
                              color: isActive
                                  ? Colors.white
                                  : Colors.white.withOpacity(
                                      0.65), // Highly legible inactive text
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Logout button at bottom
          Padding(
            padding: const EdgeInsets.all(20),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _logout,
                borderRadius: BorderRadius.circular(16),
                hoverColor: isGuest
                    ? const Color(0xFFD4AF7A).withOpacity(0.1)
                    : const Color(0xFFE74C3C).withOpacity(0.1),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(
                        isGuest ? Icons.login_rounded : Icons.logout_rounded,
                        color: isGuest
                            ? const Color(0xFFD4AF7A)
                            : const Color(0xFFE74C3C),
                        size: 22,
                      ),
                      const SizedBox(width: 14),
                      Text(
                        isGuest
                            ? (_isVi ? 'Tài khoản' : 'Account')
                            : (_isVi ? 'Đăng xuất' : 'Log Out'),
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isGuest
                              ? const Color(0xFFD4AF7A)
                              : const Color(0xFFE74C3C),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousBackground() {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final isSurveyStyle = _navIndex == _tabSearch ||
        _navIndex == _tabSaved ||
        _navIndex == _tabSurvey ||
        _navIndex == _tabProfile;
    final blurVal = isSurveyStyle ? 10.0 : (isDesktop ? 0.8 : 5.0);
    final bgPath =
        isSurveyStyle ? 'assets/images/login_bg.jpg' : _previousBgPath;

    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Destination.buildImage(bgPath),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurVal, sigmaY: blurVal),
            child: Container(color: Colors.transparent),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentBackground() {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final isSurveyStyle = _navIndex == _tabSearch ||
        _navIndex == _tabSaved ||
        _navIndex == _tabSurvey ||
        _navIndex == _tabProfile;
    final blurVal = isSurveyStyle ? 10.0 : (isDesktop ? 0.8 : 5.0);
    final bgPath =
        isSurveyStyle ? 'assets/images/login_bg.jpg' : _currentBgPath;

    return Positioned.fill(
      child: AnimBuilder(
        animation: _bgFade,
        builder: (context, child) => Opacity(
          opacity: _bgFade.value,
          child: child,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Destination.buildImage(bgPath),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurVal, sigmaY: blurVal),
              child: Container(color: Colors.transparent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDarkOverlay() {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final isSurveyStyle = _navIndex == _tabSearch ||
        _navIndex == _tabSaved ||
        _navIndex == _tabSurvey ||
        _navIndex == _tabProfile;

    if (isSurveyStyle) {
      return Positioned.fill(
        child: Container(
          color: Colors.black.withOpacity(0.6),
        ),
      );
    }

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.3, 0.7, 1.0],
            colors: [
              Colors.black.withOpacity(isDesktop ? 0.15 : 0.33),
              Colors.black.withOpacity(isDesktop ? 0.05 : 0.06),
              Colors.black.withOpacity(isDesktop ? 0.20 : 0.18),
              isDesktop ? const Color(0xFF0C1412) : const Color(0xBB000000),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUIContent(Size size) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final content = IndexedStack(
      index: _navIndex,
      children: [
        _buildHomeTabBody(size),
        _buildSearchTabBody(size),
        SavedPlacesSection(
          authToken: widget.authToken,
          userName: _currentUserName,
          avatarUrl: _currentAvatarUrl,
          initialTabIndex: _savedPlacesInitialTab,
          entranceAnimation: _cardEntrance,
          savedDestinations: _savedDestinations,
          updatingSavedNames: _updatingSavedNames,
          isLoading: _isLoadingSavedPlaces,
          onBack: () {
            _showMainTab(_tabExplore);
          },
          onOpenDetail: _openPlaceDetail,
          onToggleSaved: _toggleSaved,
          isGuest: widget.authToken == null || widget.authToken!.isEmpty,
          onNavigateMain: _handleMainNavigationResult,
        ),
        isDesktop
            ? (_isSurveyAiReady
                ? SurveyScreen(
                    authToken: widget.authToken,
                    userName: _currentUserName,
                    avatarUrl: _currentAvatarUrl,
                    embedded: true,
                    onNavigate: _handleSurveyResult,
                  )
                : _SurveyAiWarmupView(isVi: _isVi, embedded: true))
            : const SizedBox.shrink(),
        ProfileSection(
          entranceAnimation: _cardEntrance,
          userData: _userData,
          isLoading: _isLoadingProfile,
          onBack: () {
            _showMainTab(_tabExplore);
          },
          onLogout: _logout,
          onUpdateAvatar: () => _showEditImageDialog(true),
          onUpdateCover: () => _showEditImageDialog(false),
          onEditPhone: _editPhone,
          onEditSecurity: () => _editSecurity(),
          onEditNotifications: _showNotificationCenter,
          onEditLanguage: _editLanguage,
          onEditHelpSupport: _editHelpSupport,
        ),
      ],
    );

    if (isDesktop) {
      return content;
    }

    return SafeArea(
      bottom: false,
      child: content,
    );
  }

  // === WEB/DESKTOP CUSTOM UTILITIES ===

  int _findFirstIndexForCategory(String category) {
    final list = _exploreDestinations;
    for (int i = 0; i < list.length; i++) {
      final d = list[i];
      final prov = d.province.toLowerCase();
      final name = d.name.toLowerCase();
      if (category == 'vịnh biển') {
        if (prov.contains('quảng ninh') ||
            prov.contains('khánh hòa') ||
            prov.contains('vũng tàu') ||
            prov.contains('kiên giang') ||
            name.contains('vịnh') ||
            name.contains('biển') ||
            name.contains('đảo')) {
          return i;
        }
      } else if (category == 'núi rừng') {
        if (prov.contains('lào cai') ||
            prov.contains('quảng bình') ||
            prov.contains('sơn la') ||
            prov.contains('hà giang') ||
            name.contains('núi') ||
            name.contains('động') ||
            name.contains('hang') ||
            name.contains('phong nha')) {
          return i;
        }
      } else if (category == 'di sản') {
        if (prov.contains('quảng nam') ||
            prov.contains('huế') ||
            prov.contains('hà nội') ||
            prov.contains('ninh bình') ||
            name.contains('cổ') ||
            name.contains('di tích') ||
            name.contains('tự') ||
            name.contains('lăng') ||
            name.contains('chùa')) {
          return i;
        }
      } else if (category == 'đô thị') {
        if (prov.contains('chí minh') ||
            prov.contains('đà nẵng') ||
            prov.contains('hà nội') ||
            name.contains('tháp') ||
            name.contains('cầu') ||
            name.contains('nhà hát')) {
          return i;
        }
      }
    }
    return -1;
  }

  String _getBriefDescription(Destination dest) {
    final name = dest.name.toLowerCase();
    if (!_isVi) {
      if (name.contains('hạ long')) {
        return 'Ha Long Bay is a UNESCO World Heritage site, famous for its thousands of spectacular limestone karsts and serene emerald waters.';
      } else if (name.contains('hội an')) {
        return 'Hoi An Ancient Town is an exceptionally well-preserved trading port, glowing with colorful lanterns and nostalgic mossy roofs by the Thu Bon River.';
      } else if (name.contains('đà nẵng') ||
          name.contains('mỹ khê') ||
          name.contains('bà nà')) {
        return 'Da Nang is Vietnam\'s most liveable coastal city, blending iconic bridges, fine white sands, and the mist-shrouded Ba Na Hills year-round.';
      } else if (name.contains('phong nha') || name.contains('kẻ bàng')) {
        return 'Phong Nha - Ke Bang is known as the cave kingdom of the world, housing millions-of-years-old stalactites beneath lush primary rainforests.';
      } else if (name.contains('hồ chí minh') ||
          name.contains('sài gòn') ||
          name.contains('củ chi')) {
        return 'Ho Chi Minh City is a dynamic metropolis where rich history converges with modern life, soaring skyscrapers, and unique cultural heritage.';
      } else if (name.contains('hà nội') ||
          name.contains('hoàn kiếm') ||
          name.contains('lăng chủ tịch')) {
        return 'The capital Hanoi boasts a thousand years of history, peaceful with Sword Lake, quiet old quarters, elegant cuisine, and timeless historical sites.';
      } else if (name.contains('huế') || name.contains('thiên mụ')) {
        return 'Hue is dreamlike and tranquil, with its ancient Imperial City and majestic royal tombs reflecting upon the poetic Perfume River.';
      } else if (name.contains('phú quốc') || name.contains('kiên giang')) {
        return 'Phú Quốc Pearl Island boasts some of the most pristine beaches on earth, vibrant coral reefs, and world-class resorts bathed in spectacular sunsets.';
      } else if (name.contains('cát bà') || name.contains('bạch long vĩ')) {
        return 'Cat Ba is the pearl island of the North, famous for its peaceful bays interspersed with majestic limestone mountains and rich tropical rainforests.';
      }
      return '${dest.name} is located in ${_translateProvince(dest.province)}, an ideal destination with beautiful scenery and an attractive price of ${dest.price} for your journey.';
    }

    if (name.contains('hạ long')) {
      return 'Vịnh Hạ Long là di sản thiên nhiên thế giới được UNESCO công nhận, nổi tiếng với hàng nghìn hòn đảo đá vôi kỳ vĩ và làn nước xanh lục bảo thanh bình.';
    } else if (name.contains('hội an')) {
      return 'Phố cổ Hội An là thương cảng cổ xưa được bảo tồn nguyên vẹn, lung linh với ánh đèn lồng rực rỡ và những mái nhà rêu phong hoài cổ bên dòng sông Thu Bồn.';
    } else if (name.contains('đà nẵng') ||
        name.contains('mỹ khê') ||
        name.contains('bà nà')) {
      return 'Đà Nẵng là thành phố biển đáng sống nhất Việt Nam, nơi giao thoa tuyệt vời giữa những cây cầu biểu tượng, bãi cát trắng mịn và đỉnh Bà Nà quanh năm sương mờ.';
    } else if (name.contains('phong nha') || name.contains('kẻ bàng')) {
      return 'Phong Nha - Kẻ Bàng được mệnh danh là vương quốc hang động thế giới, ẩn chứa hệ thống thạch nhũ tráng lệ triệu năm tuổi sâu bên dưới cánh rừng nguyên sinh xanh mướt.';
    } else if (name.contains('hồ chí minh') ||
        name.contains('sài gòn') ||
        name.contains('củ chi')) {
      return 'Thành phố Hồ Chí Minh năng động và sôi động bậc nhất, nơi lịch sử hào hùng hội tụ với nhịp sống hiện đại, tòa tháp chọc trời và các di tích văn hóa độc đáo.';
    } else if (name.contains('hà nội') ||
        name.contains('hoàn kiếm') ||
        name.contains('lăng chủ tịch')) {
      return 'Thủ đô Hà Nội nghìn năm văn hiến, bình yên với Hồ Gươm liễu rủ, phố cổ trầm mặc, ẩm thực thanh lịch và những di tích lịch sử in đậm dấu ấn thời gian.';
    } else if (name.contains('huế') || name.contains('thiên mụ')) {
      return 'Thừa Thiên Huế mang vẻ đẹp mộng mơ, tĩnh lặng với Đại Nội cổ kính, hệ thống lăng tẩm hoàng gia uy nghiêm soi bóng bên dòng sông Hương thơ mộng.';
    } else if (name.contains('phú quốc') || name.contains('kiên giang')) {
      return 'Đảo ngọc Phú Quốc sở hữu những bãi biển hoang sơ đẹp nhất hành tinh, rạn san hô lộng lẫy và những khu nghỉ dưỡng đẳng cấp thế giới chìm trong hoàng hôn rực rỡ.';
    } else if (name.contains('cát bà') || name.contains('bạch long vĩ')) {
      return 'Cát Bà là hòn đảo ngọc phía Bắc, nổi tiếng với những vịnh biển yên bình xen kẽ dãy núi đá vôi kỳ vĩ và những cánh rừng mưa nhiệt đới trù phú.';
    }
    return '${dest.name} tọa lạc tại ${dest.province}, là điểm đến lý tưởng với phong cảnh hữu tình, mức giá ${dest.price} cực kỳ hấp dẫn cho hành trình khám phá của bạn.';
  }

  void _selectDestination(int index) {
    _onPageChanged(index);
    if (_pageController.hasClients) {
      final list = _exploreDestinations;
      if (list.isNotEmpty) {
        final currentPage = _pageController.page?.round() ?? 1000;
        final currentListIndex = currentPage % list.length;
        final offset = index - currentListIndex;
        _pageController.jumpToPage(currentPage + offset);
      }
    }
  }

  // === END WEB/DESKTOP CUSTOM UTILITIES ===

  Widget _buildHomeTabBody(Size size) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (isDesktop) {
      final destinations = _exploreDestinations;
      if (destinations.isEmpty) {
        return Center(
          child: Text(
            _isVi
                ? 'Chưa có địa điểm nào phù hợp.'
                : 'No matching locations found.',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        );
      }

      if (_currentIndex >= destinations.length) {
        _currentIndex = 0;
      }
      final activeDest = destinations[_currentIndex];
      final categoryList = ['VỊNH BIỂN', 'NÚI RỪNG', 'DI SẢN', 'ĐÔ THỊ'];

      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HERO SECTION
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
              constraints: const BoxConstraints(minHeight: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 1. Header Navigation Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFE74C3C),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'TRAVEL',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 3.0,
                              shadows: _heroTextShadows,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: List.generate(categoryList.length, (idx) {
                          final cat = categoryList[idx];

                          bool isThisCatActive = false;
                          final prov = destinations[_currentIndex]
                              .province
                              .toLowerCase();
                          final name =
                              destinations[_currentIndex].name.toLowerCase();
                          if (cat == 'VỊNH BIỂN') {
                            isThisCatActive = prov.contains('quảng ninh') ||
                                prov.contains('khánh hòa') ||
                                prov.contains('vũng tàu') ||
                                prov.contains('kiên giang') ||
                                name.contains('vịnh') ||
                                name.contains('biển') ||
                                name.contains('đảo');
                          } else if (cat == 'NÚI RỪNG') {
                            isThisCatActive = prov.contains('lào cai') ||
                                prov.contains('quảng bình') ||
                                prov.contains('sơn la') ||
                                prov.contains('hà giang') ||
                                name.contains('núi') ||
                                name.contains('động') ||
                                name.contains('hang') ||
                                name.contains('phong nha');
                          } else if (cat == 'DI SẢN') {
                            isThisCatActive = prov.contains('quảng nam') ||
                                prov.contains('huế') ||
                                prov.contains('hà nội') ||
                                prov.contains('ninh bình') ||
                                name.contains('cổ') ||
                                name.contains('di tích') ||
                                name.contains('tự') ||
                                name.contains('lăng') ||
                                name.contains('chùa');
                          } else if (cat == 'ĐÔ THỊ') {
                            isThisCatActive = prov.contains('chí minh') ||
                                prov.contains('đà nẵng') ||
                                prov.contains('hà nội') ||
                                name.contains('tháp') ||
                                name.contains('cầu') ||
                                name.contains('nhà hát');
                          }

                          return WebHoverable(
                            onTap: () {
                              final firstIdx =
                                  _findFirstIndexForCategory(cat.toLowerCase());
                              if (firstIdx != -1) {
                                _selectDestination(firstIdx);
                              } else {
                                _showMessage(
                                    'Không có địa điểm thuộc danh mục này hiện tại');
                              }
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _translateCategoryHeader(cat),
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 13,
                                      fontWeight: isThisCatActive
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isThisCatActive
                                          ? Colors.white
                                          : Colors.white60,
                                      shadows: _heroTextShadows,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    height: 1.5,
                                    width: isThisCatActive ? 30 : 0,
                                    color: const Color(0xFFD4AF7A),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(width: 24),
                      GestureDetector(
                        onTap: _showNotificationCenter,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white12, width: 1),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(Icons.notifications_none_rounded,
                                  color: Colors.white, size: 20),
                              if (_notifications.any((n) => !n.isRead))
                                Positioned(
                                  top: -1,
                                  right: -1,
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE74C3C),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),

                  // 2. Central Cinematic Title Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'VISIT',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 44,
                                fontWeight: FontWeight.w400,
                                color: Colors.white70,
                                letterSpacing: 6.0,
                                shadows: _heroTextShadows,
                              ),
                            ),
                            Text(
                              activeDest.name.toUpperCase(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 68,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.0,
                                letterSpacing: -1.0,
                                shadows: _heroTitleShadows,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 40),
                      // Left/Right Navigation controls for desktop view (unlimited browsing)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Left Arrow Button
                          WebHoverable(
                            onTap: () {
                              final prevIdx =
                                  (_currentIndex - 1 + destinations.length) %
                                      destinations.length;
                              _selectDestination(prevIdx);
                            },
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white30, width: 1.5),
                                color: Colors.white.withOpacity(0.05),
                              ),
                              child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white,
                                  size: 18),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Dynamic Page Indicator showing current out of total destinations
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                (_currentIndex + 1).toString().padLeft(2, '0'),
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  shadows: _heroTextShadows,
                                ),
                              ),
                              Container(
                                width: 20,
                                height: 1.5,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                color: const Color(0xFFD4AF7A),
                              ),
                              Text(
                                destinations.length.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.4),
                                  shadows: _heroTextShadows,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          // Right Arrow Button
                          WebHoverable(
                            onTap: () {
                              final nextIdx =
                                  (_currentIndex + 1) % destinations.length;
                              _selectDestination(nextIdx);
                            },
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white30, width: 1.5),
                                color: Colors.white.withOpacity(0.05),
                              ),
                              child: const Icon(Icons.arrow_forward_ios_rounded,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),

                  // 3. Bottom 3-column description row
                  Builder(builder: (ctx) {
                    final prevIdx = (_currentIndex - 1 + destinations.length) %
                        destinations.length;
                    final nextIdx = (_currentIndex + 1) % destinations.length;
                    final nextNextIdx =
                        (_currentIndex + 2) % destinations.length;

                    final prevDest = destinations[prevIdx];
                    final nextDest = destinations[nextIdx];
                    final nextNextDest = destinations[nextNextIdx];

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getBriefDescription(activeDest),
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.7),
                                    height: 1.6,
                                    shadows: _heroTextShadows,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    WebHoverable(
                                      onTap: () =>
                                          _openPlaceDetail(activeDest, ctx),
                                      child: const Text(
                                        'XEM CHI TIẾT >>',
                                        style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFFD4AF7A),
                                          letterSpacing: 1.0,
                                          shadows: _heroTextShadows,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Builder(builder: (buttonCtx) {
                                      final isSaved =
                                          _savedNames.contains(activeDest.name);
                                      final isBusy = _updatingSavedNames
                                          .contains(activeDest.name);

                                      return WebHoverable(
                                        onTap: isBusy
                                            ? null
                                            : () async {
                                                await _toggleSaved(activeDest);
                                                setState(() {});
                                              },
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isSaved
                                                  ? Icons.bookmark_rounded
                                                  : Icons
                                                      .bookmark_border_rounded,
                                              color: isSaved
                                                  ? const Color(0xFFD4AF7A)
                                                  : Colors.white70,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              isSaved
                                                  ? 'ĐÃ LƯU'
                                                  : 'LƯU ĐỊA ĐIỂM',
                                              style: TextStyle(
                                                fontFamily: 'Montserrat',
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                color: isSaved
                                                    ? const Color(0xFFD4AF7A)
                                                    : Colors.white70,
                                                letterSpacing: 1.0,
                                                shadows: _heroTextShadows,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nextDest.name,
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: _heroTextShadows,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getBriefDescription(nextDest),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 11,
                                    color: Colors.white.withOpacity(0.45),
                                    height: 1.5,
                                    shadows: _heroTextShadows,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                WebHoverable(
                                  onTap: () => _selectDestination(nextIdx),
                                  child: const Text(
                                    'XEM ĐIỂM ĐẾN >>',
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white54,
                                      shadows: _heroTextShadows,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nextNextDest.name,
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: _heroTextShadows,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getBriefDescription(nextNextDest),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.45),
                                  height: 1.5,
                                  shadows: _heroTextShadows,
                                ),
                              ),
                              const SizedBox(height: 10),
                              WebHoverable(
                                onTap: () => _selectDestination(nextNextIdx),
                                child: const Text(
                                  'XEM ĐIỂM ĐẾN >>',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white54,
                                    shadows: _heroTextShadows,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),

            // TRANSITION & SOLID BACKGROUND RECOMMENDATIONS SECTION
            Container(
              color: const Color(0xFF0C1412),
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(50, 58, 50, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Khám phá Việt Nam qua dữ liệu thực tế',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.58),
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildExploreStats(),
                  const SizedBox(height: 90),
                  const Text(
                    'confusion? these recommendations',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFFD4AF7A),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'destination recommendations',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 24,
                    runSpacing: 24,
                    children:
                        List.generate(destinations.length.clamp(0, 4), (i) {
                      final dest = destinations[i];
                      final rankName =
                          '${i + 1}${i == 0 ? "st" : i == 1 ? "nd" : i == 2 ? "rd" : "th"} place';

                      return WebHoverable(
                        onTap: () => _openPlaceDetail(dest, context),
                        child: Container(
                          width: 220,
                          height: 380,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Destination.buildImage(dest.imagePath,
                                    fit: BoxFit.cover),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      stops: const [0.4, 1.0],
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.9),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 20,
                                  bottom: 44,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: dest.type == 'Nhà hàng'
                                          ? const Color(0xFFE67E22)
                                              .withValues(alpha: 0.85)
                                          : dest.type == 'Khách sạn'
                                              ? const Color(0xFF3498DB)
                                                  .withValues(alpha: 0.85)
                                              : const Color(0xFFB5956A)
                                                  .withValues(alpha: 0.85),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      dest.type,
                                      style: const TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: _heroTextShadows,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 20,
                                  bottom: 20,
                                  right: 20,
                                  child: Text(
                                    dest.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: _heroTextShadows,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // FOOTER / BRANDING BANNER SECTION
            Container(
              color: const Color(0xFF0C1412),
              width: double.infinity,
              padding: const EdgeInsets.only(
                  left: 50, right: 50, bottom: 80, top: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TRAVEL AND ENJOY\nYOUR HOLIDAY',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.15,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 36),
                        WebHoverable(
                          onTap: () async {
                            await _openSurveyForCurrentLayout();
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 1.5),
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text(
                                'choose your fun holiday',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'TourXport mang đến giải pháp lập kế hoạch du lịch thông minh và tự động hóa toàn diện, giúp bạn dễ dàng cá nhân hóa hành trình khám phá dải đất hình chữ S. Hãy bắt đầu kỳ nghỉ trong mơ cùng chúng tôi ngay hôm nay.',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.55),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 60),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                width: 150,
                                height: 100,
                                child: Destination.buildImage(
                                  destinations[0].imagePath,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                width: 150,
                                height: 100,
                                child: Destination.buildImage(
                                  destinations[destinations.length > 1 ? 1 : 0]
                                      .imagePath,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 56),
                        WebHoverable(
                          onTap: () {
                            _showMessage(
                                'Chào mừng bạn đến với kênh Instagram TourXport!');
                          },
                          child: Text(
                            'http://instagram.com/tourxport_',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.35),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget content = Column(
      key: const ValueKey<String>('home_tab'),
      children: [
        if (!isDesktop) _buildTopBar(),
        const SizedBox(height: 8),
        _buildTitle(),
        const SizedBox(height: 12),
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  _buildRegionTabs(),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _buildCardCarousel(size),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    return content;
  }

  Widget _buildSearchTabBody(Size size) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    final content = Column(
      key: const ValueKey<String>('search_tab'),
      children: [
        if (!isDesktop) _buildTopBar(),
        SizedBox(height: isDesktop ? 42 : 8),
        if (isDesktop)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Tìm kiếm địa điểm',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _showNotificationCenter,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white12, width: 1),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.notifications_none_rounded,
                            color: Colors.white, size: 22),
                        if (_notifications.any((n) => !n.isRead))
                          Positioned(
                            top: -1,
                            right: -1,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE74C3C),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tìm kiếm địa điểm',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2,
                  shadows: const [
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
        SizedBox(height: isDesktop ? 22 : 12),
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  _buildRegionTabs(),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _buildSearchResultsGrid(),
                  ),
                  SizedBox(height: isDesktop ? 24 : 16),
                ],
              ),
              if (_searchFocusNode.hasFocus)
                Positioned(
                  top: 60,
                  left: isDesktop ? 26 : 0,
                  right: isDesktop ? 26 : 0,
                  child: _buildSuggestionsDropdown(),
                ),
            ],
          ),
        ),
      ],
    );

    if (isDesktop) {
      return SafeArea(
        bottom: false,
        child: content,
      );
    }

    return content;
  }

  Widget _buildExploreStats() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 780),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Expanded(
            child: _ExploreStatItem(
              value: '18.627',
              label: 'ĐIỂM ĂN UỐNG',
            ),
          ),
          Expanded(
            child: _ExploreStatItem(
              value: '2.932',
              label: 'ĐỊA ĐIỂM DU LỊCH',
            ),
          ),
          Expanded(
            child: _ExploreStatItem(
              value: '612',
              label: 'CHỖ Ở',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    final isGuest = widget.authToken == null || widget.authToken!.isEmpty;
    return FadeTransition(
      opacity: _cardEntrance,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            _buildHomeAvatar(size: 44, iconSize: 24),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppLocalizations.of(context)!.welcome_back}\n$_currentUserName!',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            WeatherWidget(
              lat: _gpsLat,
              lon: _gpsLon,
              label: _hasGps ? null : 'Hà Nội',
              compact: true,
            ),
            const Spacer(),
            GestureDetector(
              onTap: _showNotificationCenter,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_none_rounded,
                        color: Colors.white, size: 24),
                    if (_notifications.any((n) => !n.isRead))
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE74C3C),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    const title = 'Trải nghiệm chuyến đi\ncùng TourXport';

    return FadeTransition(
      opacity: _cardEntrance,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(_cardEntrance),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Chào mừng đến với TourXport',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 30,
                fontWeight: FontWeight.w400,
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

  List<Destination> get _suggestions {
    final query = _searchQuery.trim().toLowerCase();
    final pool = _allDatabaseDestinations.isNotEmpty
        ? _allDatabaseDestinations
        : (_realDestinations.isNotEmpty
            ? _realDestinations
            : sampleDestinations);

    if (query.isEmpty) {
      return pool.take(3).toList();
    }
    if (_searchSuggestions.isNotEmpty) {
      return _searchSuggestions;
    }
    return pool
        .where((d) {
          return d.name.toLowerCase().contains(query) ||
              d.province.toLowerCase().contains(query);
        })
        .take(5)
        .toList();
  }

  Widget _buildSuggestionsDropdown() {
    final list = _suggestions;
    if (list.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xEE11221D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 25,
            spreadRadius: 2,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: Colors.white.withOpacity(0.08),
            indent: 16,
            endIndent: 16,
          ),
          itemBuilder: (context, i) {
            final dest = list[i];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _searchQuery = dest.name;
                    _searchController.text = dest.name;
                    _searchResults = [dest];
                    _currentIndex = 0;
                    _currentBgPath = dest.bgBlurPath;
                    _previousBgPath = dest.bgBlurPath;
                  });
                  _searchFocusNode.unfocus();
                  _resetCarouselPosition(useSearchResults: true);
                },
                hoverColor: Colors.white.withOpacity(0.05),
                splashColor: const Color(0xFFB5956A).withOpacity(0.2),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: Destination.buildImage(dest.imagePath,
                              fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              dest.name,
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dest.province,
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.north_west_rounded,
                        color: Colors.white.withOpacity(0.35),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return FadeTransition(
      opacity: _cardEntrance,
      child: SlideTransition(
        position: _searchBarSlide,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 50 : 24,
            vertical: 8,
          ),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.48),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withOpacity(0.22)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(
                  Icons.search_rounded,
                  color: Colors.white.withOpacity(0.7),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    key: const ValueKey<String>('search_text_field'),
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.search_hint,
                      hintStyle: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.4),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 2),
                      isDense: true,
                    ),
                    cursorColor: const Color(0xFFB5956A),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withOpacity(0.5),
                      size: 20,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                    tooltip: 'Xoá tìm kiếm',
                    splashRadius: 18,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                IconButton(
                  icon: Icon(
                    Icons.mic_rounded,
                    color: Colors.white.withOpacity(0.7),
                    size: 22,
                  ),
                  onPressed: _showVoiceSearchDialog,
                  tooltip: 'Tìm kiếm bằng giọng nói',
                  splashRadius: 20,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: Colors.white.withOpacity(0.15),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                ),
                IconButton(
                  icon: Icon(
                    Icons.tune_rounded,
                    color: Colors.white.withOpacity(0.7),
                    size: 21,
                  ),
                  onPressed: () {
                    _openSearchToolsSheet();
                  },
                  tooltip: 'Bộ lọc nâng cao',
                  splashRadius: 20,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.only(left: 8, right: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegionTabs() {
    final regions = vietnameseProvinces;
    return FadeTransition(
      opacity: _cardEntrance,
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: regions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, i) {
            final isSelected = _selectedCity == regions[i];
            return GestureDetector(
              onTap: () => _selectCity(regions[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color:
                      isSelected ? Colors.white : Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  _translateProvince(regions[i]),
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? Colors.black : Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchResultsGrid() {
    final destinations = _searchDestinations;
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (destinations.isEmpty) {
      return Center(
        child: Text(
          _isVi ? 'Chưa có địa điểm phù hợp.' : 'No matching locations found.',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 15,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _cardEntrance,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minCardWidth = isDesktop ? 220.0 : 165.0;
          final maxColumns = isDesktop ? 5 : 2;
          final columns = (constraints.maxWidth / minCardWidth)
              .floor()
              .clamp(1, maxColumns)
              .toInt();
          final horizontalPadding = isDesktop ? 50.0 : 24.0;
          final cardHeight = isDesktop ? 226.0 : 214.0;
          final footerBottomPadding = isDesktop ? 6.0 : 88.0;

          return Column(
            children: [
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    2,
                    horizontalPadding,
                    18,
                  ),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: isDesktop ? 16 : 12,
                    mainAxisSpacing: isDesktop ? 16 : 12,
                    mainAxisExtent: cardHeight,
                  ),
                  itemCount: destinations.length,
                  itemBuilder: (context, index) {
                    final dest = destinations[index];
                    return _buildCompactSearchCard(dest);
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  footerBottomPadding,
                ),
                child: _buildSearchGridPageControls(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCompactSearchCard(Destination dest) {
    final isSaved = _savedNames.contains(dest.name);
    final isBusy = _updatingSavedNames.contains(dest.name);

    return Builder(
      builder: (cardContext) {
        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _openPlaceDetail(dest, cardContext),
            borderRadius: BorderRadius.circular(18),
            hoverColor: Colors.white.withOpacity(0.05),
            splashColor: const Color(0xFFD4AF7A).withOpacity(0.12),
            highlightColor: Colors.white.withOpacity(0.04),
            child: Ink(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.32),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.24),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Destination.buildImage(
                            dest.imagePath,
                            fit: BoxFit.cover,
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.08),
                                  Colors.black.withOpacity(0.58),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 10,
                            top: 10,
                            child: _buildCompactTypeBadge(dest.type),
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: GestureDetector(
                              onTap: isBusy ? null : () => _toggleSaved(dest),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.38),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.16),
                                  ),
                                ),
                                child: isBusy
                                    ? const Padding(
                                        padding: EdgeInsets.all(8),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        isSaved
                                            ? Icons.bookmark_rounded
                                            : Icons.bookmark_border_rounded,
                                        color: isSaved
                                            ? const Color(0xFFD4AF7A)
                                            : Colors.white,
                                        size: 18,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dest.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              const Icon(
                                Icons.place_rounded,
                                color: Color(0xFFD4AF7A),
                                size: 15,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  dest.province,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.68),
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white70,
                                size: 16,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactTypeBadge(String type) {
    final color = type == 'Nhà hàng'
        ? const Color(0xFFE67E22)
        : type == 'Khách sạn'
            ? const Color(0xFF3498DB)
            : const Color(0xFFB5956A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        type,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1.0,
        ),
      ),
    );
  }

  Widget _buildSearchGridPageControls() {
    final totalPages = _searchTotalPages <= 0 ? 1 : _searchTotalPages;
    final currentPage = _searchBackendPage.clamp(1, totalPages).toInt();
    if (totalPages <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSearchGridPageButton(
          icon: Icons.chevron_left_rounded,
          enabled: currentPage > 1,
          onTap: () {
            _loadCarouselBackendPage(
              currentPage - 1,
              useSearchResults: true,
            );
          },
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.34),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.16)),
          ),
          child: Text(
            '$currentPage/$totalPages',
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        _buildSearchGridPageButton(
          icon: Icons.chevron_right_rounded,
          enabled: currentPage < totalPages,
          onTap: () {
            _loadCarouselBackendPage(
              currentPage + 1,
              useSearchResults: true,
            );
          },
        ),
      ],
    );
  }

  Widget _buildSearchGridPageButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(enabled ? 0.34 : 0.16),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.14)),
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white : Colors.white.withOpacity(0.32),
          size: 22,
        ),
      ),
    );
  }

  Widget _buildCardCarousel(Size size, {bool useSearchResults = false}) {
    final destinations =
        useSearchResults ? _searchDestinations : _exploreDestinations;
    final controller =
        useSearchResults ? _searchPageController : _pageController;
    if (destinations.isEmpty) {
      return Center(
        child: Text(
          _isVi
              ? 'Chưa có địa điểm nào được thả tim.'
              : 'No locations favorited yet.',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 15,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      );
    }

    final showInfinite = destinations.length > 3;

    return FadeTransition(
      opacity: _cardEntrance,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(_cardEntrance),
        child: Stack(
          children: [
            PageView.builder(
              controller: controller,
              itemCount: showInfinite ? 100000 : destinations.length,
              onPageChanged: (index) {
                final listIndex = destinations.isEmpty
                    ? 0
                    : (showInfinite ? (index % destinations.length) : index);
                _onPageChanged(listIndex, useSearchResults: useSearchResults);
                if (!useSearchResults) {
                  _startAutoPlay();
                }
              },
              itemBuilder: (context, index) {
                if (destinations.isEmpty) return const SizedBox.shrink();
                final listIndex =
                    showInfinite ? (index % destinations.length) : index;
                return AnimBuilder(
                  animation: controller,
                  builder: (context, child) {
                    double page =
                        controller.hasClients && controller.page != null
                            ? controller.page!
                            : index.toDouble();
                    final diff = (page - index).abs();
                    final scale = (1 - diff * 0.08).clamp(0.0, 1.0);
                    final verticalOffset = diff * 20.0;
                    final opacity = (1 - diff * 0.6).clamp(0.4, 1.0);

                    return Transform.translate(
                      offset: Offset(0, verticalOffset),
                      child: Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: opacity,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: _buildDestinationCard(
                    destinations[listIndex],
                    heroPrefix:
                        useSearchResults ? 'search_card_hero' : 'card_hero',
                  ),
                );
              },
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 18,
              child: Center(
                child: _buildCarouselPageIndicator(
                  useSearchResults: useSearchResults,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselPageIndicator({required bool useSearchResults}) {
    final total = _carouselTotalCount(useSearchResults: useSearchResults);
    if (total <= 1) return const SizedBox.shrink();

    final current = _carouselGlobalIndex(useSearchResults: useSearchResults);
    final canGoBack = current > 1;
    final canGoForward = current < total;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.34),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCarouselPageButton(
                icon: Icons.chevron_left_rounded,
                enabled: canGoBack,
                onTap: () {
                  _goToCarouselPage(
                    -1,
                    useSearchResults: useSearchResults,
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '$current/$total',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
              ),
              _buildCarouselPageButton(
                icon: Icons.chevron_right_rounded,
                enabled: canGoForward,
                onTap: () {
                  _goToCarouselPage(
                    1,
                    useSearchResults: useSearchResults,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarouselPageButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Icon(
        icon,
        color: enabled ? Colors.white : Colors.white.withOpacity(0.32),
        size: 20,
      ),
    );
  }

  Widget _buildDestinationCard(
    Destination dest, {
    String heroPrefix = 'card_hero',
  }) {
    final isSaved = _savedNames.contains(dest.name);
    final isLiked = _likedNames.contains(dest.name);
    final likeCount = _fakeLikeCountFor(dest, isLiked: isLiked);
    final isBusy = _updatingSavedNames.contains(dest.name);

    return Padding(
      padding: const EdgeInsets.only(bottom: 80, left: 6, right: 6),
      child: Builder(
        builder: (cardContext) {
          return Hero(
            tag: '${heroPrefix}_${dest.name}',
            flightShuttleBuilder: (_, __, ___, ____, _____) =>
                const SizedBox.shrink(),
            placeholderBuilder: (context, size, child) =>
                Opacity(opacity: 0.0, child: child),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
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
                    Positioned(
                      top: 14,
                      left: 14,
                      child: GestureDetector(
                        onTap: () => _toggleLike(dest),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(scale: animation, child: child),
                            child: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              key: ValueKey<bool>(isLiked),
                              color: isLiked
                                  ? const Color(0xFFE74C3C)
                                  : Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 62,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.36),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Text(
                          '$likeCount',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isLiked
                                ? const Color(0xFFE74C3C)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      right: 14,
                      child: GestureDetector(
                        onTap: isBusy ? null : () => _toggleSaved(dest),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(scale: animation, child: child),
                            child: isBusy
                                ? const Padding(
                                    key: ValueKey<String>('loading'),
                                    padding: EdgeInsets.all(11),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    isSaved
                                        ? Icons.bookmark_rounded
                                        : Icons.bookmark_border_rounded,
                                    key: ValueKey<bool>(isSaved),
                                    color: isSaved
                                        ? const Color(0xFFD4AF7A)
                                        : Colors.white,
                                    size: 22,
                                  ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 180,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.75),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 20,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: dest.type == 'Nhà hàng'
                                        ? const Color(0xFFE67E22)
                                            .withValues(alpha: 0.85)
                                        : dest.type == 'Khách sạn'
                                            ? const Color(0xFF3498DB)
                                                .withValues(alpha: 0.85)
                                            : const Color(0xFFB5956A)
                                                .withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    dest.type,
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.pin_drop_rounded,
                                        color: Color(0xFFB5956A), size: 24),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        dest.name,
                                        style: const TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                              color: Color(0x88000000),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dest.province,
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _openPlaceDetail(dest, cardContext),
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFFB5956A),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFB5956A)
                                        .withValues(alpha: 0.8),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 0),
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFFB5956A)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 35,
                                    spreadRadius: 8,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 24,
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
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      Icons.home_rounded,
      Icons.search_rounded,
      Icons.bookmark_rounded,
      Icons.explore_rounded,
      Icons.person_rounded,
    ];

    return FadeTransition(
      opacity: _cardEntrance,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (i) {
                final isActive = _navIndex == i;
                return GestureDetector(
                  onTap: () async {
                    if (i == _tabSurvey) {
                      await _openSurveyForCurrentLayout();
                    } else {
                      _showMainTab(i);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      items[i],
                      color: isActive
                          ? Colors.black
                          : Colors.white.withValues(alpha: 0.55),
                      size: 26,
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExploreStatItem extends StatelessWidget {
  final String value;
  final String label;

  const _ExploreStatItem({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 25,
            fontWeight: FontWeight.w800,
            color: Color(0xFFD4AF7A),
            height: 1.0,
            letterSpacing: 0.6,
            fontFeatures: [FontFeature.tabularFigures()],
            shadows: [
              Shadow(
                color: Color(0x552D2110),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 11),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Colors.white.withOpacity(0.86),
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}

class _SurveyAiWarmupGate extends StatefulWidget {
  final String? authToken;
  final String userName;
  final String? avatarUrl;

  const _SurveyAiWarmupGate({
    required this.authToken,
    required this.userName,
    required this.avatarUrl,
  });

  @override
  State<_SurveyAiWarmupGate> createState() => _SurveyAiWarmupGateState();
}

class _SurveyAiWarmupGateState extends State<_SurveyAiWarmupGate> {
  bool _isReady = false;

  bool get _isVi => Localizations.localeOf(context).languageCode == 'vi';

  @override
  void initState() {
    super.initState();
    unawaited(_waitForAiBackend());
  }

  Future<bool> _pingAiBackend() async {
    try {
      final response = await apiAiGet('/', timeout: const Duration(seconds: 8));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<void> _waitForAiBackend() async {
    while (mounted && !_isReady) {
      if (await _pingAiBackend()) {
        if (!mounted) return;
        setState(() => _isReady = true);
        return;
      }

      await Future<void>.delayed(const Duration(seconds: 3));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isReady) {
      return SurveyScreen(
        authToken: widget.authToken,
        userName: widget.userName,
        avatarUrl: widget.avatarUrl,
      );
    }

    return _SurveyAiWarmupView(isVi: _isVi);
  }
}

class _SurveyAiWarmupView extends StatelessWidget {
  final bool isVi;
  final bool embedded;

  const _SurveyAiWarmupView({
    required this.isVi,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              width: 420,
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.34),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                    color: Colors.white.withOpacity(0.14), width: 1.2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 42,
                    height: 42,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Color(0xFFD4AF7A),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    isVi ? 'Chờ một xíu' : 'Please wait a moment',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isVi
                        ? 'AI Backend đang khởi động. TourXport sẽ mở khảo sát ngay khi kết nối thành công.'
                        : 'The AI Backend is starting. TourXport will open the survey as soon as the connection is ready.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      color: Colors.white.withOpacity(0.68),
                      fontSize: 13,
                      height: 1.55,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (embedded) {
      return card;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F1412),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/halong.jpg', fit: BoxFit.cover),
          Container(color: const Color(0xFF1B2321).withOpacity(0.78)),
          card,
        ],
      ),
    );
  }
}

class ShimmerWidget extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const ShimmerWidget({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFF152A25),
                Color(0xFF28443D),
                Color(0xFF152A25),
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ],
            ),
          ),
        );
      },
    );
  }
}
