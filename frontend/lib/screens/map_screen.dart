import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/destination.dart';
import '../utils/routing_service.dart';
import '../utils/navigation_helper.dart';
import '../widgets/map_warning_banner.dart';
import '../services/map_location_service.dart';
import '../widgets/route_metrics_card.dart';
import '../widgets/location_explanation_dialog.dart';
import '../widgets/manual_location_dialog.dart';
import '../widgets/tour_map_widget.dart';
import '../widgets/map_desktop_view.dart';
import '../widgets/map_mobile_view.dart';
import '../widgets/tour_map/states/map_loading_state.dart';

/// Dịch vụ xử lý Geocoding (Tách riêng để đảm bảo SOLID - Single Responsibility Principle)
class GeocodingService {
  static final Map<String, List<Map<String, dynamic>>> _suggestionsCache = {};
  static final Map<String, String> _reverseGeocodeCache = {};
  static const Duration _timeout = Duration(seconds: 8);

  /// Lấy danh sách địa chỉ gợi ý từ từ khóa
  static Future<List<Map<String, dynamic>>> fetchAddressSuggestions(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return [];
    if (_suggestionsCache.containsKey(cleanQuery)) return _suggestionsCache[cleanQuery]!;

    final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5');
    try {
      final response = await http.get(url, headers: _headers).timeout(_timeout);
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        final results = _parseSuggestions(data);
        _suggestionsCache[cleanQuery] = results;
        return results;
      }
    } catch (e) {
      debugPrint("Lỗi lấy danh sách gợi ý: $e");
    }
    return [];
  }

  /// Giải mã tọa độ GPS thành địa chỉ (Reverse Geocoding)
  static Future<String?> fetchAddressFromCoords(LatLng pos) async {
    final cacheKey = '${pos.latitude.toStringAsFixed(4)},${pos.longitude.toStringAsFixed(4)}';
    if (_reverseGeocodeCache.containsKey(cacheKey)) return _reverseGeocodeCache[cacheKey];

    final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=${pos.latitude}&lon=${pos.longitude}&format=json');
    try {
      final response = await http.get(url, headers: _headers).timeout(_timeout);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data['display_name'] != null) {
          final displayName = data['display_name'] as String;
          _reverseGeocodeCache[cacheKey] = displayName;
          return displayName;
        }
      }
    } catch (e) {
      debugPrint("Lỗi giải mã ngược GPS: $e");
    }
    return null;
  }

  static Map<String, String> get _headers => {
    'User-Agent': 'TourXport/1.0 (com.example.tourxport; Flutter)',
    'Accept': 'application/json',
  };

  static List<Map<String, dynamic>> _parseSuggestions(List data) {
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
    return results;
  }
}

class MapScreen extends StatefulWidget {
  final Destination destination;

  const MapScreen({
    super.key,
    required this.destination,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  static const LatLng _fallbackStart = LatLng(21.0285, 105.8542);
  static const Duration _throttleDuration = Duration(seconds: 5);

  LatLng? _userLocation;
  List<LatLng> _routePoints = [];
  bool _isLoading = true;
  
  final MapController _mapController = MapController();
  DateTime? _lastRouteCheckTime;
  int _consecutiveOffRouteCount = 0;
  
  Timer? _movementSimulationTimer;
  AnimationController? _cameraAnimationController;
  StreamSubscription<Position>? _positionStreamSubscription;
  
  bool _isRecalculating = false;
  final String _selectedProfile = 'driving';
  bool _showRouteMetricsCard = true;
  bool _showLocationCard = true;
  bool _showLocationWarningBanner = false;

  String? _manualStartLocationName;
  String? _gpsAddress;
  int _activeMobileTab = 0;
  
  double _routeDistanceKm = 0.0;
  double _routeDurationMin = 0.0;
  double _initialRouteDistanceKm = 0.0;
  double _initialRouteDurationMin = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLocationSilentlyAndRoute();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _positionStreamSubscription?.cancel();
    _movementSimulationTimer?.cancel();
    _cameraAnimationController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _userLocation == null && _manualStartLocationName == null) {
      _checkLocationSilentlyAndRoute();
    }
  }

