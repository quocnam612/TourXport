import 'dart:ui';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../models/destination.dart';
import '../utils/routing_service.dart';
import '../utils/navigation_helper.dart';
import '../widgets/map_warning_banner.dart';
import '../widgets/route_metrics_card.dart';

class MapScreen extends StatefulWidget {
  final Destination destination;

  const MapScreen({
    super.key,
    required this.destination,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _userLocation;
  List<LatLng> _routePoints = [];
  bool _isLoading = true;
  bool _showLocationWarningBanner = false;
  final MapController _mapController = MapController();
  
  // Vị trí mặc định nếu không lấy được GPS (Ví dụ: Hà Nội)
  static const LatLng _fallbackStart = LatLng(21.0285, 105.8542);

  @override
  void initState() {
    super.initState();
    _fetchLocationAndRoute();
  }

  Timer? _gpsDebounceTimer; // Timer debounce định vị GPS
  final Map<String, List<Map<String, dynamic>>> _suggestionsCache = {}; // Cache gợi ý tìm kiếm địa chỉ
  final Map<String, String> _reverseGeocodeCache = {}; // Cache giải mã tọa độ ngược

  @override
  void dispose() {
    _gpsDebounceTimer?.cancel();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  String? _manualStartLocationName; // Lưu tên vị trí người dùng tự nhập
  String? _gpsAddress; // Lưu địa chỉ đã được giải mã từ GPS
  int _activeMobileTab = 0; // 0: Đang chọn Xem Điểm đến, 1: Đang chọn Xem Điểm đi, 2: Xem toàn bộ đường đi (bản web)
  double _routeDistanceKm = 0.0; // Lưu khoảng cách tuyến đường (km)
  double _routeDurationMin = 0.0; // Lưu thời gian di chuyển dự kiến (phút)
  StreamSubscription<Position>? _positionStreamSubscription; // Lắng nghe di chuyển GPS
  bool _isRecalculating = false; // Ngăn chặn tính toán lại trùng lặp
  final String _selectedProfile = 'driving'; // Lưu phương tiện di chuyển ('driving', 'bicycle', 'foot')
  bool _showRouteMetricsCard = true; // Điều khiển hiển thị thẻ thông số tuyến đường
  bool _showLocationCard = true; // Điều khiển hiển thị ô địa điểm bên dưới

  // Hàm chuyển địa chỉ chữ sang tọa độ và danh sách gợi ý dùng API OpenStreetMap (Có cache & tryParse)
  Future<List<Map<String, dynamic>>> _fetchAddressSuggestions(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return [];

    if (_suggestionsCache.containsKey(cleanQuery)) {
      return _suggestionsCache[cleanQuery]!;
    }

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5'
    );
    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'TourXport/1.0 (com.example.tourxport; Flutter)',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        final List<Map<String, dynamic>> results = [];
        for (var item in data) {
          if (item is Map) {
            final latStr = item['lat'];
            final lonStr = item['lon'];
            final displayName = item['display_name'];
            if (latStr != null && lonStr != null && displayName != null) {
              final lat = double.tryParse(latStr.toString());
              final lon = double.tryParse(lonStr.toString());
              if (lat != null && lon != null) {
                results.add({
                  'display_name': displayName.toString(),
                  'latlng': LatLng(lat, lon),
                });
              }
            }
          }
        }
        _suggestionsCache[cleanQuery] = results;
        return results;
      }
    } catch (e) {
      print("Lỗi lấy danh sách gợi ý: $e");
    }
    return [];
  }

