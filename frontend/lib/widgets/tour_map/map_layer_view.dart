import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/tour_map_models.dart';
import '../../../utils/tour_map_utils.dart';
import 'tour_custom_marker.dart';

class MapLayerView extends StatelessWidget {
  final MapController mapController;
  final LatLng? userLocation;
  final List<RouteSegment> routeSegments;
  final List<LatLng> currentWaypoints;
  final int? focusedSegmentIndex;
  final bool isAllDaysMode;
  final bool hasUserLoc;

  const MapLayerView({
    super.key,
    required this.mapController,
    this.userLocation,
    required this.routeSegments,
    required this.currentWaypoints,
    required this.focusedSegmentIndex,
    required this.isAllDaysMode,
    required this.hasUserLoc,
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
            PolylineLayer(
              polylines: routeSegments.asMap().entries.map((entry) {
                final int index = entry.key;
                final seg = entry.value;
                final isFocused = focusedSegmentIndex == null || focusedSegmentIndex == index;
                return Polyline(
                  points: seg.points,
                  strokeWidth: isFocused ? 6.0 : 3.0,
                  color: isFocused ? seg.color.withOpacity(0.9) : seg.color.withOpacity(0.5),
                  borderColor: Colors.black.withOpacity(isFocused ? 0.8 : 0.1),
                  borderStrokeWidth: isFocused ? 2.0 : 1.0,
                );
              }).toList(),
            ),
          MarkerLayer(
            markers: currentWaypoints.asMap().entries.map((entry) {
              final int i = entry.key;
              final isFocused = focusedSegmentIndex == null || focusedSegmentIndex == i || focusedSegmentIndex == i - 1;
              return Marker(
                point: entry.value,
                width: (i == 0 && hasUserLoc) ? 50 : (isFocused ? 40 : 28),
                height: (i == 0 && hasUserLoc) ? 50 : (isFocused ? 40 : 28),
                alignment: Alignment.center,
                child: Opacity(
                  opacity: isFocused ? 1.0 : 0.4,
                  child: (i == 0 && hasUserLoc)
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isAllDaysMode ? const Color(0xFFB5956A).withOpacity(0.2) : TourMapUtils.getColorForIndex(0).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: isAllDaysMode ? const Color(0xFFB5956A) : TourMapUtils.getColorForIndex(0),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: isAllDaysMode ? const Color(0xFFB5956A).withOpacity(0.6) : TourMapUtils.getColorForIndex(0).withOpacity(0.6),
                                  blurRadius: 6,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : TourCustomMarker(
                        text: hasUserLoc ? '$i' : '${i + 1}',
                        color: isAllDaysMode ? const Color(0xFFE74C3C) : TourMapUtils.getColorForIndex(i),
                      ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
