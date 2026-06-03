import 'package:flutter/material.dart';
import '../../utils/tour_map_utils.dart';

class TourRouteSummary extends StatelessWidget {
  final double routeDistanceKm;
  final double routeDurationMin;
  final int stopsCount;

  const TourRouteSummary({
    super.key,
    required this.routeDistanceKm,
    required this.routeDurationMin,
    required this.stopsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tổng quãng đường',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontFamily: 'Montserrat',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              TourMapUtils.formatDistance(routeDistanceKm),
              style: const TextStyle(
                color: Color(0xFFD4AF7A),
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
              ),
            ),
          ],
        ),
        Container(
          width: 1,
          height: 30,
          color: Colors.white.withOpacity(0.2),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Thời gian dự kiến',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontFamily: 'Montserrat',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              TourMapUtils.formatDuration(routeDurationMin),
              style: const TextStyle(
                color: Color(0xFFD4AF7A),
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
              ),
            ),
          ],
        ),
        Container(
          width: 1,
          height: 30,
          color: Colors.white.withOpacity(0.2),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Điểm đến',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontFamily: 'Montserrat',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$stopsCount điểm',
              style: const TextStyle(
                color: Color(0xFFD4AF7A),
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
