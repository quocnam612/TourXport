import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/passport_models.dart';
import '../models/destination.dart';

class PassportService {
  PassportService._();
  static final PassportService instance = PassportService._();

  static const String _keyUnlockedNames = 'passport_unlocked_names';
  static const String _keyMemories = 'passport_memories';
  static const String _keyExp = 'passport_exp';

  final Set<String> _unlockedNames = {};
  final Map<String, TravelMemory> _memories = {};
  int _exp = 0;
  bool _initialized = false;

  final List<PassportBadge> _badges = [
    PassportBadge(
      id: 'badge_first',
      title: 'Hành Trình Bắt Đầu',
      description: 'Mở khóa địa điểm đầu tiên trên bản đồ.',
      iconName: 'military_tech_rounded',
    ),
    PassportBadge(
      id: 'badge_danang',
      title: 'Nhà Khám Phá Đà Nẵng',
      description: 'Mở khóa tất cả địa điểm du lịch tại TP. Đà Nẵng.',
      iconName: 'stars_rounded',
    ),
    PassportBadge(
      id: 'badge_hanoi',
      title: 'Hà Nội Học',
      description: 'Khám phá tất cả các địa danh di sản tại Hà Nội.',
      iconName: 'fort_rounded',
    ),
    PassportBadge(
      id: 'badge_master',
      title: 'Bậc Thầy Vi Hành',
      description: 'Khám phá thành công từ 5 địa điểm trở lên.',
      iconName: 'workspace_premium_rounded',
    ),
    PassportBadge(
      id: 'badge_photographer',
      title: 'Kẻ Săn Ảnh Du Lịch',
      description: 'Lưu giữ nhật ký hành trình có kèm ảnh check-in.',
      iconName: 'camera_alt_rounded',
    ),
  ];

  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();

      // Read unlocked names
      final names = prefs.getStringList(_keyUnlockedNames);
      if (names != null) {
        _unlockedNames.addAll(names);
      } else {
        // Pre-populate with mock data if empty
        _unlockedNames.addAll(['Cầu Rồng', 'Nhà thờ Đức Bà']);
      }

      // Read EXP
      _exp = prefs.getInt(_keyExp) ?? 250; // Start with 250 EXP for mock data