  // Hàm giải mã ngược tọa độ sang địa chỉ sử dụng API OpenStreetMap (Có cache)
  Future<String?> _fetchAddressFromCoords(LatLng pos) async {
    // Làm tròn tọa độ đến 4 chữ số thập phân để tận dụng cache cho các vị trí cực kỳ gần nhau (~11m)
    final cacheKey = '${pos.latitude.toStringAsFixed(4)},${pos.longitude.toStringAsFixed(4)}';
    if (_reverseGeocodeCache.containsKey(cacheKey)) {
      return _reverseGeocodeCache[cacheKey];
    }

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?lat=${pos.latitude}&lon=${pos.longitude}&format=json'
    );
    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'TourXport/1.0 (com.example.tourxport; Flutter)',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map) {
          final displayName = data['display_name'] as String?;
          if (displayName != null) {
            _reverseGeocodeCache[cacheKey] = displayName;
          }
          return displayName;
        }
      }
    } catch (e) {
      print("Lỗi giải mã ngược GPS: $e");
    }
    return null;
  }



  // Khởi động lắng nghe di chuyển GPS theo thời gian thực (Có debounce 3 giây)
  void _startTracking() {
    _positionStreamSubscription?.cancel(); // Hủy stream cũ nếu có để tránh nghe trùng lặp
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15, // Kích hoạt mỗi khi di chuyển tối thiểu 15 mét
      ),
    ).listen((Position position) {
      LatLng currentPos = LatLng(position.latitude, position.longitude);
      _gpsDebounceTimer?.cancel();
      _gpsDebounceTimer = Timer(const Duration(seconds: 3), () {
        _checkIfOffRoute(currentPos);
      });
    }, onError: (error) {
      print("Lỗi luồng định vị GPS: $error");
    });
  }

  // Thuật toán kiểm tra người dùng đi lệch đường (Đã được tách biệt logic sang NavigationHelper)
  void _checkIfOffRoute(LatLng currentPos) {
    if (_routePoints.isEmpty || _isRecalculating) return;

    final isOff = NavigationHelper.isOffRoute(currentPos, _routePoints);
    if (isOff) {
      print("Người dùng đi sai đường! Kích hoạt tính toán lại lộ trình.");
      _isRecalculating = true; // Thiết lập trước để khóa không cho các sự kiện tiếp theo chạy trùng lặp
      _recalculateRoute(currentPos);
    }
  }

  // Tự động tính toán lại tuyến đường đi từ vị trí mới
  Future<void> _recalculateRoute(LatLng currentPos) async {
    _isRecalculating = true;

    try {
      // Thông báo nhanh cho người dùng biết
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Bạn đã đi lệch hướng. Đang tự động tìm đường đi mới...",
            style: TextStyle(fontFamily: 'Montserrat', color: Colors.white),
          ),
          backgroundColor: Color(0xFFB5956A),
          duration: Duration(seconds: 3),
        ),
      );

      final endLocation = LatLng(widget.destination.latitude, widget.destination.longitude);
      
      // Gọi API tìm tuyến đường mới
      final routeResult = await RoutingService.getRoute(currentPos, endLocation, profile: _selectedProfile);
      // Gọi API giải mã địa chỉ của vị trí mới
      final newAddress = await _fetchAddressFromCoords(currentPos);

      if (mounted) {
        setState(() {
          _userLocation = currentPos;
          _gpsAddress = newAddress;
          _manualStartLocationName = null; // Đảm bảo hiển thị địa chỉ GPS mới
          if (routeResult.points.isNotEmpty) {
            _routePoints = routeResult.points;
            _routeDistanceKm = routeResult.distanceKm;
            _routeDurationMin = routeResult.durationMinutes;
          }
        });
        
        // Tự động zoom vừa vặn đường đi mới
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fitMapBounds();
        });
      }
    } catch (e) {
      print("Lỗi tính toán lại đường đi: $e");
    } finally {
      _isRecalculating = false;
    }
  }

  // Giả lập đi sai đường phục vụ kiểm thử (Simulate Off-Route)
  void _simulateOffRoute() {
    if (_routePoints.isEmpty) {
      _showWarning("Chưa có tuyến đường để mô phỏng đi lệch hướng.");
      return;
    }

    // Khôi phục trạng thái tính toán lại phòng trường hợp bị treo ở lần bấm trước do lỗi mạng
    _isRecalculating = false;

    // Lấy một điểm trung gian trong tuyến đường
    final idx = _routePoints.length ~/ 2;
    final referencePoint = _routePoints[idx];

    // Tính toán vector hướng của đoạn đường để tạo độ lệch vuông góc (perpendicular shift)
    LatLng nextPoint;
    if (idx + 1 < _routePoints.length) {
      nextPoint = _routePoints[idx + 1];
    } else if (idx - 1 >= 0) {
      nextPoint = _routePoints[idx - 1];
    } else {
      nextPoint = LatLng(referencePoint.latitude + 0.001, referencePoint.longitude);
    }

    final double dLat = nextPoint.latitude - referencePoint.latitude;
    final double dLon = nextPoint.longitude - referencePoint.longitude;

    // Vector vuông góc (perpendicular vector)
    double pLat = -dLon;
    double pLon = dLat;

    final double dist = dLat.abs() + dLon.abs();
    if (dist > 0) {
      pLat = (pLat / dist) * 0.0022; // Dịch chuyển vuông góc khoảng 240m để chắc chắn lệch ngoài 55m
      pLon = (pLon / dist) * 0.0022;
    } else {
      pLat = 0.0022;
      pLon = 0.0022;
    }

    final simulatedLatLng = LatLng(
      referencePoint.latitude + pLat,
      referencePoint.longitude + pLon,
    );

    print("--- [DEBUG] Bắt đầu mô phỏng đi lệch hướng ---");
    print("Tọa độ gốc trên đường đi: ${referencePoint.latitude}, ${referencePoint.longitude}");
    print("Tọa độ giả lập đi sai đường: ${simulatedLatLng.latitude}, ${simulatedLatLng.longitude}");

    // Kích hoạt hàm kiểm tra với vị trí giả lập
    _checkIfOffRoute(simulatedLatLng);
  }

  // Hiển thị popup nhập địa điểm thủ công với chức năng tự động gợi ý
  void _showManualLocationDialog() {
    final TextEditingController addressController = TextEditingController();
    List<Map<String, dynamic>> suggestions = [];
    bool isSearching = false;
    bool hasSearched = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AlertDialog(
            backgroundColor: const Color(0xFF0F1E1B).withValues(alpha: 0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
            ),
            title: const Row(
              children: [
                Icon(Icons.edit_location_alt_rounded, color: Color(0xFFD4AF7A), size: 26),
                SizedBox(width: 12),
                Text(
                  'Nhập vị trí của bạn',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 320, // Giới hạn chiều rộng cố định để dialog ổn định
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: addressController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontFamily: 'Montserrat'),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (value) async {
                      final query = value.trim();
                      if (query.isEmpty) return;
                      setDialogState(() {
                        isSearching = true;
                        hasSearched = true;
                        suggestions = [];
                      });
                      final list = await _fetchAddressSuggestions(query);
                      setDialogState(() {
                        suggestions = list;
                        isSearching = false;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Trường Đại Học Khoa Học Tự Nhiên...',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontFamily: 'Montserrat'),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search_rounded, color: Color(0xFFD4AF7A)),
                        onPressed: () async {
                          final query = addressController.text.trim();
                          if (query.isEmpty) return;
                          setDialogState(() {
                            isSearching = true;
                            hasSearched = true;
                            suggestions = [];
                          });
                          final list = await _fetchAddressSuggestions(query);
                          setDialogState(() {
                            suggestions = list;
                            isSearching = false;
                          });
                        },
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFD4AF7A)),
                      ),
                    ),
                  ),
                  if (isSearching) ...[
                    const SizedBox(height: 16),
                    const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF7A)),
                      ),
                    ),
                  ] else if (hasSearched && suggestions.isEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Không tìm thấy địa điểm nào phù hợp. Vui lòng nhập chi tiết hơn.',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ] else if (suggestions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Chọn địa điểm chính xác từ gợi ý:',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 180),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: suggestions.length,
                        separatorBuilder: (context, index) => Divider(
                          color: Colors.white.withValues(alpha: 0.08),
                          height: 1,
                        ),
                        itemBuilder: (context, index) {
                          final item = suggestions[index];
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            title: Text(
                              item['display_name'] as String,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            leading: const Icon(Icons.location_on_rounded, color: Color(0xFFD4AF7A), size: 16),
                            onTap: () async {
                              Navigator.pop(context); // Đóng Dialog

                              setState(() {
                                _isLoading = true;
                              });

                              final endLocation = LatLng(
                                widget.destination.latitude,
                                widget.destination.longitude,
                              );
                              final routeResult = await RoutingService.getRoute(
                                item['latlng'] as LatLng,
                                endLocation,
                                profile: _selectedProfile,
                              );

                              setState(() {
                                _userLocation = item['latlng'] as LatLng;
                                _routePoints = routeResult.points;
                                _routeDistanceKm = routeResult.distanceKm;
                                _routeDurationMin = routeResult.durationMinutes;
                                _manualStartLocationName = item['display_name'] as String;
                                _isLoading = false;
                              });

                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _fitMapBounds();
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Hủy',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: isSearching
                    ? null
                    : () async {
                        final query = addressController.text.trim();
                        if (query.isEmpty) return;

                        setDialogState(() {
                          isSearching = true;
                          hasSearched = true;
                          suggestions = [];
                        });
                        final list = await _fetchAddressSuggestions(query);
                        setDialogState(() {
                          suggestions = list;
                          isSearching = false;
                        });
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF7A),
                  foregroundColor: const Color(0xFF0F1E1B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text(
                  'Tìm kiếm',
                  style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Future<bool> _showLocationExplanationDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF0F1E1B).withValues(alpha: 0.9), // Xanh đen đồng bộ app
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.12), // Viền kính mờ
              width: 1.5,
            ),
          ),
          title: Row(
            children: [
              const Icon(Icons.location_on_rounded, color: Color(0xFFD4AF7A), size: 28),
              const SizedBox(width: 12),
              const Text(
                'Dịch vụ vị trí',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          content: const Text(
            'TourXport cần quyền vị trí của bạn để định vị và tính toán tuyến đường đi tối ưu nhất đến điểm du lịch.',
            style: TextStyle(
              fontFamily: 'Montserrat',
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Bỏ qua',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF7A), // Màu vàng gold sang trọng
                foregroundColor: const Color(0xFF0F1E1B), // Chữ tối màu tương phản tốt
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                elevation: 0,
              ),
              child: const Text(
                'Đồng ý',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    ) ?? false;
  }

  Widget _buildMobileTabButton({
    required bool isActive,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? const Color(0xFFB5956A) : Colors.white.withValues(alpha: 0.08),
        foregroundColor: isActive ? Colors.white : Colors.white.withValues(alpha: 0.4),
        elevation: 0,
        minimumSize: const Size(125, 42), // Đặt kích thước tối thiểu để hai nút to bằng nhau
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBannerContent() {
    return MapWarningBanner(
      manualStartLocationName: _manualStartLocationName,
      onDismiss: () => setState(() => _showLocationWarningBanner = false),
      onManualInputTap: _showManualLocationDialog,
      onEnableGPSTap: () {
        setState(() {
          _isLoading = true;
          _showLocationWarningBanner = false;
        });
        _fetchLocationAndRoute();
      },
    );
  }

  Widget _buildRouteMetricsFloatingCard() {
    return RouteMetricsCard(
      routeDurationMin: _routeDurationMin,
      routeDistanceKm: _routeDistanceKm,
      onClose: () => setState(() => _showRouteMetricsCard = false),
    );
  }







  Future<void> _fetchLocationAndRoute() async {


    LatLng startLocation = _fallbackStart;
    bool hasGPS = false;

    try {
      // 1. Kiểm tra Dịch vụ Vị trí (Location Services)
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        // 2. Kiểm tra quyền hiện tại trước khi hiển thị dialog giải thích
        LocationPermission permission = await Geolocator.checkPermission();
        
        // Thêm dòng này để test:
        permission = LocationPermission.denied; 

        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
          // Quyền đã được cấp trước đó, lấy thẳng vị trí GPS
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 5),
          );
          startLocation = LatLng(position.latitude, position.longitude);
          hasGPS = true;
        } else if (permission == LocationPermission.deniedForever) {
          // Bị từ chối vĩnh viễn, hướng dẫn bật trong cài đặt
          _showLocationWarningBanner = true;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  "Quyền định vị bị từ chối vĩnh viễn. Vui lòng bật lại trong Cài đặt để định vị GPS.",
                  style: TextStyle(fontFamily: 'Montserrat', color: Colors.white),
                ),
                backgroundColor: Colors.redAccent,
                duration: const Duration(seconds: 6),
                action: SnackBarAction(
                  label: "Cài đặt",
                  textColor: Colors.white,
                  onPressed: () async {
                    await Geolocator.openAppSettings();
                  },
                ),
              ),
            );
          }
        } else {
          // Chưa được cấp quyền, hỏi ý kiến trước bằng dialog giải thích
          final shouldRequest = await _showLocationExplanationDialog();
          if (shouldRequest) {
            permission = await Geolocator.requestPermission();
            if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
              Position position = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.high,
                timeLimit: const Duration(seconds: 5),
              );
              startLocation = LatLng(position.latitude, position.longitude);
              hasGPS = true;
            } else if (permission == LocationPermission.deniedForever) {
              _showLocationWarningBanner = true;
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      "Quyền định vị bị chặn vĩnh viễn. Hãy bật lại trong Cài đặt thiết bị.",
                      style: TextStyle(fontFamily: 'Montserrat', color: Colors.white),
                    ),
                    backgroundColor: Colors.redAccent,
                    duration: const Duration(seconds: 6),
                    action: SnackBarAction(
                      label: "Cài đặt",
                      textColor: Colors.white,
                      onPressed: () async {
                        await Geolocator.openAppSettings();
                      },
                    ),
                  ),
                );
              }
            } else {
              _showLocationWarningBanner = true;
            }
          } else {
            _showLocationWarningBanner = true;
          }
        }
      } else {
        // Dịch vụ vị trí bị tắt trên điện thoại
        _showLocationWarningBanner = true;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                "Dịch vụ vị trí (GPS) đang tắt. Vui lòng bật GPS trên thiết bị.",
                style: TextStyle(fontFamily: 'Montserrat', color: Colors.white),
              ),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: "Bật GPS",
                textColor: Colors.white,
                onPressed: () async {
                  await Geolocator.openLocationSettings();
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      print("Không lấy được vị trí GPS: $e");
    }

    String? fetchedAddress;
    if (hasGPS) {
      fetchedAddress = await _fetchAddressFromCoords(startLocation);
    }

    final endLocation = LatLng(widget.destination.latitude, widget.destination.longitude);

    // 4. Lấy dữ liệu tuyến đường từ Routing Service
    final routeResult = await RoutingService.getRoute(startLocation, endLocation, profile: _selectedProfile);

    if (mounted) {
      setState(() {
        if (hasGPS) {
          _userLocation = startLocation;
          _gpsAddress = fetchedAddress; // Save the reverse geocoded address
          _manualStartLocationName = null; // Reset manual starting location when GPS becomes active
          // Tắt banner khi có GPS
          _showLocationWarningBanner = false;
        } else {
          // Giữ nguyên banner nếu không có GPS
          _showLocationWarningBanner = true;
        }
        _routePoints = routeResult.points;
        _routeDistanceKm = routeResult.distanceKm;
        _routeDurationMin = routeResult.durationMinutes;
        _isLoading = false;
      });
      
      if (hasGPS) {
        _startTracking(); // Bắt đầu lắng nghe thời gian thực khi có GPS thành công!
      }
      
      // Tự động căn chỉnh bản đồ vừa vặn tuyến đường mới
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitMapBounds();
      });

      if (!hasGPS) {
        _showWarning("Không thể định vị vị trí hiện tại. Bản đồ đang hiển thị đường đi từ Hà Nội.");
      } else if (routeResult.points.isEmpty) {
        _showWarning("Không thể tính toán tuyến đường đi từ vị trí của bạn.");
      }
    }
  }

  void _showWarning(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontFamily: 'Montserrat', color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _fitMapBounds() {
    if (_routePoints.isEmpty) return;
    
    // Tìm các giới hạn của tuyến đường
    double minLat = _routePoints[0].latitude;
    double maxLat = _routePoints[0].latitude;
    double minLon = _routePoints[0].longitude;
    double maxLon = _routePoints[0].longitude;

    for (var point in _routePoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLon) minLon = point.longitude;
      if (point.longitude > maxLon) maxLon = point.longitude;
    }

    // Zoom vừa vặn đường đi với khoảng đệm
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(LatLng(minLat, minLon), LatLng(maxLat, maxLon)),
        padding: const EdgeInsets.all(50.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final destLocation = LatLng(widget.destination.latitude, widget.destination.longitude);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: isDesktop
          ? null // Hide AppBar on desktop since we have a dedicated sidebar back button!
          : AppBar(
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(
                'Đường đi đến ${widget.destination.name}',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              elevation: 0,
              backgroundColor: const Color(0xFF1E1E1E),
              centerTitle: true,
              actions: [
                if (_routePoints.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.zoom_out_map_rounded, color: Color(0xFFD4AF7A)),
                    tooltip: 'Xem toàn bộ đường đi',
                    onPressed: _fitMapBounds,
                  ),
              ],
            ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF7A)),
              ),
            )
          : (isDesktop
              ? _buildDesktopBody(destLocation)
              : _buildMobileBody(destLocation)),
    );
  }

  Widget _buildMobileBody(LatLng destLocation) {
    String titleText = '';
    String subtitleText = '';

    if (_activeMobileTab == 0) {
      titleText = widget.destination.name;
      subtitleText = 'Tỉnh/Thành: ${widget.destination.province}';
    } else {
      final String? fullAddress = _manualStartLocationName ?? _gpsAddress;
      if (fullAddress != null) {
        final split = NavigationHelper.splitAddress(fullAddress);
        titleText = split['title']!;
        subtitleText = split['subtitle']!; // Bỏ qua chữ định vị GPS / vị trí tự nhập
      } else {
        titleText = _userLocation != null ? 'Vị trí của tôi' : 'Hà Nội (Mặc định)';
        subtitleText = ''; // Bỏ qua trạng thái "Định vị GPS hoạt động"
      }
    }

    return Stack(
      children: [
        _buildMapWidget(destLocation),
        // Positioned bottom card
        Positioned(
          bottom: 24,
          left: 20,
          right: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_showLocationCard) 
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Thanh kéo và nút đóng ở trên cùng
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const SizedBox(width: 28), // Cân bằng với nút đóng
                                  Center(
                                    child: Container(
                                      width: 36,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => setState(() => _showLocationCard = false),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.close_rounded,
                                        color: Colors.white.withValues(alpha: 0.4),
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Nội dung chính
                              Row(
                                children: [
                                  // Cột chữ bên trái
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          titleText,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          subtitleText,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontSize: 12,
                                            color: Colors.white.withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      _buildMobileTabButton(
                                        isActive: _activeMobileTab == 0,
                                        icon: Icons.location_searching_rounded,
                                        label: 'Điểm đến',
                                        onTap: () {
                                          setState(() => _activeMobileTab = 0);
                                          _mapController.move(destLocation, 14.5);
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      _buildMobileTabButton(
                                        isActive: _activeMobileTab == 1,
                                        icon: Icons.my_location_rounded,
                                        label: 'Điểm đi',
                                        onTap: () {
                                          setState(() => _activeMobileTab = 1);
                                          final startLoc = _userLocation ?? _fallbackStart;
                                          _mapController.move(startLoc, 14.5);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                // Pill thu gọn — nhấn để mở lại
                GestureDetector(
                  onTap: () => setState(() => _showLocationCard = true),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.70),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.13),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _activeMobileTab == 0
                                  ? Icons.location_searching_rounded
                                  : Icons.my_location_rounded,
                              color: const Color(0xFFD4AF7A),
                              size: 16,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                titleText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.expand_less_rounded,
                              color: Colors.white.withValues(alpha: 0.45),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLocationCard({
    required String header,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            header,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD4AF7A),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white60, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    color: Colors.white60,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopBody(LatLng destLocation) {
    // Xác định thông tin Điểm đi để hiển thị trên Desktop
    final String? fullAddress = _manualStartLocationName ?? _gpsAddress;
    String startTitle = '';
    String startSubtitle = '';
    if (fullAddress != null) {
      final split = NavigationHelper.splitAddress(fullAddress);
      startTitle = split['title']!;
      startSubtitle = split['subtitle']!; // Bỏ qua chữ định vị GPS / vị trí tự nhập
    } else {
      startTitle = _userLocation != null ? 'Vị trí của tôi' : 'Hà Nội (Mặc định)';
      startSubtitle = ''; // Bỏ qua trạng thái "Định vị GPS hoạt động"
    }

    return Row(
      children: [
        // Left Panel: Route information and Controls
        Container(
          width: 360,
          color: const Color(0xFF0F1E1B),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button & Title
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Bản đồ đường đi',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Summary Card hiển thị thông tin vị trí (Điểm đi / Điểm đến)
              if (_activeMobileTab == 2) ...[
                _buildDesktopLocationCard(
                  header: 'ĐIỂM ĐI',
                  title: startTitle,
                  subtitle: startSubtitle,
                ),
                const SizedBox(height: 12),
                _buildDesktopLocationCard(
                  header: 'ĐIỂM ĐẾN',
                  title: widget.destination.name,
                  subtitle: widget.destination.province,
                ),
              ] else if (_activeMobileTab == 1) ...[
                _buildDesktopLocationCard(
                  header: 'ĐIỂM ĐI',
                  title: startTitle,
                  subtitle: startSubtitle,
                ),
              ] else ...[
                _buildDesktopLocationCard(
                  header: 'ĐIỂM ĐẾN',
                  title: widget.destination.name,
                  subtitle: widget.destination.province,
                ),
              ],
              const SizedBox(height: 24),

              // Actions Header
              const Text(
                'ĐIỀU KHIỂN BẢN ĐỒ',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white54,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),

              // Quick action buttons
              _desktopActionBtn(
                icon: Icons.zoom_out_map_rounded,
                label: 'Xem toàn bộ đường đi',
                onTap: () {
                  setState(() => _activeMobileTab = 2);
                  _fitMapBounds();
                },
                enabled: _routePoints.isNotEmpty,
                isActive: _activeMobileTab == 2,
              ),
              const SizedBox(height: 10),
              _desktopActionBtn(
                icon: Icons.location_searching_rounded,
                label: 'Đến vị trí điểm đến',
                onTap: () {
                  setState(() => _activeMobileTab = 0);
                  _mapController.move(destLocation, 14.5);
                },
                enabled: true,
                isActive: _activeMobileTab == 0,
              ),
              const SizedBox(height: 10),
              _desktopActionBtn(
                icon: Icons.my_location_rounded,
                label: 'Đến vị trí của tôi',
                onTap: () {
                  setState(() => _activeMobileTab = 1);
                  final startLoc = _userLocation ?? _fallbackStart;
                  _mapController.move(startLoc, 14.5);
                },
                enabled: true,
                isActive: _activeMobileTab == 1,
              ),
              const Spacer(),

              // Route Info detail
              if (_routePoints.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D6A4F).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2D6A4F).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF2D6A4F), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('Tuyến đường tối ưu đã được tính toán từ OSRM.',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Right side: Map
        Expanded(
          child: _buildMapWidget(destLocation),
        ),
      ],
    );
  }

  Widget _desktopActionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool enabled,
    bool isActive = false,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Material(
        color: isActive 
            ? const Color(0xFFB5956A)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          hoverColor: isActive 
              ? const Color(0xFFB5956A).withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon, 
                  color: isActive ? Colors.white : const Color(0xFFD4AF7A), 
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapWidget(LatLng destLocation) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: destLocation,
            initialZoom: 12.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.tourxport',
            ),
            
            // Vẽ tuyến đường
            if (_routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 5.5,
                    color: const Color(0xFFB5956A),
                    borderColor: Colors.black.withValues(alpha: 0.3),
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),
            
            // Đánh dấu các địa điểm
            MarkerLayer(
              markers: [
                // Ghim Vị trí Người dùng
                if (_userLocation != null)
                  Marker(
                    point: _userLocation!,
                    width: 50,
                    height: 50,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blueAccent,
                                blurRadius: 6,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Ghim Vị trí Điểm đến
                Marker(
                  point: destLocation,
                  width: 55,
                  height: 55,
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Colors.redAccent,
                    size: 42,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Thêm Banner kính mờ ở phía trên cùng của bản đồ + thẻ thông số tuyến đường
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_showLocationWarningBanner) ...[
                _buildWarningBannerContent(),
                const SizedBox(height: 10),
              ],
              if (_showRouteMetricsCard && _routePoints.isNotEmpty && (_routeDistanceKm > 0 || _routeDurationMin > 0)) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildRouteMetricsFloatingCard(),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Nút mở lại thẻ thông số (hiện khi đã đóng card)
        if (!_showRouteMetricsCard && _routePoints.isNotEmpty && (_routeDistanceKm > 0 || _routeDurationMin > 0))
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => setState(() => _showRouteMetricsCard = true),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1E1B).withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.directions_car_rounded, color: Color(0xFFD4AF7A), size: 15),
                          const SizedBox(width: 6),
                          Text(
                            '${_routeDurationMin.toStringAsFixed(0)} phút • ${_routeDistanceKm.toStringAsFixed(1).replaceAll('.', ',')} km',
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.expand_more_rounded,
                            color: Colors.white.withValues(alpha: 0.5),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Nút Debug giả lập đi sai đường (Chỉ hiển thị ở chế độ Debug)
        if (kDebugMode && _routePoints.isNotEmpty)
          Positioned(
            right: 20,
            bottom: 260,
            child: FloatingActionButton.small(
              heroTag: 'debug_rerouting_fab',
              backgroundColor: const Color(0xFFD4AF7A),
              foregroundColor: const Color(0xFF0F1E1B),
              tooltip: 'Mô phỏng đi sai đường (Debug)',
              onPressed: _simulateOffRoute,
              child: const Icon(Icons.bug_report_rounded, size: 20),
            ),
          ),
      ],
    );
  }
}
