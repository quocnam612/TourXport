import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../api/api.dart';
import '../models/destination.dart';
import '../models/province_collection.dart';

/// The 34 provinces used in the collection grid.
const List<String> collectionProvinces = [
  'Tuyên Quang',
  'Cao Bằng',
  'Lai Châu',
  'Lào Cai',
  'Thái Nguyên',
  'Điện Biên',
  'Lạng Sơn',
  'Sơn La',
  'Phú Thọ',
  'TP. Hà Nội',
  'TP. Hải Phòng',
  'Bắc Ninh',
  'Quảng Ninh',
  'Hưng Yên',
  'Ninh Bình',
  'Thanh Hóa',
  'Nghệ An',
  'Hà Tĩnh',
  'Quảng Trị',
  'TP. Huế',
  'TP. Đà Nẵng',
  'Quảng Ngãi',
  'Gia Lai',
  'Đắk Lắk',
  'Khánh Hòa',
  'Lâm Đồng',
  'Đồng Nai',
  'Tây Ninh',
  'TP. Hồ Chí Minh',
  'Đồng Tháp',
  'An Giang',
  'Vĩnh Long',
  'TP. Cần Thơ',
  'Cà Mau',
];

/// Maps province display names to the backend `city` query values.
/// The backend stores provinces with their Vietnamese diacritics as the `city`
/// field, and also recognises some English variants.  This map covers the 34
/// collection provinces so we can build accurate API queries.
const Map<String, List<String>> _provinceQueryAliases = {
  'Tuyên Quang': ['Tuyên Quang', 'Tuyen Quang'],
  'Cao Bằng': ['Cao Bằng', 'Cao Bang'],
  'Lai Châu': ['Lai Châu', 'Lai Chau'],
  'Lào Cai': ['Lào Cai', 'Lao Cai', 'Sapa'],
  'Thái Nguyên': ['Thái Nguyên', 'Thai Nguyen'],
  'Điện Biên': ['Điện Biên', 'Dien Bien'],
  'Lạng Sơn': ['Lạng Sơn', 'Lang Son'],
  'Sơn La': ['Sơn La', 'Son La'],
  'Phú Thọ': ['Phú Thọ', 'Phu Tho'],
  'TP. Hà Nội': ['Hà Nội', 'Hanoi', 'Ha Noi'],
  'TP. Hải Phòng': ['Hải Phòng', 'Hai Phong'],
  'Bắc Ninh': ['Bắc Ninh', 'Bac Ninh'],
  'Quảng Ninh': ['Quảng Ninh', 'Quang Ninh'],
  'Hưng Yên': ['Hưng Yên', 'Hung Yen'],
  'Ninh Bình': ['Ninh Bình', 'Ninh Binh'],
  'Thanh Hóa': ['Thanh Hóa', 'Thanh Hoa'],
  'Nghệ An': ['Nghệ An', 'Nghe An'],
  'Hà Tĩnh': ['Hà Tĩnh', 'Ha Tinh'],
  'Quảng Trị': ['Quảng Trị', 'Quang Tri'],
  'TP. Huế': ['Huế', 'Hue', 'Thừa Thiên Huế', 'Thua Thien Hue'],
  'TP. Đà Nẵng': ['Đà Nẵng', 'Da Nang'],
  'Quảng Ngãi': ['Quảng Ngãi', 'Quang Ngai'],
  'Gia Lai': ['Gia Lai'],
  'Đắk Lắk': ['Đắk Lắk', 'Dak Lak'],
  'Khánh Hòa': ['Khánh Hòa', 'Khanh Hoa', 'Nha Trang'],
  'Lâm Đồng': ['Lâm Đồng', 'Lam Dong', 'Đà Lạt', 'Da Lat'],
  'Đồng Nai': ['Đồng Nai', 'Dong Nai'],
  'Tây Ninh': ['Tây Ninh', 'Tay Ninh'],
  'TP. Hồ Chí Minh': ['TP. Hồ Chí Minh', 'Ho Chi Minh City', 'Hồ Chí Minh'],
  'Đồng Tháp': ['Đồng Tháp', 'Dong Thap'],
  'An Giang': ['An Giang'],
  'Vĩnh Long': ['Vĩnh Long', 'Vinh Long'],
  'TP. Cần Thơ': ['Cần Thơ', 'Can Tho'],
  'Cà Mau': ['Cà Mau', 'Ca Mau'],
};

class ProvinceDataService {
  // Singleton
  ProvinceDataService._();
  static final ProvinceDataService instance = ProvinceDataService._();

  List<ProvinceCollection>? _cache;
  bool _isLoading = false;

