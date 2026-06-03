import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart' as intl;

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

  static String formatDuration(double totalMinutes) {
    int minutes = totalMinutes.round();
    int hours = minutes ~/ 60;
    int mins = minutes % 60;
    if (hours > 0) {
      return '$hours giờ ${mins > 0 ? '$mins phút' : ''}';
    }
    return '$mins phút';
  }

  static String formatCurrency(double cost) {
    if (cost <= 0) return "Miễn phí";
    // Using a manual format to avoid requiring context or intl initialization for simple use cases
    // Or we can use intl. We will use intl here.
    final format = intl.NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return format.format(cost);
  }

  static String formatDistance(double km) {
    return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
  }
}
