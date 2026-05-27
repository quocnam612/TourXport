import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/destination.dart';
import '../utils/routing_service.dart';
import '../utils/navigation_helper.dart';
import '../widgets/map_warning_banner.dart';
import '../widgets/route_metrics_card.dart';
import '../widgets/location_explanation_dialog.dart';
import '../widgets/manual_location_dialog.dart';
import '../widgets/tour_map_widget.dart';
import '../widgets/map_desktop_view.dart';
import '../widgets/map_mobile_view.dart';

class MapScreen extends StatefulWidget {
  final Destination destination;

  const MapScreen({
    super.key,
    required this.destination,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  LatLng? _userLocation;
  List<LatLng> _routePoints = [];
  bool _isLoading = true;
  final MapController _mapController = MapController();
  
  // Vị trí mặc định nếu không lấy được GPS (Ví dụ: Hà Nội)
  static const LatLng _fallbackStart = LatLng(21.0285, 105.8542);

  @override
  void initState() {
    super.initState();
    _fetchLocationAndRoute();
  }

  // TỐI ƯU: Thay thế _gpsDebounceTimer bằng cơ chế Throttling dựa trên thời gian thực (_lastRouteCheckTime)
  // để khắc phục lỗi không thể kiểm tra lệch tuyến (off-route) khi đang di chuyển liên tục.
  DateTime? _lastRouteCheckTime; 
  final Map<String, List<Map<String, dynamic>>> _suggestionsCache = {}; // Cache gợi ý tìm kiếm địa chỉ
  final Map<String, String> _reverseGeocodeCache = {}; // Cache giải mã tọa độ ngược
  Timer? _movementSimulationTimer; // Timer mô phỏng di chuyển dọc đường đi
  AnimationController? _cameraAnimationController; // Quản lý tập trung hoạt ảnh di chuyển camera

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _movementSimulationTimer?.cancel();
    _cameraAnimationController?.dispose(); // Giải phóng controller camera
    _suggestionsCache.clear();
    _reverseGeocodeCache.clear();
    super.dispose();
  }

  String? _manualStartLocationName; // Lưu tên vị trí người dùng tự nhập
  String? _gpsAddress; // Lưu địa chỉ đã được giải mã từ GPS
  int _activeMobileTab = 0; // 0: Đang chọn Xem Điểm đến, 1: Đang chọn Xem Điểm đi, 2: Xem toàn bộ đường đi (bản web)
  double _routeDistanceKm = 0.0; // Lưu khoảng cách tuyến đường (km)
  double _routeDurationMin = 0.0; // Lưu thời gian di chuyển dự kiến (phút)
  double _initialRouteDistanceKm = 0.0; // Khoảng cách tuyến đường ban đầu nhận từ OSRM
  double _initialRouteDurationMin = 0.0; // Thời gian di chuyển dự kiến ban đầu nhận từ OSRM
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
      debugPrint("Lỗi lấy danh sách gợi ý: $e");
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
      debugPrint("Lỗi giải mã ngược GPS: $e");
    }
    return null;
  }

  // Khởi động lắng nghe di chuyển GPS theo thời gian thực (Có throttling 5 giây & cập nhật Marker thực tế)
  void _startTracking() {
    _positionStreamSubscription?.cancel(); // Hủy stream cũ nếu có để tránh nghe trùng lặp
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Di chuyển tối thiểu 10 mét sẽ cập nhật để vẽ marker mượt hơn
      ),
    ).listen((Position position) {
      if (!mounted) return;
      
      final currentPos = LatLng(position.latitude, position.longitude);
      
      // SỬA LỖI LOGIC: Cập nhật vị trí người dùng tức thời lên giao diện (để Marker chấm xanh dương di chuyển theo xe)
      setState(() {
        _userLocation = currentPos;
      });
      _updateRemainingMetrics(currentPos);

      // SỬA LỖI LOGIC: Thay debounce bằng throttle 5 giây. Nếu dùng debounce, mỗi lần người dùng di chuyển
      // timer sẽ bị hủy và tạo lại -> khi di chuyển liên tục, hàm kiểm tra lệch đường sẽ KHÔNG BAO GIỜ được gọi.
      final now = DateTime.now();
      if (_lastRouteCheckTime == null || now.difference(_lastRouteCheckTime!) >= const Duration(seconds: 5)) {
        _lastRouteCheckTime = now;
        _checkIfOffRoute(currentPos);
      }
    }, onError: (error) {
      debugPrint("Lỗi luồng định vị GPS: $error");
    });
  }

  // Thuật toán kiểm tra người dùng đi lệch đường (Đã được tách biệt logic sang NavigationHelper)
  void _checkIfOffRoute(LatLng currentPos) {
    if (_routePoints.isEmpty || _isRecalculating) return;

    final isOff = NavigationHelper.isOffRoute(currentPos, _routePoints);
    if (isOff) {
      debugPrint("Người dùng đi sai đường! Kích hoạt tính toán lại lộ trình.");
      _recalculateRoute(currentPos);
    }
  }

  // Tự động tính toán lại tuyến đường đi từ vị trí mới
  Future<void> _recalculateRoute(LatLng currentPos) async {
    // SỬA LỖI BẢO MẬT: Kiểm tra mounted để tránh crash do sử dụng BuildContext (như ScaffoldMessenger) sau khi widget đã bị hủy.
    if (!mounted) return;
    
    _isRecalculating = true;

    try {
      // Thông báo nhanh cho người dùng biết, dọn các thông báo cũ để tránh chồng chéo
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
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

      if (mounted) {
        setState(() {
          _userLocation = currentPos;
          _gpsAddress = null; // Xóa địa chỉ cũ để hiển thị "Đang xác định địa chỉ..."
          _manualStartLocationName = null; // Đảm bảo hiển thị địa chỉ GPS mới
          
          if (routeResult.points.isNotEmpty) {
            _routePoints = routeResult.points;
            _routeDistanceKm = routeResult.distanceKm;
            _routeDurationMin = routeResult.durationMinutes;
            _initialRouteDistanceKm = routeResult.distanceKm;
            _initialRouteDurationMin = routeResult.durationMinutes;
          } else {
            // SỬA LỖI LOGIC: Khi OSRM lỗi/không tìm được đường, nếu không xử lý, _routePoints vẫn giữ giá trị cũ.
            // Khi đó vị trí của người dùng hiện đã lệch so với _routePoints cũ, gây ra vòng lặp vô hạn recalculate.
            // Ta thông báo và tăng cooldown của lần kiểm tra tiếp theo.
            _lastRouteCheckTime = DateTime.now().add(const Duration(seconds: 15)); // Cool-down 15 giây
            _showWarning("Không thể tính toán lại lộ trình từ vị trí hiện tại.");
          }
        });
        
        // Tự động zoom vừa vặn đường đi mới
        if (routeResult.points.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fitMapBounds();
          });
        }
      }

      if (routeResult.points.isNotEmpty) {
        // Gọi API giải mã địa chỉ của vị trí mới một cách bất đồng bộ không chặn vẽ tuyến đường
        _fetchAddressFromCoords(currentPos).then((newAddress) {
          if (mounted && newAddress != null) {
            setState(() {
              _gpsAddress = newAddress;
            });
          }
        });
      }
    } catch (e) {
      debugPrint("Lỗi tính toán lại đường đi: $e");
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

    debugPrint("--- [DEBUG] Bắt đầu mô phỏng đi lệch hướng ---");
    debugPrint("Tọa độ gốc trên đường đi: ${referencePoint.latitude}, ${referencePoint.longitude}");
    debugPrint("Tọa độ giả lập đi sai đường: ${simulatedLatLng.latitude}, ${simulatedLatLng.longitude}");

    // Kích hoạt hàm kiểm tra với vị trí giả lập
    _checkIfOffRoute(simulatedLatLng);
  }

  // Debug: Bật/Tắt chế độ mô phỏng di chuyển dọc theo tuyến đường đi thực tế
  void _toggleSimulation() {
    if (_movementSimulationTimer != null && _movementSimulationTimer!.isActive) {
      _movementSimulationTimer?.cancel();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đã dừng mô phỏng di chuyển. Khôi phục định vị GPS thật...",
            style: TextStyle(fontFamily: 'Montserrat', color: Colors.white)),
          backgroundColor: Color(0xFF0F1E1B),
          duration: Duration(seconds: 2),
        ),
      );
      _startTracking(); // Khởi chạy lại định vị thực tế
      setState(() {}); // Để cập nhật icon Play/Pause
    } else {
      if (_routePoints.isEmpty) {
        _showWarning("Chưa có tuyến đường được vẽ để mô phỏng.");
        return;
      }
      
      _positionStreamSubscription?.cancel(); // Tạm tắt stream GPS thật
      double simulationIndex = 0.0;
      
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bắt đầu mô phỏng di chuyển tự động...",
            style: TextStyle(fontFamily: 'Montserrat', color: Colors.white)),
          backgroundColor: Color(0xFFB5956A),
          duration: Duration(seconds: 2),
        ),
      );

      _movementSimulationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (simulationIndex >= _routePoints.length) {
          timer.cancel();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Đã đi hết tuyến đường mô phỏng!",
                style: TextStyle(fontFamily: 'Montserrat', color: Colors.white)),
              backgroundColor: Color(0xFF2D6A4F),
            ),
          );
          _startTracking(); // Bật lại GPS thật
          setState(() {});
          return;
        }

        final simulatedPos = _routePoints[simulationIndex.toInt()];
        setState(() {
          _userLocation = simulatedPos;
        });
        _updateRemainingMetrics(simulatedPos);

        // Di chuyển camera bản đồ mượt mà theo chấm xanh
        _animatedMapMove(simulatedPos, _mapController.camera.zoom);

        // Kiểm tra đi lệch đường (ở đây đi dọc theo tuyến nên chắc chắn không lệch)
        _checkIfOffRoute(simulatedPos);

        // Tăng bước di chuyển (Nhảy 3 điểm để mô phỏng đi nhanh hơn)
        simulationIndex += 0.3;
      });
      setState(() {}); // Cập nhật icon sang Pause
    }
  }

  // Hiển thị popup nhập địa điểm thủ công với chức năng tự động gợi ý
  void _showManualLocationDialog() {
    showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ManualLocationDialog(
        fetchSuggestions: _fetchAddressSuggestions,
      ),
    ).then((item) async {
      if (item != null) {
        // Chỉ gọi setState khi widget vẫn còn tồn tại trên màn hình
        if (mounted) {
          setState(() {
            _isLoading = true;
          });
        }

        final endLocation = LatLng(
          widget.destination.latitude,
          widget.destination.longitude,
        );
        final routeResult = await RoutingService.getRoute(
          item['latlng'] as LatLng,
          endLocation,
          profile: _selectedProfile,
        );

        if (mounted) {
          setState(() {
            _userLocation = item['latlng'] as LatLng;
            _routePoints = routeResult.points;
            _routeDistanceKm = routeResult.distanceKm;
            _routeDurationMin = routeResult.durationMinutes;
            _initialRouteDistanceKm = routeResult.distanceKm;
            _initialRouteDurationMin = routeResult.durationMinutes;
            _manualStartLocationName = item['display_name'] as String;
            _gpsAddress = null; // Clear GPS address to avoid state conflicts
            _isLoading = false;
          });

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fitMapBounds();
          });
        }
      }
    });
  }

  Future<bool> _showLocationExplanationDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LocationExplanationDialog(),
    ) ?? false;
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
        // 2. Kiểm tra & Yêu cầu Quyền truy cập
        LocationPermission permission = await Geolocator.checkPermission();

        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
          // 3. Lấy vị trí GPS hiện tại (thêm timeLimit 5 giây để tránh treo vô hạn)
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 5),
          );
          startLocation = LatLng(position.latitude, position.longitude);
          hasGPS = true;
        }
      }
    } catch (e) {
      debugPrint("Không lấy được vị trí GPS: $e");
    }

    // TỐI ƯU BẢO MẬT: Kiểm tra mounted trước khi gọi API mạng RoutingService để tránh lãng phí tài nguyên và lỗi trạng thái
    if (!mounted) return;

    final endLocation = LatLng(widget.destination.latitude, widget.destination.longitude);

    // 4. Lấy dữ liệu tuyến đường từ Routing Service
    final points = await RoutingService.getRoute(startLocation, endLocation);

    if (mounted) {
      setState(() {
        if (hasGPS) {
          _userLocation = startLocation;
          _gpsAddress = null; // Reset địa chỉ cũ để hiển thị "Đang xác định địa chỉ..."
          _manualStartLocationName = null; // Reset vị trí thủ công khi GPS hoạt động
          _showLocationWarningBanner = false; // Tắt banner khi có GPS
        } else {
          _showLocationWarningBanner = true; // Giữ nguyên banner nếu không có GPS
        }
        _routePoints = routeResult.points;
        _routeDistanceKm = routeResult.distanceKm;
        _routeDurationMin = routeResult.durationMinutes;
        _initialRouteDistanceKm = routeResult.distanceKm;
        _initialRouteDurationMin = routeResult.durationMinutes;
        _isLoading = false;
      });

      if (!hasGPS) {
        _showWarning("Không thể định vị vị trí hiện tại. Bản đồ đang hiển thị đường đi từ Hà Nội.");
      } else if (points.isEmpty) {
        _showWarning("Không thể tính toán tuyến đường đi từ vị trí của bạn.");
      }
    }

    if (hasGPS) {
      _fetchAddressFromCoords(startLocation).then((fetchedAddress) {
        if (mounted && fetchedAddress != null) {
          setState(() {
            _gpsAddress = fetchedAddress;
          });
        }
      });
    }
  }

  // TỐI ƯU BẢO MẬT & TRẢI NGHIỆM: Kiểm tra mounted và ẩn snackbar hiện tại trước khi show cái mới
  void _showWarning(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
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

  // TỐI ƯU: Sử dụng LatLngBounds.fromPoints() và cameraFit.fit để di chuyển camera mượt mà
  void _fitMapBounds() {
    if (_routePoints.isEmpty) return;
    
    final cameraFit = CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(_routePoints),
      padding: const EdgeInsets.all(50.0),
    );
    final fitted = cameraFit.fit(_mapController.camera);
    _animatedMapMove(fitted.center, fitted.zoom);
  }

  // Hàm di chuyển camera bản đồ mượt mà (Animated Map Move) tránh xung đột nhiều chuyển động
  void _animatedMapMove(LatLng destLocation, double destZoom) {
    // 1. Dừng và giải phóng hoạt ảnh cũ nếu đang chạy để tránh rung giật camera
    _cameraAnimationController?.stop();
    _cameraAnimationController?.dispose();

    final camera = _mapController.camera;
    final latTween = Tween<double>(begin: camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: camera.zoom, end: destZoom);

    // 2. Gán vào biến quản lý chung
    _cameraAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    final animation = CurvedAnimation(
      parent: _cameraAnimationController!,
      curve: Curves.fastOutSlowIn,
    );

    _cameraAnimationController!.addListener(() {
      if (!mounted) return;
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    _cameraAnimationController!.forward();
  }

  // Tính toán khoảng cách và thời gian di chuyển còn lại ngoại tuyến (Client-side real-time estimation)
  // để tránh việc liên tục spam API OSRM mỗi khi chấm xanh di chuyển.
  void _updateRemainingMetrics(LatLng currentPos) {
    if (_routePoints.isEmpty || _initialRouteDistanceKm == 0.0) return;

    final metrics = NavigationHelper.calculateRemainingMetrics(
      currentPos: currentPos,
      routePoints: _routePoints,
      initialRouteDistanceKm: _initialRouteDistanceKm,
      initialRouteDurationMin: _initialRouteDurationMin,
    );

    setState(() {
      _routeDistanceKm = metrics.remainingDistanceKm;
      _routeDurationMin = metrics.remainingDurationMin;
    });
  }

  @override
  Widget build(BuildContext context) {
    final destLocation = LatLng(widget.destination.latitude, widget.destination.longitude);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    // Xác định thông tin Điểm đi để hiển thị
    final String? fullAddress = _manualStartLocationName ?? _gpsAddress;
    String startTitle = '';
    String startSubtitle = '';
    if (fullAddress != null) {
      final split = NavigationHelper.splitAddress(fullAddress);
      startTitle = split['title']!;
      startSubtitle = split['subtitle']!; // Bỏ qua chữ định vị GPS / vị trí tự nhập
    } else {
      startTitle = _userLocation != null ? 'Vị trí của tôi' : 'Hà Nội (Mặc định)';
      startSubtitle = _userLocation != null ? 'Đang xác định địa chỉ...' : '';
    }

    final mapWidget = TourMapWidget(
      destLocation: destLocation,
      userLocation: _userLocation,
      routePoints: _routePoints,
      routeDistanceKm: _routeDistanceKm,
      routeDurationMin: _routeDurationMin,
      showLocationWarningBanner: _showLocationWarningBanner,
      showRouteMetricsCard: _showRouteMetricsCard,
      isSimulating: _movementSimulationTimer != null && _movementSimulationTimer!.isActive,
      mapController: _mapController,
      warningBannerContent: _buildWarningBannerContent(),
      routeMetricsFloatingCard: _buildRouteMetricsFloatingCard(),
      onToggleRouteMetricsCard: (val) {
        setState(() {
          _showRouteMetricsCard = val;
        });
      },
      onToggleSimulation: _toggleSimulation,
      onSimulateOffRoute: _simulateOffRoute,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: isDesktop
          ? null // Ẩn AppBar trên giao diện desktop vì đã có nút quay lại tích hợp ở thanh điều khiển bên trái
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
              ? MapDesktopView(
                  destination: widget.destination,
                  destLocation: destLocation,
                  userLocation: _userLocation,
                  fallbackStart: _fallbackStart,
                  routePoints: _routePoints,
                  startTitle: startTitle,
                  startSubtitle: startSubtitle,
                  activeMobileTab: _activeMobileTab,
                  onTabChanged: (val) {
                    setState(() {
                      _activeMobileTab = val;
                    });
                  },
                  onFitMapBounds: _fitMapBounds,
                  onMoveCamera: _animatedMapMove,
                  mapWidget: mapWidget,
                )
              : MapMobileView(
                  destination: widget.destination,
                  destLocation: destLocation,
                  userLocation: _userLocation,
                  fallbackStart: _fallbackStart,
                  activeMobileTab: _activeMobileTab,
                  showLocationCard: _showLocationCard,
                  manualStartLocationName: _manualStartLocationName,
                  gpsAddress: _gpsAddress,
                  mapController: _mapController,
                  mapWidget: mapWidget,
                  onMoveCamera: _animatedMapMove,
                  onTabChanged: (val) {
                    setState(() {
                      _activeMobileTab = val;
                    });
                  },
                  onCardToggle: (val) {
                    setState(() {
                      _showLocationCard = val;
                    });
                  },
                )),
    );
  }
}
