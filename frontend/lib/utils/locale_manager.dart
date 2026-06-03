import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleManager {
  static const String _localeKey = 'selected_locale';
  static final ValueNotifier<Locale> localeNotifier = ValueNotifier<Locale>(const Locale('vi'));

  /// Initializes the Locale from SharedPreferences or system default
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? localeCode = prefs.getString(_localeKey);
      if (localeCode != null) {
        localeNotifier.value = Locale(localeCode);
      } else {
        localeNotifier.value = const Locale('vi');
      }
    } catch (e) {
      debugPrint("Lỗi khởi tạo LocaleManager: $e");
    }
  }

  /// Sets and persists the selected Locale
  static Future<void> setLocale(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, languageCode);
      localeNotifier.value = Locale(languageCode);
    } catch (e) {
      debugPrint("Lỗi lưu Locale: $e");
    }
  }
}
