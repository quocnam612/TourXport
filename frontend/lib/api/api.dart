import 'dart:convert';

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// Override từ build/run, không cần sửa backend.
/// Ví dụ thiết bị thật: `flutter run --dart-define=API_BASE_URL=http://192.168.1.5:3000`
const String _kApiBaseFromEnv = String.fromEnvironment('API_BASE_URL', defaultValue: '');
const String _kAiBaseFromEnv = String.fromEnvironment('AI_BASE_URL', defaultValue: '');

/// Base URL cho API Node. Emulator Android dùng 10.0.2.2 để trỏ về máy host.
String get apiBaseUrl {
    final override = _kApiBaseFromEnv.trim();
    if (override.isNotEmpty) {
        return override.endsWith('/') ? override.substring(0, override.length - 1) : override;
    }
    if (kIsWeb) {
        return 'http://localhost:3000';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
        // Android emulator dùng 10.0.2.2 để trỏ về localhost của máy host.
        // Thiết bị thật cần truyền API_BASE_URL bằng IP LAN của máy chạy backend.
        return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
}

/// Base URL cho AI Backend (Python - FastAPI)
String get aiBaseUrl {
  final override = _kAiBaseFromEnv.trim();
  if (override.isNotEmpty) {
    return override.endsWith('/') ? override.substring(0, override.length - 1) : override;
  }
  if (kIsWeb) {
    return 'http://localhost:8000';
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8000';
  }
  return 'http://localhost:8000';
}

final http.Client _client = http.Client();

Map<String, String> _buildHeaders({String? token}) {
  return {
    'Content-Type': 'application/json',
    if (token != null && token.trim().isNotEmpty)
      'Authorization': 'Bearer ${token.trim()}',
  };
}

Future<http.Response> apiGet(String path, {String? token}) {
  final uri = Uri.parse('$apiBaseUrl$path');
  return _client.get(
    uri,
    headers: _buildHeaders(token: token),
  );
}

Future<http.Response> apiPostJson(
  String path,
  Map<String, dynamic> body, {
  String? token,
}) {
  final uri = Uri.parse('$apiBaseUrl$path');
  return _client.post(
    uri,
    headers: _buildHeaders(token: token),
    body: jsonEncode(body),
  );
}
/// Gọi API tới AI Backend (timeout dài hơn vì OpenAI cần xử lý 15-60s)
Future<http.Response> apiAiPostJson(
  String path,
  Map<String, dynamic> body, {
  String? token,
  Duration timeout = const Duration(seconds: 120),
}) {
  final uri = Uri.parse('$aiBaseUrl$path');
  return _client.post(
    uri,
    headers: _buildHeaders(token: token),
    body: jsonEncode(body),
  ).timeout(timeout);
}

Future<http.Response> apiDeleteJson(
  String path,
  Map<String, dynamic> body, {
  String? token,
}) {
  final uri = Uri.parse('$apiBaseUrl$path');
  return _client.delete(
    uri,
    headers: _buildHeaders(token: token),
    body: jsonEncode(body),
  );
}

Future<http.Response> apiPutJson(
  String path,
  Map<String, dynamic> body, {
  String? token,
}) {
  final uri = Uri.parse('$apiBaseUrl$path');
  return _client.put(
    uri,
    headers: _buildHeaders(token: token),
    body: jsonEncode(body),
  );
}

MediaType _getMediaTypeForFile(String filePath) {
  final ext = filePath.split('.').last.toLowerCase();
  if (ext == 'jpg' || ext == 'jpeg') {
    return MediaType('image', 'jpeg');
  } else if (ext == 'png') {
    return MediaType('image', 'png');
  } else if (ext == 'webp') {
    return MediaType('image', 'webp');
  }
  return MediaType('application', 'octet-stream');
}

Future<http.StreamedResponse> apiPostMultipartBytes(
  String path,
  String fieldName,
  List<int> bytes, {
  required String filename,
  String? token,
}) async {
  final uri = Uri.parse('$apiBaseUrl$path');
  final request = http.MultipartRequest('POST', uri);
  
  if (token != null && token.trim().isNotEmpty) {
    request.headers['Authorization'] = 'Bearer ${token.trim()}';
  }
  
  final mediaType = _getMediaTypeForFile(filename);
  request.files.add(http.MultipartFile.fromBytes(
    fieldName,
    bytes,
    filename: filename,
    contentType: mediaType,
  ));
  return request.send();
}

Future<http.StreamedResponse> apiPutMultipartBytes(
  String path,
  String fieldName,
  List<int> bytes, {
  required String filename,
  String? token,
}) async {
  final uri = Uri.parse('$apiBaseUrl$path');
  final request = http.MultipartRequest('PUT', uri);
  
  if (token != null && token.trim().isNotEmpty) {
    request.headers['Authorization'] = 'Bearer ${token.trim()}';
  }
  
  final mediaType = _getMediaTypeForFile(filename);
  request.files.add(http.MultipartFile.fromBytes(
    fieldName,
    bytes,
    filename: filename,
    contentType: mediaType,
  ));
  return request.send();
}

/// Fetch a location document by its sourceLocationId (external provider id).
/// Returns the first matching document as a Map<String, dynamic> or null.


/// Parses JSON object from response body; returns null if body is empty or invalid.
Map<String, dynamic>? tryDecodeJsonObject(String body) {
  final trimmed = body.trim();
  if (trimmed.isEmpty) return null;
  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  } catch (_) {}
  return null;
}

