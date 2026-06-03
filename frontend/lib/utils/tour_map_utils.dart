import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class TourMapUtils {
  static const LatLng fallbackStart = LatLng(21.0285, 105.8542);

  static final List<Color> palette = [
    Colors.lightBlueAccent,
    Colors.redAccent,
    const Color(0xFF4ADE80), // vibrant green
    Colors.orangeAccent,
    Colors.purpleAccent,
    Colors.amberAccent,
    Colors.cyanAccent,
    Colors.pinkAccent,
    Colors.limeAccent,
    Colors.tealAccent,
  ];

  static Color getColorForIndex(int index) {
    return palette[index % palette.length];
  }

  static IconData getTimeSlotIcon(String slot) {
    if (slot.contains('Sáng') || slot.contains('0')) return Icons.wb_sunny_rounded;
    if (slot.contains('Chiều') || slot.contains('13') || slot.contains('14') || slot.contains('15') || slot.contains('16') || slot.contains('17')) return Icons.wb_cloudy_rounded;
    return Icons.nightlight_round;
  }
}
