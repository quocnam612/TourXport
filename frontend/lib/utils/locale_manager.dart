import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleManager {
  static const String _localeKey = 'selected_locale';
  static const Set<String> supportedLanguageCodes = {'vi', 'en'};
  static final ValueNotifier<Locale> localeNotifier = ValueNotifier<Locale>(const Locale('vi'));

  static String normalizeLanguageCode(String? languageCode) {
    return supportedLanguageCodes.contains(languageCode) ? languageCode! : 'vi';
  }

  /// Initializes the Locale from SharedPreferences or system default
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? localeCode = prefs.getString(_localeKey);
      final normalizedCode = normalizeLanguageCode(localeCode);
      if (localeCode != normalizedCode) {
        await prefs.setString(_localeKey, normalizedCode);
      }
      localeNotifier.value = Locale(normalizedCode);
    } catch (e) {
      debugPrint("Lỗi khởi tạo LocaleManager: $e");
    }
  }

  /// Sets and persists the selected Locale
  static Future<void> setLocale(String languageCode) async {
    try {
      final normalizedCode = normalizeLanguageCode(languageCode);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, normalizedCode);
      localeNotifier.value = Locale(normalizedCode);
    } catch (e) {
      debugPrint("Lỗi lưu Locale: $e");
    }
  }
}