String savedLocationEndpointForType(String type) {
  final normalized = type.trim().toLowerCase();
  if (normalized.contains('nhà hàng') ||
      normalized.contains('nha hang') ||
      normalized.contains('restaurant')) {
    return '/auth/profile/saved-restaurants';
  }
  if (normalized.contains('khách sạn') ||
      normalized.contains('khach san') ||
      normalized.contains('hotel')) {
    return '/auth/profile/saved-hotels';
  }
  return '/auth/profile/saved-places';
}

String savedLocationBodyKeyForType(String type) {
  final endpoint = savedLocationEndpointForType(type);
  if (endpoint.endsWith('saved-restaurants')) return 'restaurantId';
  if (endpoint.endsWith('saved-hotels')) return 'hotelId';
  return 'placeId';
}

String searchEndpointForType(String type) {
  final normalized = type.trim().toLowerCase();
  if (normalized.contains('nhà hàng') ||
      normalized.contains('nha hang') ||
      normalized.contains('restaurant')) {
    return '/restaurants';
  }
  if (normalized.contains('khách sạn') ||
      normalized.contains('khach san') ||
      normalized.contains('hotel')) {
    return '/hotels';
  }
  return '/locations';
}

/// Resolves a saved location ID by searching the matching backend collection.
Future<String?> resolveLocationIdByName(String name, String type, {String? token}) async {
  if (name.isEmpty) return null;
  try {
    final encodedName = Uri.encodeComponent(name);
    final endpoint = searchEndpointForType(type);
    final response = await apiGet(
      '$endpoint?query=$encodedName&limit=1',
      token: token,
    );
    final data = tryDecodeJsonObject(response.body);
    if (response.statusCode == 200 && data?['success'] == true) {
      final list = data!['data'];
      if (list is List && list.isNotEmpty) {
        return list.first['_id'] as String?;
      }
    }
  } catch (_) {}
  return null;
}

/// Resolves a place ID by searching the backend using `/locations`.
Future<String?> resolvePlaceIdByName(String name, {String? token}) {
  return resolveLocationIdByName(name, 'Địa điểm', token: token);
}

/// Fetch a location document from the backend by the original source ID
/// Returns the first matching document as a Map or null when not found.
Future<Map<String, dynamic>?> fetchLocationBySourceId(String sourceId, {String? sourceCollection, String? token}) async {
  if (sourceId.isEmpty) return null;
  // Only call the specific endpoint indicated by sourceCollection.
  if (sourceCollection == null || sourceCollection.trim().isEmpty) return null;
  try {
    final sc = sourceCollection.trim().toLowerCase();
    String coll;
    if (sc.contains('restaurant')) coll = 'restaurants';
    else if (sc.contains('hotel')) coll = 'hotels';
    else coll = 'locations';

    final uri = Uri.parse('$apiBaseUrl/$coll/search?id=${Uri.encodeComponent(sourceId)}');
    final resp = await _client.get(uri, headers: _buildHeaders(token: token));
    final data = tryDecodeJsonObject(resp.body);
    if (resp.statusCode == 200 && data != null && data['success'] == true) {
      final payload = data['data'];
      if (payload is List && payload.isNotEmpty) {
        final item = payload.first;
        if (item is Map) return Map<String, dynamic>.from(item);
      } else if (payload is Map) {
        return Map<String, dynamic>.from(payload);
      }
      // Some endpoints may return the object directly without 'data'
      if (data is Map && data.containsKey('_id') && data.containsKey('title')) {
        return Map<String, dynamic>.from(data);
      }
    }
  } catch (_) {}
  return null;
}
