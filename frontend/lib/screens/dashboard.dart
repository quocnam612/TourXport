import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../api/api.dart';
import '../widgets/responsive_builder.dart';
import '../models/destination.dart';
import '../widgets/anim_builder.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'edit_profile_screen.dart';
import 'email_settings_screen.dart';
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
import '../models/travel_notification.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final String? authToken;

  const HomeScreen({
    super.key,
    this.userName = 'Username',
    this.authToken,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  int _previousIndex = 0;
  int _navIndex = 0;
  int _savedPlacesInitialTab = 0;
  bool _showLikedOnly = false;
  String _searchQuery = '';
  String? _selectedCity;
  String _sortBy = 'reviewsCount';
  String _sortOrder = 'desc';
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
  late final PageController _pageController;
  Timer? _autoPlayTimer;
  Timer? _searchDebounceTimer;
  List<Destination> _searchResults = [];
  List<Destination> _searchSuggestions = [];
  final Map<String, List<Destination>> _cityCache = {};

  static const List<String> vietnameseProvinces = [
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

  static const Map<String, int> _fakeLikeSeeds = {
    'Hạ Long Bay': 1243,
    'Hội An': 987,
    'Đà Nẵng': 1765,
    'Phong Nha': 842,
  };

  @override
  void initState() {
    super.initState();

    _currentUserName = widget.userName;
    _selectedCity = vietnameseProvinces[0];
    _initMockNotifications();
    _pageController = PageController(viewportFraction: 0.82, initialPage: 1000);
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
    _entranceController.forward();

    _loadSavedPlaces();
    _loadProfile();
    _fetchDestinations();
    _startAutoPlay();
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
    super.dispose();
  }

  void _startAutoPlay() {
    _stopAutoPlay();
    if (_navIndex != 0) return;

    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      if (_navIndex != 0) {
        _stopAutoPlay();
        return;
      }

      final destinations = _homeDestinations;
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

  void _onPageChanged(int index) {
    final activeList = _homeDestinations;
    if (index >= 0 && index < activeList.length) {
      final nextPath = activeList[index].bgBlurPath;
      if (nextPath != _currentBgPath) {
        setState(() {
          _previousBgPath = _currentBgPath;
          _currentBgPath = nextPath;
          _previousIndex = _currentIndex;
          _currentIndex = index;
        });
        _bgFadeController.forward(from: 0);
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

      final allSucceeded = responses.every((response) => response.statusCode == 200);
      if (allSucceeded) {
        final payload = <String, dynamic>{
          'savedPlaces': tryDecodeJsonObject(responses[0].body)?['savedPlaces'] ?? [],
          'savedRestaurants': tryDecodeJsonObject(responses[1].body)?['savedRestaurants'] ?? [],
          'savedHotels': tryDecodeJsonObject(responses[2].body)?['savedHotels'] ?? [],
        };
        _applySavedPlacesPayload(payload);
      } else if (showError) {
        _showMessage(
            'Không tải được danh sách đã lưu');
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

  Future<List<Destination>> _fetchMixedDestinationsForCity(String city) async {
    final encodedCity = Uri.encodeComponent(city);
    final futures = [
      apiGet('/locations?city=$encodedCity&limit=3&sortBy=reviewsCount&order=desc'),
      apiGet('/restaurants?city=$encodedCity&limit=2&sortBy=reviewsCount&order=desc'),
      apiGet('/hotels?city=$encodedCity&limit=2&sortBy=reviewsCount&order=desc'),
    ];
    final responses = await Future.wait(futures);

    final List<Destination> locs = [];
    final List<Destination> rests = [];
    final List<Destination> hots = [];

    // 1. Locations
    try {
      final res = responses[0];
      final data = tryDecodeJsonObject(res.body);
      if (res.statusCode == 200 && data?['success'] == true && data?['data'] is List) {
        for (var item in data!['data']) {
          final map = Map<String, dynamic>.from(item);
          map['type'] = 'Địa điểm';
          locs.add(Destination.fromJson(map));
        }
      }
    } catch (e) {
      debugPrint('Error parsing locations: $e');
    }

    // 2. Restaurants
    try {
      final res = responses[1];
      final data = tryDecodeJsonObject(res.body);
      if (res.statusCode == 200 && data?['success'] == true && data?['data'] is List) {
        for (var item in data!['data']) {
          final map = Map<String, dynamic>.from(item);
          map['type'] = 'Nhà hàng';
          rests.add(Destination.fromJson(map));
        }
      }
    } catch (e) {
      debugPrint('Error parsing restaurants: $e');
    }

    // 3. Hotels
    try {
      final res = responses[2];
      final data = tryDecodeJsonObject(res.body);
      if (res.statusCode == 200 && data?['success'] == true && data?['data'] is List) {
        for (var item in data!['data']) {
          final map = Map<String, dynamic>.from(item);
          map['type'] = 'Khách sạn';
          hots.add(Destination.fromJson(map));
        }
      }
    } catch (e) {
      debugPrint('Error parsing hotels: $e');
    }

    // Round-robin mix
    final List<Destination> loaded = [];
    while (locs.isNotEmpty || rests.isNotEmpty || hots.isNotEmpty) {
      if (locs.isNotEmpty) loaded.add(locs.removeAt(0));
      if (rests.isNotEmpty) loaded.add(rests.removeAt(0));
      if (hots.isNotEmpty) loaded.add(hots.removeAt(0));
    }
    return loaded;
  }

  Future<void> _fetchDestinations() async {
    if (mounted) {
      setState(() => _isLoadingDestinations = true);
    }
    try {
      // 1. Fetch top mixed destinations for the selected city
      final city = _selectedCity ?? vietnameseProvinces[0];
      final List<Destination> loaded = await _fetchMixedDestinationsForCity(city);

      if (mounted) {
        _cityCache[city] = loaded;
        setState(() {
          _realDestinations = loaded;
          final list = _homeDestinations;
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

  Future<void> _selectCity(String city) async {
    if (_selectedCity == city && _realDestinations.isNotEmpty && _searchQuery.isEmpty) return;

    if (_cityCache.containsKey(city)) {
      final cachedList = _cityCache[city]!;
      setState(() {
        _selectedCity = city;
        _isLoadingDestinations = false;
        _currentIndex = 0;
        _searchResults = [];
        _searchController.clear();
        _searchQuery = '';
        _realDestinations = cachedList;
        final list = _homeDestinations;
        if (list.isNotEmpty) {
          _currentBgPath = list[0].bgBlurPath;
          _previousBgPath = list[0].bgBlurPath;
        } else {
          _currentBgPath = 'assets/images/halong.jpg';
          _previousBgPath = 'assets/images/halong.jpg';
        }
      });
      _resetCarouselPosition();
      _startAutoPlay();
      return;
    }

    setState(() {
      _selectedCity = city;
      _isLoadingDestinations = true;
      _currentIndex = 0;
      _searchResults = [];
      _searchController.clear();
      _searchQuery = '';
      // Keep _realDestinations as-is so the UI stays stable while loading
    });

    try {
      final List<Destination> loaded = await _fetchMixedDestinationsForCity(city);

      if (mounted && _selectedCity == city) {
        _cityCache[city] = loaded;
        setState(() {
          _realDestinations = loaded;
          final list = _homeDestinations;
          if (list.isNotEmpty) {
            _currentBgPath = list[0].bgBlurPath;
            _previousBgPath = list[0].bgBlurPath;
          } else {
            _currentBgPath = 'assets/images/halong.jpg';
            _previousBgPath = 'assets/images/halong.jpg';
          }
        });
        _resetCarouselPosition();
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
    ]
        .where((item) => item.name.isNotEmpty)
        .toList();

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
    if (!Platform.isAndroid) return true;

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
    if (Platform.isAndroid) {
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

      final file = File(image.path);

      if (isAvatar) {
        final response = await apiPutMultipart(
          '/auth/profile/avatar',
          'avatar',
          file,
          token: widget.authToken,
        );

        final responseStr = await response.stream.bytesToString();
        final data = tryDecodeJsonObject(responseStr);

        if (response.statusCode == 200 && data != null && data['success'] == true) {
          _loadProfile();
          _showMessage('Đã cập nhật ảnh đại diện thành công');
        } else {
          _showMessage(data?['message'] ?? 'Cập nhật avatar thất bại');
        }
      } else {
        final response = await apiPostMultipart(
          '/auth/upload',
          'image',
          file,
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
              onPressed: () {
                Navigator.pop(context); // Close dialog
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

  Future<void> _openEditProfile() async {
    if (_userData == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          userData: _userData!,
          authToken: widget.authToken!,
        ),
      ),
    );

    if (result == true) {
      _loadProfile();
    }
  }

  Future<void> _editName() => _showEditFieldDialog(
        'Tên',
        'name',
        _userData?['name'] ?? '',
        const Color(0xFFD4AF7A),
        Icons.person_rounded,
      );

  Future<void> _editHelpSupport() async {
    if (_userData == null) return;
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            HelpSupportScreen(userData: _userData!),
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

  Future<void> _editEmail() async {
    if (_userData == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmailSettingsScreen(
          userData: _userData!,
          authToken: widget.authToken!,
        ),
      ),
    );

    if (result == true) {
      _loadProfile();
    }
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
        description: 'Lịch trình tham quan Đà Nẵng 3 ngày 2 đêm của bạn đã sẵn sàng! Chạm để xem ngay các địa điểm tối ưu.',
        icon: Icons.map_rounded,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        type: 'itinerary',
      ),
      TravelNotification(
        id: 'notif_2',
        title: 'Cảnh báo thời tiết',
        description: 'Dự báo thời tiết Đà Nẵng hôm nay: 26°C, trời nắng đẹp, gió mát mẻ, rất lý tưởng để đi biển hoặc ghé Bà Nà Hills.',
        icon: Icons.wb_sunny_rounded,
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        type: 'weather',
      ),
      TravelNotification(
        id: 'notif_3',
        title: 'Cập nhật ngân sách chuyến đi',
        description: 'Tổng chi tiêu dự kiến hiện tại là 1.250.000đ. Bạn đang kiểm soát ngân sách rất tốt (đạt 62% hạn mức tự đặt).',
        icon: Icons.account_balance_wallet_rounded,
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        type: 'expense',
      ),
      TravelNotification(
        id: 'notif_4',
        title: 'Mẹo du lịch hữu ích',
        description: 'Kinh nghiệm đắt giá: Nên di chuyển lên Cầu Vàng lúc 8h sáng để chụp hình không vướng người và ngắm trọn mây ngàn.',
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
      periodTag = 'HOT HÔM NAY';
      periodLabel = 'day';
      for (int i = 0; i < pool.length; i++) {
        if (i % 3 == 0) periodDestinations.add(pool[i]);
      }
    } else if (_selectedTrendFilter == 'week') {
      periodTag = 'XU HƯỚNG TUẦN';
      periodLabel = 'week';
      for (int i = 0; i < pool.length; i++) {
        if (i % 3 == 1) periodDestinations.add(pool[i]);
      }
    } else {
      periodTag = 'ĐỀ XUẤT THÁNG';
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
      final price = dest.price.isNotEmpty ? dest.price : 'Chỉ từ 1.500.000 đ';
      
      String reason = '';
      String tag = periodTag;
      double rating = 4.7 + ((dest.name.length % 3) * 0.1);
      int reviews = 800 + (dest.name.length * 77) % 2500;

      if (name.toLowerCase().contains('hạ long') || name.toLowerCase().contains('ha long')) {
        reason = 'Thời tiết tại Vịnh ${prov} tuần này vô cùng dịu mát, nước biển trong xanh lý tưởng để trải nghiệm du thuyền 5 sao đẳng cấp.';
        tag = 'DU THUYỀN 5 SAO';
      } else if (name.toLowerCase().contains('đà nẵng') || name.toLowerCase().contains('da nang')) {
        reason = 'Nhiệt độ hoàn hảo 26°C. Lễ hội pháo hoa quốc tế vừa diễn ra thu hút đông đảo du khách ghé thăm các cây cầu huyền thoại.';
        tag = 'PHÁO HOA QUỐC TẾ';
      } else if (name.toLowerCase().contains('hội an') || name.toLowerCase().contains('hoi an')) {
        reason = 'Khí hậu bắt đầu vào mùa khô ráo tuyệt đẹp. Phố đèn lồng lung linh lộng lẫy và lễ hội hoa đăng bên sông Hoài đang diễn ra rất náo nhiệt.';
        tag = 'PHỐ CỔ HOÀI CỔ';
      } else if (name.toLowerCase().contains('phong nha') || name.toLowerCase().contains('quảng bình') || name.toLowerCase().contains('quang binh')) {
        reason = 'Thời tiết khô ráo rất thích hợp để thám hiểm hệ thống hang động thạch nhũ tráng lệ bậc nhất thế giới.';
        tag = 'KHÁM PHÁ HANG ĐỘNG';
      } else if (name.toLowerCase().contains('phú quốc') || name.toLowerCase().contains('phu quoc')) {
        reason = 'Biển cực kỳ êm, nắng vàng rực rỡ và nước biển trong vắt như pha lê, hoàn hảo cho tour lặn biển ngắm san hô.';
        tag = 'THIÊN ĐƯỜNG BIỂN';
      } else if (name.toLowerCase().contains('sapa')) {
        reason = 'Đỉnh Fansipan xuất hiện biển mây cực đẹp vào sáng sớm, nhiệt độ se lạnh lý tưởng để thưởng thức ẩm thực Tây Bắc.';
        tag = 'SĂN MÂY TÂY BẮC';
      } else if (name.toLowerCase().contains('đà lạt') || name.toLowerCase().contains('da lat')) {
        reason = 'Mùa hoa dã quỳ vàng rực rỡ khắp các triền đồi, không khí mát mẻ dễ chịu vô cùng thích hợp cho cắm trại đêm.';
        tag = 'THÀNH PHỐ NGÀN HOA';
      } else {
        reason = 'Điểm đến đang nhận được sự quan tâm đột biến từ cộng đồng du lịch nhờ khí hậu thuận lợi và nhiều ưu đãi dịch vụ hấp dẫn trong thời gian này.';
        tag = 'ĐIỂM ĐẾN VÀNG';
      }

      return AppTrendRecommendation(
        title: '$name - Khám phá vẻ đẹp kỳ diệu',
        province: prov,
        price: price,
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
            const Icon(Icons.notifications_none_rounded, color: Colors.white24, size: 64),
            const SizedBox(height: 16),
            Text(
              'Chưa có thông báo nào dành cho bạn',
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
                                      color: item.isRead ? Colors.white : const Color(0xFFD4AF7A),
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
                          color: Colors.white.withOpacity(item.isRead ? 0.6 : 0.85),
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
              _buildTrendFilterButton('day', 'Hôm nay', setSheetState),
              const SizedBox(width: 8),
              _buildTrendFilterButton('week', 'Tuần này', setSheetState),
              const SizedBox(width: 8),
              _buildTrendFilterButton('month', 'Tháng này', setSheetState),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Scrollable list of recommendations
        Expanded(
          child: trends.isEmpty
              ? Center(
                  child: Text(
                    'Không có đề xuất nào cho khoảng thời gian này.',
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
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Top row
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFD4AF7A), Color(0xFFB5956A)],
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFD4AF7A).withOpacity(0.3),
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
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.6),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: Colors.white24, width: 0.8),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.star_rounded, color: Color(0xFFF1C40F), size: 14),
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    rec.province.toUpperCase(),
                                                    style: const TextStyle(
                                                      fontFamily: 'Montserrat',
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFFD4AF7A),
                                                      letterSpacing: 1.0,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    rec.title,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontFamily: 'Montserrat',
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
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
                                            color: Colors.white.withOpacity(0.8),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '⭐ ${rec.rating} · ${rec.reviewsCount} lượt quan tâm',
                                              style: TextStyle(
                                                fontFamily: 'Montserrat',
                                                fontSize: 12,
                                                color: Colors.white.withOpacity(0.5),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.pop(context);
                                                _openPlaceDetail(rec.destination, context);
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: Colors.transparent,
                                                  borderRadius: BorderRadius.circular(16),
                                                  border: Border.all(color: const Color(0xFFD4AF7A), width: 1.5),
                                                ),
                                                child: const Row(
                                                  children: [
                                                    Text(
                                                      'Lên lịch ngay',
                                                      style: TextStyle(
                                                        fontFamily: 'Montserrat',
                                                        fontSize: 12.5,
                                                        fontWeight: FontWeight.bold,
                                                        color: Color(0xFFD4AF7A),
                                                      ),
                                                    ),
                                                    SizedBox(width: 4),
                                                    Icon(Icons.arrow_forward_rounded, color: Color(0xFFD4AF7A), size: 14),
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

  Widget _buildTrendFilterButton(String key, String title, StateSetter setSheetState) {
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
            color: isActive ? const Color(0xFFD4AF7A).withOpacity(0.15) : Colors.transparent,
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

  Future<void> _showEditFieldDialog(String label, String fieldKey,
      String initialValue, Color accentColor, IconData icon) async {
    final controller = TextEditingController(text: initialValue);

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: const Color(0xFF1B2321).withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 40,
              spreadRadius: 10,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Stack(
              children: [
                // Large Background Decorative Icon
                Positioned(
                  top: -20,
                  right: -30,
                  child: Icon(
                    icon,
                    size: 200,
                    color: accentColor.withOpacity(0.05),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 12,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(icon, color: accentColor, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Chỉnh sửa $label',
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded,
                                  color: Colors.white70, size: 20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Cập nhật $label của bạn để mọi người có thể kết nối với bạn dễ dàng hơn.',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.5),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Themed Input
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: accentColor.withOpacity(0.4),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withOpacity(0.1),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: controller,
                          autofocus: true,
                          keyboardType: fieldKey == 'phone'
                              ? TextInputType.phone
                              : (fieldKey == 'email'
                                  ? TextInputType.emailAddress
                                  : TextInputType.text),
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Nhập $label mới...',
                            hintStyle:
                                TextStyle(color: Colors.white.withOpacity(0.2)),
                            border: InputBorder.none,
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: ElevatedButton(
                          onPressed: () async {
                            final newValue = controller.text.trim();
                            if (newValue == initialValue) {
                              Navigator.pop(context);
                              return;
                            }

                            final token = widget.authToken?.trim();
                            if (token == null) return;

                            final response = await apiPutJson(
                              '/auth/profile',
                              {fieldKey: newValue},
                              token: token,
                            );

                            if (response.statusCode == 200) {
                              Navigator.pop(context, true);
                            } else {
                              _showMessage('Cập nhật thất bại');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 12,
                            shadowColor: accentColor.withOpacity(0.4),
                          ),
                          child: const Text(
                            'Lưu thay đổi',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true) {
      _loadProfile();
    }
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
        placeId = await resolveLocationIdByName(dest.name, dest.type, token: token);
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
    final useSimpleTransition = _navIndex == 1;
    Rect? cardRect;

    if (!useSimpleTransition) {
      final renderBox = cardContext.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final offset = renderBox.localToGlobal(Offset.zero);
        cardRect = offset & renderBox.size;
      }
    }

    _stopAutoPlay();

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
    final destinations = _homeDestinations;
    final idx = destinations.indexWhere((d) => _citiesMatch(d.province, region));
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
    var withDiacritics = 'àáảãạăắằẳẵặâấầẩẫậèéẻẽẹêếềểễệìíỉĩịòóỏõọôốồổỗộơớờởỡợùúủũụưứừửữựỳýỷỹỵđĐ';
    var withoutDiacritics = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyydd';
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

  List<Destination> get _homeDestinations {
    if (_searchQuery.isNotEmpty || _nearbyEnabled) {
      var list = _searchResults;
      if (_showLikedOnly) {
        list = list.where((d) => _likedNames.contains(d.name)).toList();
      }
      return list;
    }
    
    final activeCity = _selectedCity ?? (vietnameseProvinces.isNotEmpty ? vietnameseProvinces[0] : 'Đà Nẵng');
    
    // 1. Use ALL real database destinations directly (the API already filtered by city)
    final List<Destination> list = List<Destination>.from(_realDestinations);
    
    // 2. Only pad with fallbacks if we have fewer than 5 database results
    if (list.length < 5) {
      final fallbacks = getFallbackDestinationsForProvince(activeCity);
      for (var f in fallbacks) {
        if (list.length >= 5) break;
        if (!list.any((d) => d.name.toLowerCase().trim() == f.name.toLowerCase().trim())) {
          list.add(f);
        }
      }
    }
    
    var filteredList = list;
    if (_showLikedOnly) {
      filteredList = list.where((d) => _likedNames.contains(d.name)).toList();
    }
    return filteredList;
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _currentIndex = 0;
      _searchSuggestions = [];
    });

    _searchDebounceTimer?.cancel();
    if (value.trim().isEmpty && !_nearbyEnabled) {
      setState(() {
        _searchResults = [];
        _searchSuggestions = [];
      });
      _resetCarouselPosition();
      final list = _homeDestinations;
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
      final queryParams = <String, String>{};
      if (query.trim().isNotEmpty) {
        queryParams['query'] = query;
      }
      if (_selectedCity != null) {
        queryParams['city'] = _selectedCity!;
      }
      queryParams['sortBy'] = _sortBy;
      queryParams['order'] = _sortOrder;

      if (_nearbyEnabled) {
        // Đà Nẵng coordinates
        queryParams['gps'] = '108.26409,16.002966';
        queryParams['radius'] = _radius.round().toString();
      }

      final queryString = Uri(queryParameters: queryParams).query;
      final path =
          queryString.isNotEmpty ? '/locations?$queryString' : '/locations';

      final response = await apiGet(path);
      final data = tryDecodeJsonObject(response.body);
      if (response.statusCode == 200 && data?['success'] == true) {
        final rawList = data!['data'];
        if (rawList is List) {
          final List<Destination> loaded = [];
          for (var item in rawList) {
            try {
              loaded.add(Destination.fromJson(Map<String, dynamic>.from(item)));
            } catch (e) {
              debugPrint('Error parsing search item: $e');
            }
          }
          if (mounted && _searchQuery == query) {
            setState(() {
              _searchResults = loaded;
              _searchSuggestions = loaded.take(5).toList();

              if (_searchResults.isNotEmpty) {
                _currentBgPath = _searchResults[0].bgBlurPath;
                _previousBgPath = _searchResults[0].bgBlurPath;
              }
            });
            _resetCarouselPosition();
          }
        }
      }
    } catch (e) {
      debugPrint('Error performing backend search: $e');
    }
  }

  void _resetCarouselPosition() {
    if (_pageController.hasClients) {
      final list = _homeDestinations;
      if (list.length > 3) {
        _pageController.jumpToPage(1000 - (1000 % list.length));
      } else {
        _pageController.jumpToPage(0);
      }
    }
  }

  void _toggleLikedOnlyView() {
    setState(() => _showLikedOnly = !_showLikedOnly);

    final destinations = _homeDestinations;
    if (destinations.isEmpty) {
      _showMessage('Chưa có địa điểm nào được thả tim');
      return;
    }

    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = 0;
      _currentBgPath = destinations[0].bgBlurPath;
      _previousBgPath = destinations[0].bgBlurPath;
    });

    _resetCarouselPosition();
  }

  void _jumpToRandomDestination() {
    final destinations = _homeDestinations;
    if (destinations.isEmpty) {
      _showMessage('Không có địa điểm để chọn ngẫu nhiên');
      return;
    }
    final seed = DateTime.now().microsecondsSinceEpoch.abs();
    final idx = seed % destinations.length;

    if (_pageController.hasClients) {
      final currentPage = _pageController.page?.round() ?? 1000;
      final currentListIndex = currentPage % destinations.length;
      final offset = idx - currentListIndex;
      _pageController.animateToPage(
        currentPage + offset,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _openSearchToolsSheet() async {
    final cities = vietnameseProvinces;
    final sortOptions = [
      {'label': 'Lượt review', 'field': 'reviewsCount', 'order': 'desc'},
      {'label': 'Điểm số', 'field': 'totalScore', 'order': 'desc'},
      {'label': 'Tên A-Z', 'field': 'title', 'order': 'asc'},
    ];

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
                        const Text(
                          'Bộ lọc & Công cụ',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (_selectedCity != vietnameseProvinces[0] ||
                            _nearbyEnabled ||
                            _showLikedOnly ||
                            _sortBy != 'reviewsCount')
                          GestureDetector(
                            onTap: () {
                              setSheetState(() {
                                _selectedCity = vietnameseProvinces[0];
                                _nearbyEnabled = false;
                                _sortBy = 'reviewsCount';
                                _sortOrder = 'desc';
                                _showLikedOnly = false;
                              });
                              setState(() {});
                              if (_searchQuery.trim().isNotEmpty) {
                                _performBackendSearch(_searchQuery);
                              } else {
                                _selectCity(vietnameseProvinces[0]);
                              }
                            },
                            child: const Text(
                              'Đặt lại',
                              style: TextStyle(
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

                    // SECTION 1: QUICK TOOLS
                    Text(
                      'Công cụ nhanh',
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
                          child: _toolFilterChip(
                            icon: _showLikedOnly
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            label: 'Đã thích',
                            isActive: _showLikedOnly,
                            onTap: () {
                              setSheetState(() {
                                _showLikedOnly = !_showLikedOnly;
                              });
                              _toggleLikedOnlyView();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _toolFilterChip(
                            icon: Icons.casino_rounded,
                            label: 'Ngẫu nhiên',
                            isActive: false,
                            onTap: () {
                              Navigator.pop(context);
                              _jumpToRandomDestination();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // SECTION 2: CHOOSE CITY
                    Text(
                      'Lọc theo Thành phố',
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
                          ...cities.map((city) {
                            final isFirst = city == cities.first;
                            return Padding(
                              padding: EdgeInsets.only(left: isFirst ? 0.0 : 8.0),
                              child: _choiceChip(
                                label: city,
                                isSelected: _selectedCity == city,
                                onTap: () {
                                  setSheetState(() {
                                    _selectedCity = city;
                                  });
                                  setState(() {});
                                  if (_searchQuery.trim().isNotEmpty) {
                                    _performBackendSearch(_searchQuery);
                                  } else {
                                    _selectCity(city);
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SECTION 3: SORT BY
                    Text(
                      'Sắp xếp theo',
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
                      children: sortOptions.map((opt) {
                        final isSelected = _sortBy == opt['field'];
                        return Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4.0),
                            child: _choiceChip(
                              label: opt['label']!,
                              isSelected: isSelected,
                              centerText: true,
                              onTap: () {
                                setSheetState(() {
                                  _sortBy = opt['field']!;
                                  _sortOrder = opt['order']!;
                                });
                                setState(() {});
                                _performBackendSearch(_searchQuery);
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // SECTION 4: NEARBY / GPS
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
                                  const Text(
                                    'Tìm kiếm xung quanh (GPS)',
                                    style: TextStyle(
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
                                  setState(() {});
                                  _performBackendSearch(_searchQuery);
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
                                  'Bán kính: ${_radius >= 1000 ? "${(_radius / 1000).toStringAsFixed(1)} km" : "${_radius.round()} m"}',
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
                                setState(() {});
                                _performBackendSearch(_searchQuery);
                              },
                            ),
                          ],
                        ],
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

  Widget _toolFilterChip({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFFD4AF7A).withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? const Color(0xFFD4AF7A)
                : Colors.white.withOpacity(0.08),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: isActive ? const Color(0xFFD4AF7A) : Colors.white70,
                size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isActive ? const Color(0xFFD4AF7A) : Colors.white70,
              ),
            ),
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
            bottom: _navIndex == 3
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
      (Icons.home_rounded, 'Khám phá'),
      (Icons.bookmark_rounded, 'Đã lưu'),
      (Icons.explore_rounded, 'Khảo sát'),
      (Icons.person_rounded, 'Tài khoản'),
    ];

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: const Color(0xFF070E0D).withOpacity(0.45), // Semi-transparent dark green/black background for glass effect
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
                          'Thành viên',
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
                      if (i == 2) {
                        _stopAutoPlay();
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SurveyScreen(
                              authToken: widget.authToken,
                            ),
                          ),
                        );
                        _startAutoPlay();
                        if (result == 'go_to_saved_tours') {
                          setState(() {
                            _savedPlacesInitialTab = 1;
                            _navIndex = 1;
                          });
                        }
                      } else {
                        setState(() {
                          _navIndex = i;
                          _savedPlacesInitialTab = 0;
                        });
                        if (i == 0) {
                          _startAutoPlay();
                        } else {
                          _stopAutoPlay();
                        }
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
                              ? const Color(0xFFD4AF7A).withOpacity(0.65) // Subtle glowing gold border for active item
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
                                : Colors.white.withOpacity(0.65), // Crisp contrast for inactive icons
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
                                  : Colors.white.withOpacity(0.65), // Highly legible inactive text
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
                        isGuest ? 'Tài khoản' : 'Đăng xuất',
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
    final isSurveyStyle = _navIndex == 1 || _navIndex == 3;
    final blurVal = isSurveyStyle ? 10.0 : (isDesktop ? 0.8 : 5.0);
    final bgPath = isSurveyStyle ? 'assets/images/login_bg.jpg' : _previousBgPath;

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
    final isSurveyStyle = _navIndex == 1 || _navIndex == 3;
    final blurVal = isSurveyStyle ? 10.0 : (isDesktop ? 0.8 : 5.0);
    final bgPath = isSurveyStyle ? 'assets/images/login_bg.jpg' : _currentBgPath;

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
    final isSurveyStyle = _navIndex == 1 || _navIndex == 3;

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
        SavedPlacesSection(
          authToken: widget.authToken,
          initialTabIndex: _savedPlacesInitialTab,
          entranceAnimation: _cardEntrance,
          savedDestinations: _savedDestinations,
          updatingSavedNames: _updatingSavedNames,
          isLoading: _isLoadingSavedPlaces,
          onBack: () {
            setState(() {
              _navIndex = 0;
              _savedPlacesInitialTab = 0;
            });
            _startAutoPlay();
          },
          onOpenDetail: _openPlaceDetail,
          onToggleSaved: _toggleSaved,
          isGuest: widget.authToken == null || widget.authToken!.isEmpty,
        ),
        const SizedBox.shrink(),
        ProfileSection(
          entranceAnimation: _cardEntrance,
          userData: _userData,
          isLoading: _isLoadingProfile,
          onBack: () {
            setState(() => _navIndex = 0);
            _startAutoPlay();
          },
          onLogout: _logout,
          onUpdateAvatar: () => _showEditImageDialog(true),
          onUpdateCover: () => _showEditImageDialog(false),
          onEditName: _openEditProfile,
          onEditEmail: _editEmail,
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
    final list = _homeDestinations;
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
      final list = _homeDestinations;
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
      final destinations = _homeDestinations;
      if (destinations.isEmpty) {
        return Center(
          child: Text(
            'Chưa có địa điểm nào phù hợp.',
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
                                    cat.toLowerCase(),
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 13,
                                      fontWeight: isThisCatActive
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isThisCatActive
                                          ? Colors.white
                                          : Colors.white60,
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
                              const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20),
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
                              final prevIdx = (_currentIndex - 1 + destinations.length) % destinations.length;
                              _selectDestination(prevIdx);
                            },
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white30, width: 1.5),
                                color: Colors.white.withOpacity(0.05),
                              ),
                              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
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
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          // Right Arrow Button
                          WebHoverable(
                            onTap: () {
                              final nextIdx = (_currentIndex + 1) % destinations.length;
                              _selectDestination(nextIdx);
                            },
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white30, width: 1.5),
                                color: Colors.white.withOpacity(0.05),
                              ),
                              child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
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
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    WebHoverable(
                                      onTap: () => _openPlaceDetail(activeDest, ctx),
                                      child: const Text(
                                        'XEM CHI TIẾT >>',
                                        style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFFD4AF7A),
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Builder(
                                      builder: (buttonCtx) {
                                        final isSaved = _savedNames.contains(activeDest.name);
                                        final isBusy = _updatingSavedNames.contains(activeDest.name);
                                        
                                        return WebHoverable(
                                          onTap: isBusy ? null : () async {
                                            await _toggleSaved(activeDest);
                                            setState(() {});
                                          },
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                                color: isSaved ? const Color(0xFFD4AF7A) : Colors.white70,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                isSaved ? 'ĐÃ LƯU' : 'LƯU ĐỊA ĐIỂM',
                                                style: TextStyle(
                                                  fontFamily: 'Montserrat',
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w800,
                                                  color: isSaved ? const Color(0xFFD4AF7A) : Colors.white70,
                                                  letterSpacing: 1.0,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                    ),
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
              padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 50),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'confusion? These recommendation',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFFD4AF7A),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: dest.type == 'Nhà hàng'
                                          ? const Color(0xFFE67E22).withValues(alpha: 0.85)
                                          : dest.type == 'Khách sạn'
                                              ? const Color(0xFF3498DB).withValues(alpha: 0.85)
                                              : const Color(0xFFB5956A).withValues(alpha: 0.85),
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
                            _stopAutoPlay();
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SurveyScreen(
                                  authToken: widget.authToken,
                                ),
                              ),
                            );
                            _startAutoPlay();
                            if (result == 'go_to_saved_tours') {
                              setState(() {
                                _savedPlacesInitialTab = 1;
                                _navIndex = 1;
                              });
                            }
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
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  _buildRegionTabs(),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _buildCardCarousel(size),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
              if (_searchFocusNode.hasFocus)
                Positioned(
                  top: 60,
                  left: 0,
                  right: 0,
                  child: _buildSuggestionsDropdown(),
                ),
            ],
          ),
        ),
      ],
    );

    return content;
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
                  'Xin chào,\n$_currentUserName!',
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
                    const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24),
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
                  _resetCarouselPosition();
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
    return FadeTransition(
      opacity: _cardEntrance,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(_cardEntrance),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm trên TourXport...',
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
                  onPressed: () {
                    _showMessage(
                        'Tính năng tìm kiếm bằng giọng nói đang được phát triển');
                  },
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
                  regions[i],
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

  Widget _buildCardCarousel(Size size) {
    final destinations = _homeDestinations;
    if (destinations.isEmpty) {
      return Center(
        child: Text(
          'Chưa có địa điểm nào được thả tim.',
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
        child: PageView.builder(
          controller: _pageController,
          itemCount: showInfinite ? 100000 : destinations.length,
          onPageChanged: (index) {
            final listIndex = destinations.isEmpty
                ? 0
                : (showInfinite ? (index % destinations.length) : index);
            _onPageChanged(listIndex);
            _startAutoPlay();
          },
          itemBuilder: (context, index) {
            if (destinations.isEmpty) return const SizedBox.shrink();
            final listIndex =
                showInfinite ? (index % destinations.length) : index;
            return AnimBuilder(
              animation: _pageController,
              builder: (context, child) {
                double page =
                    _pageController.hasClients && _pageController.page != null
                        ? _pageController.page!
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
              child: _buildDestinationCard(destinations[listIndex]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDestinationCard(Destination dest) {
    final isSaved = _savedNames.contains(dest.name);
    final isLiked = _likedNames.contains(dest.name);
    final likeCount = _fakeLikeCountFor(dest, isLiked: isLiked);
    final isBusy = _updatingSavedNames.contains(dest.name);

    return Padding(
      padding: const EdgeInsets.only(bottom: 80, left: 6, right: 6),
      child: Builder(
        builder: (cardContext) {
          return Hero(
            tag: 'card_hero_${dest.name}',
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
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: dest.type == 'Nhà hàng'
                                        ? const Color(0xFFE67E22).withValues(alpha: 0.85)
                                        : dest.type == 'Khách sạn'
                                            ? const Color(0xFF3498DB).withValues(alpha: 0.85)
                                            : const Color(0xFFB5956A).withValues(alpha: 0.85),
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
                    if (i == 2) {
                      // Mở khảo sát khi nhấn vào nút Explore (Safari-like)
                      _stopAutoPlay();
                      final result = await Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => SurveyScreen(
                            authToken: widget.authToken,
                          ),
                          transitionDuration: const Duration(milliseconds: 500),
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
                      );
                      _startAutoPlay();
                      if (result == 'go_to_saved_tours') {
                        setState(() {
                          _savedPlacesInitialTab = 1;
                          _navIndex = 1;
                        });
                      }
                    } else {
                      setState(() {
                        _navIndex = i;
                        _savedPlacesInitialTab = 0;
                      });
                      if (i == 0) {
                        _startAutoPlay();
                      } else {
                        _stopAutoPlay();
                      }
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