      // Read memories
      final memoriesJson = prefs.getString(_keyMemories);
      if (memoriesJson != null) {
        final decoded = json.decode(memoriesJson) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          _memories[key] = TravelMemory.fromJson(Map<String, dynamic>.from(value));
        });
      } else {
        // Pre-populate mock memories
        _memories['Cầu Rồng'] = TravelMemory(
          destinationId: 'mock_cau_rong',
          destinationName: 'Cầu Rồng',
          date: '12/06/2026',
          tourTitle: 'Đà Nẵng City Tour 1 Ngày',
          durationHours: 1.5,
          durationDays: 1,
          durationNights: 0,
          photoCount: 15,
          note: 'Cầu Rồng phun lửa rất hoành tráng vào cuối tuần! Thích hợp đi dạo ban đêm.',
          rating: 4.8,
          photoUrl: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=600&auto=format&fit=crop&q=60',
        );

        _memories['Nhà thờ Đức Bà'] = TravelMemory(
          destinationId: 'mock_nha_tho_duc_ba',
          destinationName: 'Nhà thờ Đức Bà',
          date: '10/06/2026',
          tourTitle: 'Sài Gòn Xưa Và Nay',
          durationHours: 2.0,
          durationDays: 1,
          durationNights: 0,
          photoCount: 8,
          note: 'Kiến trúc cổ kính rất đẹp giữa trung tâm thành phố. Đang trong giai đoạn trùng tu nhưng vẫn chụp được nhiều góc đẹp.',
          rating: 4.5,
          photoUrl: 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=600&auto=format&fit=crop&q=60',
        );
      }

      _initialized = true;
    } catch (e) {
      debugPrint('Error initializing PassportService: $e');
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_keyUnlockedNames, _unlockedNames.toList());
      await prefs.setInt(_keyExp, _exp);

      final memoriesMap = <String, Map<String, dynamic>>{};
      _memories.forEach((key, value) {
        memoriesMap[key] = value.toJson();
      });
      await prefs.setString(_keyMemories, json.encode(memoriesMap));
    } catch (e) {
      debugPrint('Error saving Passport data: $e');
    }
  }

  bool isUnlocked(String placeName) {
    return _unlockedNames.contains(placeName);
  }

  int getExp() => _exp;

  Set<String> getUnlockedNames() => _unlockedNames;

  TravelMemory? getMemory(String placeName) => _memories[placeName];

  List<PassportBadge> getBadges({List<Destination> allDestinations = const []}) {
    final list = <PassportBadge>[];
    
    // Check first check-in
    bool hasFirst = _unlockedNames.isNotEmpty;
    
    // Check Da Nang Explorer (Da Nang destinations all unlocked)
    bool hasDaNang = false;
    final daNangPlaces = allDestinations.where((d) => d.province.contains('Đà Nẵng')).map((d) => d.name).toList();
    if (daNangPlaces.isNotEmpty) {
      hasDaNang = daNangPlaces.every((name) => _unlockedNames.contains(name));
    } else {
      // Fallback check if Da Nang place names are unlocked (e.g. Cầu Rồng)
      hasDaNang = _unlockedNames.contains('Cầu Rồng');
    }

    // Check Hanoi Explorer
    bool hasHanoi = false;
    final hanoiPlaces = allDestinations.where((d) => d.province.contains('Hà Nội')).map((d) => d.name).toList();
    if (hanoiPlaces.isNotEmpty) {
      hasHanoi = hanoiPlaces.every((name) => _unlockedNames.contains(name));
    }

    // Check Master
    bool hasMaster = _unlockedNames.length >= 5;

    // Check Photographer (at least 1 memory with photo count > 0)
    bool hasPhoto = _memories.values.any((m) => m.photoCount > 0 || m.photoUrl.isNotEmpty);

    for (var b in _badges) {
      bool earned = false;
      if (b.id == 'badge_first') earned = hasFirst;
      else if (b.id == 'badge_danang') earned = hasDaNang;
      else if (b.id == 'badge_hanoi') earned = hasHanoi;
      else if (b.id == 'badge_master') earned = hasMaster;
      else if (b.id == 'badge_photographer') earned = hasPhoto;

      list.add(b.copyWith(isEarned: earned));
    }

    return list;
  }

  /// Perform a location check-in.
  /// Returns a map with results:
  /// - 'success': bool
  /// - 'gainedExp': int
  /// - 'badgesUnlocked': List<String> (new badge titles unlocked)
  Future<Map<String, dynamic>> checkIn(Destination dest, {List<Destination> allDestinations = const []}) async {
    await init();
    if (_unlockedNames.contains(dest.name)) {
      return {'success': false, 'message': 'Địa điểm này đã được mở khóa.'};
    }

    // Capture old badges
    final oldBadges = getBadges(allDestinations: allDestinations).where((b) => b.isEarned).map((b) => b.id).toSet();

    // Mark as unlocked
    _unlockedNames.add(dest.name);
    _exp += 150; // Gain 150 EXP for new unlock

    // Auto-create an empty travel memory so they can view it
    _memories[dest.name] = TravelMemory(
      destinationId: dest.id ?? '',
      destinationName: dest.name,
      date: _formattedToday(),
      tourTitle: 'Tự do khám phá',
      durationHours: 1.0,
      durationDays: 3,
      durationNights: 2,
      photoCount: 0,
      note: 'Nhật ký khám phá chưa được tạo. Hãy nhấn chỉnh sửa để viết ghi chú!',
      rating: 5.0,
      photoUrl: dest.imagePath,
    );

    await _save();

    // Capture new badges
    final newBadges = getBadges(allDestinations: allDestinations);
    final newlyUnlockedBadgeTitles = <String>[];
    for (var b in newBadges) {
      if (b.isEarned && !oldBadges.contains(b.id)) {
        newlyUnlockedBadgeTitles.add(b.title);
      }
    }

    return {
      'success': true,
      'gainedExp': 150,
      'badgesUnlocked': newlyUnlockedBadgeTitles,
    };
  }

  Future<void> saveMemory(String placeName, TravelMemory memory) async {
    await init();
    _memories[placeName] = memory;
    await _save();
  }

  String _formattedToday() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    return '$day/$month/${now.year}';
  }
}
