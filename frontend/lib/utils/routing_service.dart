import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final double durationMinutes;

  RouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
  });

  RouteResult.empty()
      : points = [],
        distanceKm = 0.0,
        durationMinutes = 0.0;
}

class RoutingService {
  /// Lấy thông tin tuyến đường đi thực tế từ điểm start đến điểm end
  /// Hỗ trợ các phương tiện (profile): 'driving' (ô tô/xe máy), 'bicycle' (xe đạp), 'foot' (đi bộ)
  static Future<RouteResult> getRoute(LatLng start, LatLng end, {String profile = 'driving'}) async {
    final validProfile = (profile == 'bicycle' || profile == 'foot') ? profile : 'driving';

    // Thử gọi OSRM với profile được chọn
    RouteResult result = await _fetchRouteFromOSRM(start, end, validProfile);

    // Nếu không có tuyến đường và profile được chọn không phải 'driving', fallback về 'driving'
    if (result.points.isEmpty && validProfile != 'driving') {
      print("OSRM routing failed for profile $profile, falling back to driving profile.");
      result = await _fetchRouteFromOSRM(start, end, 'driving');
    }

    return result;
  }

  static Future<RouteResult> _fetchRouteFromOSRM(LatLng start, LatLng end, String profile) async {
    final url = 'https://router.project-osrm.org/route/v1/$profile/'
        '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'TourXport/1.0 (com.example.tourxport; Flutter)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final List coordinates = data['routes'][0]['geometry']['coordinates'];
          final double distance = (data['routes'][0]['distance'] as num).toDouble() / 1000.0; // mét -> km

          double duration = (data['routes'][0]['duration'] as num).toDouble() / 60.0; // giây -> phút

          // Chuyển đổi GeoJSON [Kinh độ, Vĩ độ] -> LatLng [Vĩ độ, Kinh độ]
          final List<LatLng> points = coordinates
              .map((point) => LatLng(
                    (point[1] as num).toDouble(),
                    (point[0] as num).toDouble(),
                  ))
              .toList();

          return RouteResult(
            points: points,
            distanceKm: distance,
            durationMinutes: duration,
          );
        }
      }
    } catch (e) {
      print("Error calling OSRM Routing API ($profile): $e");
    }
    return RouteResult.empty();
  }
}
