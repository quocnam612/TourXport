import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../models/ai_trip_response.dart';
import '../../../../models/tour_map_models.dart';
import '../../../../utils/time_parser_util.dart';
import '../../../../utils/tour_map_utils.dart';
import '../../route_metrics_card.dart';
import '../tour_activity_card.dart';

class MapLocationList extends StatelessWidget {
  final List<WaypointItem> waypointItems;
  final List<RouteSegment> routeSegments;
  final List<LatLng> currentWaypoints;
  final int? focusedSegmentIndex;
  final int selectedDayIndex;
  final AiDailyItinerary? currentDayItinerary;
  final bool hasNextDay;
  final bool isDesktop;
  final VoidCallback onNextDay;
  final Function(int?) onSegmentFocused;
  final Function(List<LatLng>) onFitBounds;
  final List<GlobalKey> waypointKeys;

  const MapLocationList({
    super.key,
    required this.waypointItems,
    required this.routeSegments,
    required this.currentWaypoints,
    required this.focusedSegmentIndex,
    required this.selectedDayIndex,
    this.currentDayItinerary,
    required this.hasNextDay,
    required this.onNextDay,
    required this.onSegmentFocused,
    required this.onFitBounds,
    required this.waypointKeys,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    DateTime? segmentStartTime;
    if (focusedSegmentIndex != null) {
      try {
        final startItem = waypointItems.firstWhere((w) => w.waypointIndex == focusedSegmentIndex);
        if (startItem.activity != null && startItem.activity!.timeSlot.isNotEmpty) {
          segmentStartTime = TimeParserUtil.parseEndTime(startItem.activity!.timeSlot);
        }
      } catch (_) {}
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (focusedSegmentIndex != null && focusedSegmentIndex! < routeSegments.length)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: RouteMetricsCard(
              routeDurationMin: routeSegments[focusedSegmentIndex!].durationMin,
              routeDistanceKm: routeSegments[focusedSegmentIndex!].distanceKm,
              startTime: segmentStartTime,
              onOpenMap: () async {
                final targetIndex = focusedSegmentIndex! + 1;
                if (targetIndex < currentWaypoints.length) {
                  final startPoint = currentWaypoints[focusedSegmentIndex!];
                  final targetPoint = currentWaypoints[targetIndex];
                  
                  final startLat = startPoint.latitude;
                  final startLng = startPoint.longitude;
                  final destLat = targetPoint.latitude;
                  final destLng = targetPoint.longitude;
                  
                  final url = Uri.parse('https://www.google.com/maps/dir/?api=1&origin=$startLat,$startLng&destination=$destLat,$destLng&travelmode=driving');
                  
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    await launchUrl(url);
                  }
                }
              },
              onClose: () {
                onSegmentFocused(null);
                onFitBounds(currentWaypoints);
              },
            ),
          ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: List.generate(waypointItems.length + 1, (i) {
              if (i == waypointItems.length) {
                if (!hasNextDay) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 24.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                    label: Text("Chuyển sang Ngày ${selectedDayIndex + 2}", style: const TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold)),
                    onPressed: onNextDay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF7A),
                      foregroundColor: const Color(0xFF0F1E1B),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                );
              }

              final item = waypointItems[i];
              final wpIndex = item.waypointIndex;
              final itemKey = i < waypointKeys.length ? waypointKeys[i] : null;
              
              bool isHighlighted = true;
              bool isSelected = false;
              if (focusedSegmentIndex != null && wpIndex != null) {
                isSelected = (wpIndex == focusedSegmentIndex) || (wpIndex == focusedSegmentIndex! + 1);
                isHighlighted = isSelected;
              } else if (focusedSegmentIndex != null && wpIndex == null) {
                isHighlighted = false;
              }
              
              final markerColor = wpIndex != null ? TourMapUtils.getColorForIndex(wpIndex) : null;
              VoidCallback? onTap = wpIndex != null ? () {
                  int targetSegment = wpIndex == 0 ? 0 : wpIndex - 1;
                  if (focusedSegmentIndex == targetSegment) {
                    onSegmentFocused(null);
                    onFitBounds(currentWaypoints);
                  } else {
                    onSegmentFocused(targetSegment);
                    if (targetSegment < currentWaypoints.length - 1) {
                      onFitBounds([currentWaypoints[targetSegment], currentWaypoints[targetSegment + 1]]);
                    }
                  }
              } : null;
              
              if (item.activity == null) {
                return GestureDetector(
                  key: itemKey,
                  onTap: onTap,
                  child: Opacity(
                    opacity: isHighlighted ? 1.0 : 0.4,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected 
                              ? (markerColor ?? const Color(0xFFD4AF7A)) 
                              : Colors.white.withOpacity(0.08),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: (markerColor ?? const Color(0xFFD4AF7A)).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.my_location_rounded,
                              color: markerColor ?? const Color(0xFFD4AF7A),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 14,
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
              }
              
              return Container(
                key: itemKey,
                child: TourActivityCard(act: item.activity!, onTap: onTap, isHighlighted: isHighlighted, isSelected: isSelected, markerColor: markerColor, isDesktop: isDesktop),
              );
            }),
          ),
        ),
      ],
    );
  }
}
