import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/navigation_helper.dart';

class RouteMetricsCard extends StatelessWidget {
  final double routeDurationMin;
  final double routeDistanceKm;
  final VoidCallback onClose;

  const RouteMetricsCard({
    super.key,
    required this.routeDurationMin,
    required this.routeDistanceKm,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final maxCardWidth = isDesktop
        ? (MediaQuery.of(context).size.width - 360 - 40)
        : (MediaQuery.of(context).size.width - 72);

    final etaStr = NavigationHelper.getETAString(routeDurationMin);

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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.directions_car_rounded, color: Color(0xFFD4AF7A), size: 18),
                        const SizedBox(width: 8),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text: 'Ô tô/Xe máy: ',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(
                                text: '${routeDurationMin.toStringAsFixed(0)} phút ',
                                style: const TextStyle(color: Color(0xFFD4AF7A)),
                              ),
                              TextSpan(
                                text: '(${routeDistanceKm.toStringAsFixed(1).replaceAll('.', ',')} km)',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
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
              const SizedBox(width: 4),
              // Nút đóng
              GestureDetector(
                onTap: onClose,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white.withValues(alpha: 0.4),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
