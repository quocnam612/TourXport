import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/destination.dart';
import '../utils/routing_service.dart';

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
  final MapController _mapController = MapController();
  
  // Vị trí mặc định nếu không lấy được GPS (Ví dụ: Hà Nội)
  static const LatLng _fallbackStart = LatLng(21.0285, 105.8542);

  @override
  void initState() {
    super.initState();
    _fetchLocationAndRoute();
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
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

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
      print("Không lấy được vị trí GPS: $e");
    }

    final endLocation = LatLng(widget.destination.latitude, widget.destination.longitude);

    // 4. Lấy dữ liệu tuyến đường từ Routing Service
    final points = await RoutingService.getRoute(startLocation, endLocation);

    if (mounted) {
      setState(() {
        if (hasGPS) {
          _userLocation = startLocation;
        }
        _routePoints = points;
        _isLoading = false;
      });

      if (!hasGPS) {
        _showWarning("Không thể định vị vị trí hiện tại. Bản đồ đang hiển thị đường đi từ Hà Nội.");
      } else if (points.isEmpty) {
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

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
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
          : Stack(
              children: [
                // Render Bản đồ OpenStreetMap
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
                            color: const Color(0xFFB5956A), // Màu vàng đồng sang trọng đồng bộ app
                            borderColor: Colors.black.withOpacity(0.3),
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
                                    color: Colors.blue.withOpacity(0.2),
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

                // Phím chức năng và thông tin bên dưới bản đồ
                Positioned(
                  bottom: 24,
                  left: 20,
                  right: 20,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.destination.name,
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tỉnh/Thành: ${widget.destination.province}',
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                _mapController.move(destLocation, 14.5);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB5956A),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.location_searching_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Điểm đến',
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
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
}
