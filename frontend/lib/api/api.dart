import 'dart:convert';
import 'dart:io' show Platform;

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
    return 'http://10.0.2.2:3000';
  }
  return 'http://localhost:3000';
}

final http.Client _client = http.Client();

Future<http.Response> apiPostJson(String path, Map<String, dynamic> body) {
  final uri = Uri.parse('${apiBaseUrl}$path');
  return _client.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(body),
  );
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
