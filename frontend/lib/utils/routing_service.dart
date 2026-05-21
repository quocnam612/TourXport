import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RoutingService {
  /// Lấy danh sách các LatLng để vẽ đường đi thực tế từ điểm start đến điểm end
  /// Sử dụng dịch vụ OSRM public hoàn toàn miễn phí.
  static Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    final url = 'https://router.project-osrm.org/route/v1/driving/'
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
          
          // Định dạng GeoJSON là [Kinh độ, Vĩ độ] -> Chuyển sang LatLng [Vĩ độ, Kinh độ]
          return coordinates
              .map((point) => LatLng(
                    (point[1] as num).toDouble(),
                    (point[0] as num).toDouble(),
                  ))
              .toList();
        }
      }
    } catch (e) {
      print("Error calling OSRM Routing API: $e");
    }
    return [];
  }
}
