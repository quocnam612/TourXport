import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const String _tokenKey = 'auth_token';
  static const String _userNameKey = 'auth_user_name';
  static const String _savedAccountsKey = 'saved_accounts';

  static Future<void> saveSession({
    required String token,
    required String userName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userNameKey, userName);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey)?.trim();
    return token == null || token.isEmpty ? null : token;
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString(_userNameKey)?.trim();
    return userName == null || userName.isEmpty ? null : userName;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userNameKey);
  }

  static Future<List<Map<String, String>>> getSavedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_savedAccountsKey);
    if (data == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => Map<String, String>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveAccountToHistory({
    required String emailOrPhone,
    required String name,
    String? avatar,
  }) async {
    final accounts = await getSavedAccounts();
    
    accounts.removeWhere((acc) => acc['email'] == emailOrPhone);
    
    accounts.insert(0, {
      'email': emailOrPhone,
      'name': name,
      if (avatar != null && avatar.isNotEmpty) 'avatar': avatar,
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedAccountsKey, jsonEncode(accounts));
  }
  
  static Future<void> removeSavedAccount(String emailOrPhone) async {
    final accounts = await getSavedAccounts();
    accounts.removeWhere((acc) => acc['email'] == emailOrPhone);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedAccountsKey, jsonEncode(accounts));
  }

  static const String _pinKey = 'app_pin_lock';

  static Future<void> setAppPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final userName = await getUserName();
    if (userName == null) return;
    await prefs.setString('${_pinKey}_$userName', pin);
  }

  static Future<String?> getAppPin() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = await getUserName();
    if (userName == null) return null;
    return prefs.getString('${_pinKey}_$userName');
  }

  static Future<void> removeAppPin() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = await getUserName();
    if (userName == null) return;
    await prefs.remove('${_pinKey}_$userName');
  }
}
