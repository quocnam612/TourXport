import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/tour_map_models.dart';
import '../../../utils/tour_map_utils.dart';
import 'tour_custom_marker.dart';
import 'pulsing_location_marker.dart';

class MapLayerView extends StatelessWidget {
  final MapController mapController;
  final LatLng? userLocation;
  final List<RouteSegment> routeSegments;
  final List<LatLng> currentWaypoints;
  final int? focusedSegmentIndex;
  final bool isAllDaysMode;
  final bool hasUserLoc;
  final Function(int)? onMarkerTap;

  const MapLayerView({
    super.key,
    required this.mapController,
    this.userLocation,
    required this.routeSegments,
    required this.currentWaypoints,
    required this.focusedSegmentIndex,
    required this.isAllDaysMode,
    required this.hasUserLoc,
    this.onMarkerTap,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          initialCenter: userLocation ?? TourMapUtils.fallbackStart,
          initialZoom: 12.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.tourxport',
            tileProvider: CancellableNetworkTileProvider(),
            errorTileCallback: (tile, error, stackTrace) {},
          ),
          if (routeSegments.isNotEmpty)
            TweenAnimationBuilder<double>(
              key: ValueKey(routeSegments.hashCode), // Re-animate if segments change
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return PolylineLayer(
                  polylines: routeSegments.asMap().entries.map((entry) {
                    final int index = entry.key;
                    final seg = entry.value;
                    final isFocused = focusedSegmentIndex == null || focusedSegmentIndex == index;
                    
                    final int ptCount = (seg.points.length * value).ceil();
                    final pts = seg.points.take(ptCount).toList();

                    return Polyline(
                      points: pts,
                      strokeWidth: isFocused ? 6.0 : 3.0,
                      color: isFocused ? seg.color.withOpacity(0.9) : seg.color.withOpacity(0.5),
                      borderColor: Colors.black.withOpacity(isFocused ? 0.8 : 0.1),
                      borderStrokeWidth: isFocused ? 2.0 : 1.0,
                    );
                  }).toList(),
                );
              },
            ),
          MarkerClusterLayerWidget(
            options: MarkerClusterLayerOptions(
              maxClusterRadius: 40,
              size: const Size(40, 40),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(50),
              maxZoom: 15,
              markers: currentWaypoints.asMap().entries
                  .where((entry) => !(entry.key == 0 && hasUserLoc)) // Loại bỏ User Location khỏi cluster
                  .map((entry) {
                final int i = entry.key;
                final isFocused = focusedSegmentIndex == null || focusedSegmentIndex == i || focusedSegmentIndex == i - 1;
                return Marker(
                  point: entry.value,
                  width: isFocused ? 40 : 28,
                  height: isFocused ? 40 : 28,
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: () {
                      if (onMarkerTap != null) onMarkerTap!(i);
                    },
                    child: Opacity(
                      opacity: isFocused ? 1.0 : 0.4,
                      child: TourCustomMarker(
                        text: hasUserLoc ? '$i' : '${i + 1}',
                        color: isAllDaysMode ? const Color(0xFFE74C3C) : TourMapUtils.getColorForIndex(i),
                      ),
                    ),
                  ),
                );
              }).toList(),
              builder: (context, markers) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color(0xFFD4AF7A),
                    border: Border.all(color: const Color(0xFF1B2321), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '+${markers.length}',
                      style: const TextStyle(color: Color(0xFF1B2321), fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
                    ),
                  ),
                );
              },
            ),
          ),
          if (hasUserLoc && currentWaypoints.isNotEmpty)
            MarkerLayer(
              markers: [
                Marker(
                  point: currentWaypoints[0],
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: () {
                      if (onMarkerTap != null) onMarkerTap!(0);
                    },
                    child: PulsingLocationMarker(
                      baseColor: isAllDaysMode 
                          ? const Color(0xFFB5956A) 
                          : TourMapUtils.getColorForIndex(0),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