  void _startTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(_onPositionUpdated, onError: (error) {
      debugPrint("Lỗi luồng định vị GPS: $error");
    });
  }

  void _onPositionUpdated(Position position) {
    if (!mounted) return;
    
    final currentPos = LatLng(position.latitude, position.longitude);
    
    setState(() {
      _userLocation = currentPos;
    });
    
    _updateRemainingMetrics(currentPos);

    final now = DateTime.now();
    if (_lastRouteCheckTime == null || now.difference(_lastRouteCheckTime!) >= _throttleDuration) {
      _lastRouteCheckTime = now;
      _checkIfOffRoute(currentPos);
    }
  }

  void _checkIfOffRoute(LatLng currentPos, {bool isSimulated = false}) {
    if (_routePoints.isEmpty || _isRecalculating) return;

    final isOff = NavigationHelper.isOffRoute(currentPos, _routePoints);
    if (isOff) {
      if (isSimulated) {
        _consecutiveOffRouteCount = 0;
        _recalculateRoute(currentPos);
      } else {
        _consecutiveOffRouteCount++;
        if (_consecutiveOffRouteCount >= 3) {
          _consecutiveOffRouteCount = 0;
          _recalculateRoute(currentPos);
        }
      }
    } else if (_consecutiveOffRouteCount > 0) {
      _consecutiveOffRouteCount = 0;
    }
  }

  Future<void> _recalculateRoute(LatLng currentPos) async {
    if (!mounted) return;
    _isRecalculating = true;

    try {
      _showSnackBar("Bạn đã đi lệch hướng. Đang tự động tìm đường đi mới...", const Color(0xFFB5956A));

      final endLocation = LatLng(widget.destination.latitude, widget.destination.longitude);
      final routeResult = await RoutingService.getRoute(currentPos, endLocation, profile: _selectedProfile);

      if (!mounted) return;

      if (routeResult.points.isNotEmpty) {
        setState(() {
          _userLocation = currentPos;
          _gpsAddress = null;
          _manualStartLocationName = null;
          _routePoints = routeResult.points;
          _routeDistanceKm = routeResult.distanceKm;
          _routeDurationMin = routeResult.durationMinutes;
          _initialRouteDistanceKm = routeResult.distanceKm;
          _initialRouteDurationMin = routeResult.durationMinutes;
        });
        
        WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapBounds());
        
        GeocodingService.fetchAddressFromCoords(currentPos).then((newAddress) {
          if (mounted && newAddress != null) {
            setState(() => _gpsAddress = newAddress);
          }
        });
      } else {
        _lastRouteCheckTime = DateTime.now().add(const Duration(seconds: 15));
        _showWarning("Không thể tính toán lại lộ trình từ vị trí hiện tại.");
      }
    } catch (e) {
      debugPrint("Lỗi tính toán lại đường đi: $e");
    } finally {
      if (mounted) _isRecalculating = false;
    }
  }

  void _simulateOffRoute() {
    if (_routePoints.isEmpty) {
      _showWarning("Chưa có tuyến đường để mô phỏng đi lệch hướng.");
      return;
    }

    _isRecalculating = false;
    final idx = _routePoints.length ~/ 2;
    final referencePoint = _routePoints[idx];

    LatLng nextPoint = (idx + 1 < _routePoints.length) 
        ? _routePoints[idx + 1] 
        : ((idx - 1 >= 0) ? _routePoints[idx - 1] : LatLng(referencePoint.latitude + 0.001, referencePoint.longitude));

    final double dLat = nextPoint.latitude - referencePoint.latitude;
    final double dLon = nextPoint.longitude - referencePoint.longitude;

    double pLat = -dLon;
    double pLon = dLat;
    final double dist = dLat.abs() + dLon.abs();
    
    if (dist > 0) {
      pLat = (pLat / dist) * 0.0022;
      pLon = (pLon / dist) * 0.0022;
    } else {
      pLat = pLon = 0.0022;
    }

    final simulatedLatLng = LatLng(referencePoint.latitude + pLat, referencePoint.longitude + pLon);
    _checkIfOffRoute(simulatedLatLng, isSimulated: true);
  }

  void _toggleSimulation() {
    if (_movementSimulationTimer?.isActive ?? false) {
      _movementSimulationTimer?.cancel();
      _showSnackBar("Đã dừng mô phỏng di chuyển. Khôi phục định vị GPS thật...", const Color(0xFF0F1E1B));
      _startTracking();
      setState(() {});
    } else {
      if (_routePoints.isEmpty) {
        _showWarning("Chưa có tuyến đường được vẽ để mô phỏng.");
        return;
      }
      
      _positionStreamSubscription?.cancel();
      double simulationIndex = 0.0;
      
      _showSnackBar("Bắt đầu mô phỏng di chuyển tự động...", const Color(0xFFB5956A));

      _movementSimulationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (simulationIndex >= _routePoints.length) {
          timer.cancel();
          _showSnackBar("Đã đi hết tuyến đường mô phỏng!", const Color(0xFF2D6A4F));
          _startTracking();
          setState(() {});
          return;
        }

        final simulatedPos = _routePoints[simulationIndex.toInt()];
        setState(() => _userLocation = simulatedPos);
        _updateRemainingMetrics(simulatedPos);
        _animatedMapMove(simulatedPos, _mapController.camera.zoom);
        _checkIfOffRoute(simulatedPos);
        simulationIndex += 0.3;
      });
      setState(() {});
    }
  }

  void _showManualLocationDialog() {
    showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ManualLocationDialog(
        fetchSuggestions: GeocodingService.fetchAddressSuggestions,
      ),
    ).then(_onManualLocationSelected);
  }

  Future<void> _onManualLocationSelected(Map<String, dynamic>? item) async {
    if (item == null || !mounted) return;
    
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    setState(() => _isLoading = true);

    final startLocation = item['latlng'] as LatLng;
    final endLocation = LatLng(widget.destination.latitude, widget.destination.longitude);
    
    try {
      final routeResult = await RoutingService.getRoute(startLocation, endLocation, profile: _selectedProfile);
      if (mounted) {
        setState(() {
          _userLocation = startLocation;
          _routePoints = routeResult.points;
          _routeDistanceKm = routeResult.distanceKm;
          _routeDurationMin = routeResult.durationMinutes;
          _initialRouteDistanceKm = routeResult.distanceKm;
          _initialRouteDurationMin = routeResult.durationMinutes;
          _manualStartLocationName = item['display_name'] as String;
          _gpsAddress = null;
          _consecutiveOffRouteCount = 0;
          _isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapBounds());
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showWarning("Lỗi khi tìm đường: $e");
      }
    }
  }

  Future<void> _checkLocationSilentlyAndRoute() async {
    LatLng startLocation = _fallbackStart;
    bool hasGPS = false;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
          final pos = await MapLocationService.getCurrentPosition();
          if (pos != null) {
            startLocation = LatLng(pos.latitude, pos.longitude);
            hasGPS = true;
          }
        }
      }
    } catch (e) {
      debugPrint("Lỗi kiểm tra GPS: $e");
    }

    _calculateAndSetRoute(startLocation, hasGPS);
  }

  Future<void> _requestLocationAndRoute() async {
    LatLng startLocation = _fallbackStart;
    bool hasGPS = false;

    try {
      bool hasPermission = await MapLocationService.handleLocationPermission(
        onEnableService: () async {
          if (!mounted) return false;
          return await showDialog<bool>(
            context: context,
            builder: (context) => const LocationExplanationDialog(
              title: 'Bật GPS',
              content: 'Vui lòng bật dịch vụ định vị (GPS) để dẫn đường từ vị trí của bạn.',
              confirmText: 'Mở Cài đặt',
            ),
          ) ?? false;
        },
        onPermissionDenied: () async {
          if (!mounted) return false;
          return await showDialog<bool>(
            context: context,
            builder: (context) => const LocationExplanationDialog(
              title: 'Cấp quyền vị trí',
              content: 'Ứng dụng cần quyền truy cập vị trí để dẫn đường.',
              confirmText: 'Cho phép',
            ),
          ) ?? false;
        },
        onPermissionPermanentlyDenied: () async {
          if (!mounted) return false;
          return await showDialog<bool>(
            context: context,
            builder: (context) => const LocationExplanationDialog(
              title: 'Quyền bị từ chối',
              content: 'Vui lòng mở Cài đặt ứng dụng và cấp quyền để sử dụng bản đồ.',
              confirmText: 'Mở Cài đặt App',
            ),
          ) ?? false;
        },
      );

      if (hasPermission) {
        final pos = await MapLocationService.getCurrentPosition();
        if (pos != null) {
          startLocation = LatLng(pos.latitude, pos.longitude);
          hasGPS = true;
        }
      }
    } catch (e) {
      debugPrint("Lỗi GPS: $e");
    }

    _calculateAndSetRoute(startLocation, hasGPS);
  }

  Future<void> _calculateAndSetRoute(LatLng startLocation, bool hasGPS) async {
    if (!mounted) return;
    
    final endLocation = LatLng(widget.destination.latitude, widget.destination.longitude);
    try {
      final routeResult = await RoutingService.getRoute(startLocation, endLocation);
      if (!mounted) return;

      setState(() {
        if (hasGPS) {
          _userLocation = startLocation;
          _gpsAddress = null;
          _manualStartLocationName = null;
          _showLocationWarningBanner = false;
        } else {
          _showLocationWarningBanner = true;
        }
        _routePoints = routeResult.points;
        _routeDistanceKm = routeResult.distanceKm;
        _routeDurationMin = routeResult.durationMinutes;
        _initialRouteDistanceKm = routeResult.distanceKm;
        _initialRouteDurationMin = routeResult.durationMinutes;
        _consecutiveOffRouteCount = 0;
        _isLoading = false;
      });

      if (!hasGPS) {
        _showWarning("Không thể định vị vị trí hiện tại. Bản đồ đang hiển thị đường đi từ Hà Nội.");
      } else if (routeResult.points.isEmpty) {
        _showWarning("Không thể tính toán tuyến đường đi từ vị trí của bạn.");
      }

      if (hasGPS) {
        _startTracking();
        GeocodingService.fetchAddressFromCoords(startLocation).then((fetchedAddress) {
          if (mounted && fetchedAddress != null) {
            setState(() => _gpsAddress = fetchedAddress);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showWarning("Lỗi kết nối khi lấy tuyến đường.");
      }
    }
  }

  void _showWarning(String msg) {
    if (!mounted) return;
    _showSnackBar(msg, Colors.redAccent, durationSeconds: 4);
  }

  void _showSnackBar(String message, Color backgroundColor, {int durationSeconds = 3}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Montserrat', color: Colors.white)),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: durationSeconds),
      ),
    );
  }

  void _fitMapBounds() {
    if (_routePoints.isEmpty) return;
    final cameraFit = CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(_routePoints),
      padding: const EdgeInsets.all(50.0),
    );
    final fitted = cameraFit.fit(_mapController.camera);
    _animatedMapMove(fitted.center, fitted.zoom);
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    _cameraAnimationController?.stop();
    _cameraAnimationController?.dispose();

    final camera = _mapController.camera;
    final latTween = Tween<double>(begin: camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: camera.zoom, end: destZoom);

    _cameraAnimationController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    final animation = CurvedAnimation(parent: _cameraAnimationController!, curve: Curves.fastOutSlowIn);

    _cameraAnimationController!.addListener(() {
      if (!mounted) return;
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    _cameraAnimationController!.forward();
  }

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

    final String? fullAddress = _manualStartLocationName ?? _gpsAddress;
    final split = fullAddress != null ? NavigationHelper.splitAddress(fullAddress) : null;
    final startTitle = split?['title'] ?? (_userLocation != null ? 'Vị trí của tôi' : 'Hà Nội (Mặc định)');
    final startSubtitle = split?['subtitle'] ?? (_userLocation != null && _gpsAddress == null ? 'Đang xác định địa chỉ...' : '');

    final mapWidget = TourMapWidget(
      destLocation: destLocation,
      userLocation: _userLocation,
      routePoints: _routePoints,
      routeDistanceKm: _routeDistanceKm,
      routeDurationMin: _routeDurationMin,
      showLocationWarningBanner: _showLocationWarningBanner,
      showRouteMetricsCard: _showRouteMetricsCard,
      isSimulating: _movementSimulationTimer?.isActive ?? false,
      mapController: _mapController,
      warningBannerContent: MapWarningBanner(
        manualStartLocationName: _manualStartLocationName,
        onDismiss: () => setState(() => _showLocationWarningBanner = false),
        onManualInputTap: _showManualLocationDialog,
        onEnableGPSTap: () {
          setState(() {
            _isLoading = true;
            _showLocationWarningBanner = false;
          });
          _requestLocationAndRoute();
        },
      ),
      routeMetricsFloatingCard: RouteMetricsCard(
        routeDurationMin: _routeDurationMin,
        routeDistanceKm: _routeDistanceKm,
        onClose: () => setState(() => _showRouteMetricsCard = false),
      ),
      onToggleRouteMetricsCard: (val) => setState(() => _showRouteMetricsCard = val),
      onToggleSimulation: _toggleSimulation,
      onSimulateOffRoute: _simulateOffRoute,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: isDesktop ? null : _buildAppBar(),
      body: _isLoading 
          ? const MapLoadingState()
          : _buildBody(isDesktop, destLocation, startTitle, startSubtitle, mapWidget),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      title: Text(
        'Đường đi đến ${widget.destination.name}',
        style: const TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white),
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
    );
  }

  Widget _buildBody(bool isDesktop, LatLng destLocation, String startTitle, String startSubtitle, Widget mapWidget) {
    if (isDesktop) {
      return MapDesktopView(
        destination: widget.destination,
        destLocation: destLocation,
        userLocation: _userLocation,
        fallbackStart: _fallbackStart,
        routePoints: _routePoints,
        startTitle: startTitle,
        startSubtitle: startSubtitle,
        activeMobileTab: _activeMobileTab,
        onTabChanged: (val) => setState(() => _activeMobileTab = val),
        onFitMapBounds: _fitMapBounds,
        onMoveCamera: _animatedMapMove,
        mapWidget: mapWidget,
      );
    } else {
      return MapMobileView(
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
        onTabChanged: (val) => setState(() => _activeMobileTab = val),
        onCardToggle: (val) => setState(() => _showLocationCard = val),
      );
    }
  }
}
