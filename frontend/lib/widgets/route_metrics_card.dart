import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/navigation_helper.dart';
import '../utils/tour_map_utils.dart';

class RouteMetricsCard extends StatelessWidget {
  final double routeDurationMin;
  final double routeDistanceKm;
  final VoidCallback onClose;
  final VoidCallback? onOpenMap;
  final DateTime? startTime;

  const RouteMetricsCard({
    super.key,
    required this.routeDurationMin,
    required this.routeDistanceKm,
    required this.onClose,
    this.onOpenMap,
    this.startTime,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final maxCardWidth = isDesktop
        ? (MediaQuery.of(context).size.width - 360 - 40)
        : (MediaQuery.of(context).size.width - 72);

    final etaStr = NavigationHelper.getETAString(routeDurationMin, startTime: startTime);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          constraints: BoxConstraints(
            maxWidth: maxCardWidth,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1E1B).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Wrap(
                  alignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          const WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding: EdgeInsets.only(right: 8.0),
                              child: Icon(Icons.directions_car_rounded, color: Color(0xFFD4AF7A), size: 18),
                            ),
                          ),
                          TextSpan(
                            text: 'Ô tô/Xe máy: ',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextSpan(
                            text: '${TourMapUtils.formatDuration(routeDurationMin)} ',
                            style: const TextStyle(color: Color(0xFFD4AF7A)),
                          ),
                          TextSpan(
                            text: '(${TourMapUtils.formatDistance(routeDistanceKm)})',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '• Đến nơi lúc $etaStr',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (onOpenMap != null)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF7A).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.navigation_rounded, color: Color(0xFFD4AF7A), size: 20),
                    onPressed: onOpenMap,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                  onPressed: onClose,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
