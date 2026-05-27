import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class TourMapWidget extends StatelessWidget {
  final LatLng destLocation;
  final LatLng? userLocation;
  final List<LatLng> routePoints;
  final double routeDistanceKm;
  final double routeDurationMin;
  final bool showLocationWarningBanner;
  final bool showRouteMetricsCard;
  final bool isSimulating;
  final MapController mapController;
  final Widget warningBannerContent;
  final Widget routeMetricsFloatingCard;
  final ValueChanged<bool> onToggleRouteMetricsCard;
  final VoidCallback onToggleSimulation;
  final VoidCallback onSimulateOffRoute;

  const TourMapWidget({
    super.key,
    required this.destLocation,
    required this.userLocation,
    required this.routePoints,
    required this.routeDistanceKm,
    required this.routeDurationMin,
    required this.showLocationWarningBanner,
    required this.showRouteMetricsCard,
    required this.isSimulating,
    required this.mapController,
    required this.warningBannerContent,
    required this.routeMetricsFloatingCard,
    required this.onToggleRouteMetricsCard,
    required this.onToggleSimulation,
    required this.onSimulateOffRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
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
            if (routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    strokeWidth: 5.5,
                    color: const Color(0xFFB5956A),
                    borderColor: Colors.black.withValues(alpha: 1),
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),
            
            // Đánh dấu các địa điểm
            MarkerLayer(
              markers: [
                // Ghim Vị trí Người dùng (Marker chấm tròn màu xanh có hiệu ứng đổ bóng)
                if (userLocation != null)
                  Marker(
                    point: userLocation!,
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
                
                // Ghim Vị trí Điểm đến (Marker biểu tượng ghim đỏ)
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

        // Banner cảnh báo vị trí & Thẻ hiển thị thông số hành trình nổi trên bản đồ
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showLocationWarningBanner) ...[
                warningBannerContent,
                const SizedBox(height: 10),
              ],
              if (showRouteMetricsCard && routePoints.isNotEmpty && (routeDistanceKm > 0 || routeDurationMin > 0)) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    routeMetricsFloatingCard,
                  ],
                ),
              ],
            ],
          ),
        ),

        // Nút mở lại thẻ thông số hành trình khi người dùng đã ẩn đi trước đó
        if (!showRouteMetricsCard && routePoints.isNotEmpty && (routeDistanceKm > 0 || routeDurationMin > 0))
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () => onToggleRouteMetricsCard(true),
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
                            '${routeDurationMin.toStringAsFixed(0)} phút • ${routeDistanceKm.toStringAsFixed(1).replaceAll('.', ',')} km',
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

        // Nút giả lập đi sai đường và di chuyển (Debug mode duy nhất để test)
        if (kDebugMode && routePoints.isNotEmpty) ...[
          // Nút mô phỏng di chuyển dọc tuyến đường
          Positioned(
            right: 20,
            bottom: 310,
            child: FloatingActionButton.small(
              heroTag: 'debug_simulation_fab',
              backgroundColor: isSimulating ? Colors.green : const Color(0xFFD4AF7A),
              foregroundColor: Colors.white,
              tooltip: 'Mô phỏng di chuyển (Debug)',
              onPressed: onToggleSimulation,
              child: Icon(
                isSimulating ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 20,
              ),
            ),
          ),
          // Nút mô phỏng đi sai đường để kiểm tra re-routing
          Positioned(
            right: 20,
            bottom: 260,
            child: FloatingActionButton.small(
              heroTag: 'debug_rerouting_fab',
              backgroundColor: const Color(0xFFD4AF7A),
              foregroundColor: const Color(0xFF0F1E1B),
              tooltip: 'Mô phỏng đi sai đường (Debug)',
              onPressed: onSimulateOffRoute,
              child: const Icon(Icons.bug_report_rounded, size: 20),
            ),
          ),
        ],
      ],
    );
  }
}