  /// Returns cached collection data or fetches it fresh.
  Future<List<ProvinceCollection>> getCollections({
    Set<String> savedNames = const {},
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cache != null) {
      // Re-compute visited counts with latest savedNames
      return _rebuildVisited(_cache!, savedNames);
    }
    if (_isLoading) {
      // Wait for in-flight request
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (_cache != null) return _rebuildVisited(_cache!, savedNames);
    }
    _isLoading = true;
    try {
      _cache = await _fetchAllProvinceCollections(savedNames);
      return _cache!;
    } finally {
      _isLoading = false;
    }
  }

  void invalidateCache() => _cache = null;

  // ────────────────────────────────────────────────────

  Future<List<ProvinceCollection>> _fetchAllProvinceCollections(
    Set<String> savedNames,
  ) async {
    // Fetch a large batch of destinations from all 3 collections
    final futures = [
      _fetchBatch('/locations?limit=500&sortBy=reviewsCount&order=desc'),
      _fetchBatch('/restaurants?limit=200&sortBy=reviewsCount&order=desc'),
      _fetchBatch('/hotels?limit=200&sortBy=reviewsCount&order=desc'),
    ];
    final results = await Future.wait(futures);
    final allDestinations = <Destination>[
      ...results[0],
      ...results[1],
      ...results[2],
    ];

    return _groupByProvince(allDestinations, savedNames);
  }

  Future<List<Destination>> _fetchBatch(String path) async {
    try {
      final response = await apiGet(path);
      final data = tryDecodeJsonObject(response.body);
      if (response.statusCode == 200 && data?['success'] == true) {
        final raw = data!['data'];
        if (raw is List) {
          return raw
              .map((item) {
                try {
                  return Destination.fromJson(Map<String, dynamic>.from(item));
                } catch (e) {
                  debugPrint('Error parsing destination: $e');
                  return null;
                }
              })
              .whereType<Destination>()
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching batch $path: $e');
    }
    return [];
  }

  List<ProvinceCollection> _groupByProvince(
    List<Destination> allDestinations,
    Set<String> savedNames,
  ) {
    final collections = <ProvinceCollection>[];

    for (final provinceName in collectionProvinces) {
      final aliases = _provinceQueryAliases[provinceName] ?? [provinceName];
      final aliasSet = aliases.map((a) => a.toLowerCase()).toSet();

      // Find all destinations belonging to this province
      final provinceDestinations = allDestinations.where((d) {
        final prov = d.province.toLowerCase().trim();
        return aliasSet.any((alias) =>
            prov == alias ||
            prov.contains(alias) ||
            alias.contains(prov));
      }).toList();

      // Group by district (the `province` field after translation often
      // contains the city-level name; for sub-grouping we use the original
      // `province` value which may be a district/city name).
      final districtMap = <String, List<Destination>>{};
      for (final dest in provinceDestinations) {
        final districtName = dest.province.trim().isNotEmpty
            ? dest.province.trim()
            : provinceName;
        districtMap.putIfAbsent(districtName, () => []).add(dest);
      }

      final districts = districtMap.entries.map((entry) {
        final visitedCount = entry.value
            .where((d) => savedNames.contains(d.name))
            .length;
        return DistrictGroup(
          name: entry.key,
          places: entry.value,
          visitedCount: visitedCount,
        );
      }).toList();

      // Sort districts: unlocked first, then by place count descending
      districts.sort((a, b) {
        if (a.isUnlocked != b.isUnlocked) {
          return a.isUnlocked ? -1 : 1;
        }
        return b.places.length.compareTo(a.places.length);
      });

      // Find hero image for the province
      String? heroImageUrl;
      final allWithImage = provinceDestinations
          .where((d) => d.hasImage == true)
          .toList();
      if (allWithImage.isNotEmpty) {
        allWithImage.sort((a, b) =>
            (b.totalScore ?? 0).compareTo(a.totalScore ?? 0));
        final hero = allWithImage.first;
        heroImageUrl = hero.imagePath.startsWith('http') ? hero.imagePath : null;
      }

      final visitedTotal = provinceDestinations
          .where((d) => savedNames.contains(d.name))
          .length;

      collections.add(ProvinceCollection(
        name: provinceName,
        imageUrl: heroImageUrl,
        totalPlaces: provinceDestinations.length,
        visitedPlaces: visitedTotal,
        districts: districts,
      ));
    }

    return collections;
  }

  List<ProvinceCollection> _rebuildVisited(
    List<ProvinceCollection> cached,
    Set<String> savedNames,
  ) {
    return cached.map((pc) {
      int visitedTotal = 0;
      final updatedDistricts = pc.districts.map((dg) {
        final visited = dg.places
            .where((d) => savedNames.contains(d.name))
            .length;
        visitedTotal += visited;
        return DistrictGroup(
          name: dg.name,
          places: dg.places,
          visitedCount: visited,
        );
      }).toList();

      return ProvinceCollection(
        name: pc.name,
        imageUrl: pc.imageUrl,
        totalPlaces: pc.totalPlaces,
        visitedPlaces: visitedTotal,
        districts: updatedDistricts,
      );
    }).toList();
  }
}
