import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class NavigationHelper {
  /// Tính khoảng cách ngắn nhất từ [p] đến đoạn thẳng nối [a] và [b] (bằng mét).
  static double distanceToSegment(LatLng p, LatLng a, LatLng b) {
    // Ước lượng mặt phẳng cục bộ bằng cách nhân kinh độ với cos(vĩ độ)
    final double latRad = (a.latitude + b.latitude + p.latitude) / 3 * pi / 180.0;
    final double cosLat = cos(latRad);

    final double ax = a.longitude * cosLat;
    final double ay = a.latitude;
    final double bx = b.longitude * cosLat;
    final double by = b.latitude;
    final double px = p.longitude * cosLat;
    final double py = p.latitude;

    final double dx = bx - ax;
    final double dy = by - ay;

    if (dx == 0 && dy == 0) {
      return Geolocator.distanceBetween(p.latitude, p.longitude, a.latitude, a.longitude);
    }

    // Chiếu điểm P lên đoạn thẳng AB
    double t = ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy);
    t = t.clamp(0.0, 1.0); // Ràng buộc trong đoạn thẳng

    // Tọa độ của điểm chiếu C
    final double cx = ax + t * dx;
    final double cy = ay + t * dy;

    // Chuyển đổi ngược lại kinh/vĩ độ
    final double closestLon = cx / cosLat;
    final double closestLat = cy;

    return Geolocator.distanceBetween(p.latitude, p.longitude, closestLat, closestLon);
  }

  /// Kiểm tra xem vị trí hiện tại có bị lệch khỏi tuyến đường quá khoảng cách tối đa (maxDistanceMetres) hay không.
  /// Duyệt qua các đoạn thẳng (segments) nối giữa các nút để đảm bảo tính chính xác trên các đường thẳng dài.
  static bool isOffRoute(LatLng currentPos, List<LatLng> routePoints, {double maxDistanceMetres = 55.0}) {
    if (routePoints.isEmpty) return false;
    if (routePoints.length == 1) {
      final dist = Geolocator.distanceBetween(
        currentPos.latitude,
        currentPos.longitude,
        routePoints[0].latitude,
        routePoints[0].longitude,
      );
      return dist > maxDistanceMetres;
    }

    double minDistance = double.infinity;

    for (int i = 0; i < routePoints.length - 1; i++) {
      final double distance = distanceToSegment(currentPos, routePoints[i], routePoints[i + 1]);
      if (distance < minDistance) {
        minDistance = distance;
      }
      // Tối ưu hóa: Nếu đã tìm thấy khoảng cách nhỏ hơn hoặc bằng ngưỡng cho phép, chắc chắn không lệch hướng
      if (minDistance <= maxDistanceMetres) {
        return false;
      }
    }

    return minDistance > maxDistanceMetres;
  }

  /// Tách tên địa điểm và địa chỉ chi tiết từ chuỗi full OSM display_name
  static Map<String, String> splitAddress(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) {
      return {'title': 'Vị trí của tôi', 'subtitle': ''};
    }
    final commaIndex = fullName.indexOf(',');
    if (commaIndex == -1) {
      return {'title': fullName.trim(), 'subtitle': ''};
    }
    final title = fullName.substring(0, commaIndex).trim();
    final subtitle = fullName.substring(commaIndex + 1).trim();
    return {'title': title, 'subtitle': subtitle};
  }

  /// Tính chuỗi thời gian dự kiến đến nơi (ETA) định dạng "HH:MM"
  static String getETAString(double durationMinutes) {
    final now = DateTime.now();
    final eta = now.add(Duration(minutes: durationMinutes.round()));
    final hour = eta.hour.toString().padLeft(2, '0');
    final minute = eta.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Tính toán khoảng cách và thời gian di chuyển còn lại ngoại tuyến (Client-side estimation)
  static RemainingRouteMetrics calculateRemainingMetrics({
    required LatLng currentPos,
    required List<LatLng> routePoints,
    required double initialRouteDistanceKm,
    required double initialRouteDurationMin,
  }) {
    if (routePoints.isEmpty || initialRouteDistanceKm == 0.0) {
      return RemainingRouteMetrics(
        remainingDistanceKm: 0.0,
        remainingDurationMin: 0.0,
      );
    }

    // 1. Tìm điểm gần vị trí hiện tại nhất trên tuyến đường (closest index)
    int closestIndex = 0;
    double minDistance = double.infinity;

    for (int i = 0; i < routePoints.length; i++) {
      final distance = Geolocator.distanceBetween(
        currentPos.latitude,
        currentPos.longitude,
        routePoints[i].latitude,
        routePoints[i].longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    // 2. Tính tổng chiều dài phần còn lại của tuyến đường (từ closestIndex tới cuối)
    double remainingDistanceMeters = 0.0;
    for (int i = closestIndex; i < routePoints.length - 1; i++) {
      remainingDistanceMeters += Geolocator.distanceBetween(
        routePoints[i].latitude,
        routePoints[i].longitude,
        routePoints[i + 1].latitude,
        routePoints[i + 1].longitude,
      );
    }

    final double remainingKm = remainingDistanceMeters / 1000.0;

    // 3. Ước tính thời gian còn lại theo tỷ lệ chiều dài còn lại so với tổng chiều dài ban đầu
    double remainingMin = 0.0;
    double totalRouteMeters = 0.0;
    for (int i = 0; i < routePoints.length - 1; i++) {
      totalRouteMeters += Geolocator.distanceBetween(
        routePoints[i].latitude,
        routePoints[i].longitude,
        routePoints[i + 1].latitude,
        routePoints[i + 1].longitude,
      );
    }

    if (totalRouteMeters > 0) {
      double ratio = remainingDistanceMeters / totalRouteMeters;
      ratio = ratio.clamp(0.0, 1.0);
      remainingMin = initialRouteDurationMin * ratio;
    } else {
      remainingMin = initialRouteDurationMin;
    }

    return RemainingRouteMetrics(
      remainingDistanceKm: remainingKm,
      remainingDurationMin: remainingMin,
    );
  }
}

class RemainingRouteMetrics {
  final double remainingDistanceKm;
  final double remainingDurationMin;

  RemainingRouteMetrics({
    required this.remainingDistanceKm,
    required this.remainingDurationMin,
  });
}
