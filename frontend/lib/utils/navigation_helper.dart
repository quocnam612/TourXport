import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class NavigationHelper {
  /// Kiểm tra xem vị trí hiện tại có bị lệch khỏi tuyến đường quá khoảng cách tối đa (maxDistanceMetres) hay không.
  /// Sử dụng bộ lọc thô (coarse filter) để giảm thiểu phép tính lượng giác đắt đỏ.
  static bool isOffRoute(LatLng currentPos, List<LatLng> routePoints, {double maxDistanceMetres = 55.0}) {
    if (routePoints.isEmpty) return false;

    double minDistance = double.infinity;
    bool foundPotentialClosePoint = false;

    // Bước 1: Bộ lọc thô (Coarse filtering) - Lọc nhanh bằng sai lệch tọa độ chữ số thập phân
    // 0.001 độ vĩ/kinh độ tương đương khoảng 110m.
    for (final point in routePoints) {
      final latDiff = (point.latitude - currentPos.latitude).abs();
      final lonDiff = (point.longitude - currentPos.longitude).abs();
      
      if (latDiff < 0.001 && lonDiff < 0.001) {
        foundPotentialClosePoint = true;
        
        // Tính khoảng cách lượng giác chính xác chỉ cho các điểm ở gần
        final distance = Geolocator.distanceBetween(
          currentPos.latitude,
          currentPos.longitude,
          point.latitude,
          point.longitude,
        );
        if (distance < minDistance) {
          minDistance = distance;
        }
      }
    }

    // Nếu bộ lọc nhanh xác nhận người dùng nằm trong bán kính an toàn (<= 55m)
    if (foundPotentialClosePoint && minDistance <= maxDistanceMetres) {
      return false; 
    }

    // Bước 2: Chỉ khi không tìm thấy điểm gần ở bước 1 mới quét chi tiết toàn bộ tuyến đường
    minDistance = double.infinity;
    for (final point in routePoints) {
      final distance = Geolocator.distanceBetween(
        currentPos.latitude,
        currentPos.longitude,
        point.latitude,
        point.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
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
