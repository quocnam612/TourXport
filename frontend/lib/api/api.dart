import 'dart:convert';
import 'dart:io' show Platform, File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// Override từ build/run, không cần sửa backend.
/// Ví dụ thiết bị thật: `flutter run --dart-define=API_BASE_URL=http://192.168.1.5:3000`
const String _kApiBaseFromEnv = String.fromEnvironment('API_BASE_URL', defaultValue: '');

/// Base URL cho API Node. Emulator Android dùng 10.0.2.2 để trỏ về máy host.
String get apiBaseUrl {
    final override = _kApiBaseFromEnv.trim();
    if (override.isNotEmpty) {
        return override.endsWith('/') ? override.substring(0, override.length - 1) : override;
    }
    if (kIsWeb) {
        return 'http://localhost:3000';
    }
    if (Platform.isAndroid) {
        // Android emulator dùng 10.0.2.2 để trỏ về localhost của máy host.
        // Thiết bị thật cần truyền API_BASE_URL bằng IP LAN của máy chạy backend.
        return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
}

/// Base URL cho AI Backend (Python - FastAPI)
String get aiBaseUrl {
  final override = _kApiBaseFromEnv.trim();
  if (override.isNotEmpty) {
    // Nếu override có chứa port, ta giả định nó là base chung, nhưng AI thường chạy port khác.
    // Tuy nhiên để đơn giản, nếu người dùng cung cấp API_BASE_URL, ta dùng nó làm base cho cả 2 hoặc xử lý logic riêng.
    // Ở đây ta mặc định port 8000 cho AI.
    final base = override.endsWith('/') ? override.substring(0, override.length - 1) : override;
    if (base.contains(':3000')) return base.replaceFirst(':3000', ':8000');
    return base;
  }
  if (kIsWeb) {
    return 'http://localhost:8000';
  }
  if (Platform.isAndroid) {
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

Future<http.StreamedResponse> apiPostMultipart(
  String path,
  String fieldName,
  File file, {
  String? token,
}) async {
  final uri = Uri.parse('$apiBaseUrl$path');
  final request = http.MultipartRequest('POST', uri);
  
  if (token != null && token.trim().isNotEmpty) {
    request.headers['Authorization'] = 'Bearer ${token.trim()}';
  }
  
  request.files.add(await http.MultipartFile.fromPath(fieldName, file.path));
  return request.send();
}

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

/// Resolves a place ID by searching the backend using `/locations/search`
Future<String?> resolvePlaceIdByName(String name, {String? token}) async {
  if (name.isEmpty) return null;
  try {
    final encodedName = Uri.encodeComponent(name);
    final response = await apiGet(
      '/locations?query=$encodedName&limit=1',
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
