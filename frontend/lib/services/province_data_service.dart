import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

const Map<String, String> collectionProvinceSlugs = {
  'Tuyên Quang': 'tuyen-quang',
  'Cao Bằng': 'cao-bang',
  'Lai Châu': 'lai-chau',
  'Lào Cai': 'lao-cai',
  'Thái Nguyên': 'thai-nguyen',
  'Điện Biên': 'dien-bien',
  'Lạng Sơn': 'lang-son',
  'Sơn La': 'son-la',
  'Phú Thọ': 'phu-tho',
  'TP. Hà Nội': 'ha-noi',
  'TP. Hải Phòng': 'hai-phong',
  'Bắc Ninh': 'bac-ninh',
  'Quảng Ninh': 'quang-ninh',
  'Hưng Yên': 'hung-yen',
  'Ninh Bình': 'ninh-binh',
  'Thanh Hóa': 'thanh-hoa',
  'Nghệ An': 'nghe-an',
  'Hà Tĩnh': 'ha-tinh',
  'Quảng Trị': 'quang-tri',
  'TP. Huế': 'hue',
  'TP. Đà Nẵng': 'da-nang',
  'Quảng Ngãi': 'quang-ngai',
  'Gia Lai': 'gia-lai',
  'Đắk Lắk': 'dak-lak',
  'Khánh Hòa': 'khanh-hoa',
  'Lâm Đồng': 'lam-dong',
  'Đồng Nai': 'dong-nai',
  'Tây Ninh': 'tay-ninh',
  'TP. Hồ Chí Minh': 'ho-chi-minh',
  'Đồng Tháp': 'dong-thap',
  'An Giang': 'an-giang',
  'Vĩnh Long': 'vinh-long',
  'TP. Cần Thơ': 'can-tho',
  'Cà Mau': 'ca-mau',
};

String provinceExplorePath(String provinceName) =>
    '/explore/${collectionProvinceSlugs[provinceName] ?? provinceName}';

String? provinceNameFromExploreSlug(String slug) {
  final normalized = slug.trim().toLowerCase();
  for (final entry in collectionProvinceSlugs.entries) {
    if (entry.value == normalized) {
      return entry.key;
    }
  }
  return null;
}

/// Maps the 34 collection provinces to backend `city` queries. The backend then
/// expands each query with its own city/district aliases from parser.js.
const Map<String, List<String>> _provinceCityQueries = {
  'Tuyên Quang': ['Tuyên Quang', 'Hà Giang'],
  'Cao Bằng': ['Cao Bằng'],
  'Lai Châu': ['Lai Châu'],
  'Lào Cai': ['Lào Cai', 'Yên Bái'],
  'Thái Nguyên': ['Thái Nguyên', 'Bắc Kạn'],
  'Điện Biên': ['Điện Biên'],
  'Lạng Sơn': ['Lạng Sơn'],
  'Sơn La': ['Sơn La'],
  'Phú Thọ': ['Phú Thọ', 'Vĩnh Phúc', 'Hòa Bình'],
  'TP. Hà Nội': ['TP. Hà Nội'],
  'TP. Hải Phòng': ['TP. Hải Phòng', 'Hải Dương'],
  'Bắc Ninh': ['Bắc Ninh', 'Bắc Giang'],
  'Quảng Ninh': ['Quảng Ninh'],
  'Hưng Yên': ['Hưng Yên', 'Thái Bình'],
  'Ninh Bình': ['Ninh Bình', 'Hà Nam', 'Nam Định'],
  'Thanh Hóa': ['Thanh Hóa'],
  'Nghệ An': ['Nghệ An'],
  'Hà Tĩnh': ['Hà Tĩnh'],
  'Quảng Trị': ['Quảng Trị', 'Quảng Bình'],
  'TP. Huế': ['TP. Huế', 'Thừa Thiên Huế'],
  'TP. Đà Nẵng': ['TP. Đà Nẵng', 'Quảng Nam'],
  'Quảng Ngãi': ['Quảng Ngãi', 'Kon Tum'],
  'Gia Lai': ['Gia Lai', 'Bình Định'],
  'Đắk Lắk': ['Đắk Lắk', 'Phú Yên'],
  'Khánh Hòa': ['Khánh Hòa', 'Ninh Thuận'],
  'Lâm Đồng': ['Lâm Đồng', 'Bình Thuận', 'Đắk Nông'],
  'Đồng Nai': ['Đồng Nai', 'Bình Phước'],
  'Tây Ninh': ['Tây Ninh', 'Long An'],
  'TP. Hồ Chí Minh': [
    'TP. Hồ Chí Minh',
    'Bình Dương',
    'Bà Rịa - Vũng Tàu',
  ],
  'Đồng Tháp': ['Đồng Tháp', 'Tiền Giang'],
  'An Giang': ['An Giang', 'Kiên Giang'],
  'Vĩnh Long': ['Vĩnh Long', 'Bến Tre', 'Trà Vinh'],
  'TP. Cần Thơ': ['TP. Cần Thơ', 'Hậu Giang', 'Sóc Trăng'],
  'Cà Mau': ['Cà Mau', 'Bạc Liêu'],
};

const Map<String, int> _provincePlaceLimits = {
  'Tuyên Quang': 40,
  'Cao Bằng': 20,
  'Lai Châu': 10,
  'Lào Cai': 60,
  'Thái Nguyên': 10,
  'Điện Biên': 10,
  'Lạng Sơn': 10,
  'Sơn La': 15,
  'Phú Thọ': 30,
  'TP. Hà Nội': 300,
  'TP. Hải Phòng': 60,
  'Bắc Ninh': 15,
  'Quảng Ninh': 50,
  'Hưng Yên': 20,
  'Ninh Bình': 80,
  'Thanh Hóa': 36,
  'Nghệ An': 30,
  'Hà Tĩnh': 10,
  'Quảng Trị': 50,
  'TP. Huế': 90,
  'TP. Đà Nẵng': 200,
  'Quảng Ngãi': 30,
  'Gia Lai': 45,
  'Đắk Lắk': 40,
  'Khánh Hòa': 120,
  'Lâm Đồng': 100,
  'Đồng Nai': 15,
  'Tây Ninh': 10,
  'TP. Hồ Chí Minh': 400,
  'Đồng Tháp': 10,
  'An Giang': 90,
  'Vĩnh Long': 15,
  'TP. Cần Thơ': 25,
  'Cà Mau': 10,
};

const List<String> _collectionEndpoints = [
  '/locations',
  '/restaurants',
  '/hotels',
];

String _typeForEndpoint(String endpoint) {
  switch (endpoint) {
    case '/restaurants':
      return 'Nhà hàng';
    case '/hotels':
      return 'Khách sạn';
    default:
      return 'Địa điểm';
  }
}

class _ProvinceEndpointResult {
  final List<Destination> items;
  final int totalPages;

  const _ProvinceEndpointResult({
    this.items = const [],
    this.totalPages = 1,
  });
}

class ProvinceDataService {
  // Singleton
  ProvinceDataService._();
  static final ProvinceDataService instance = ProvinceDataService._();

  static const String _detailCachePrefix = 'province_collection_detail_v2_';
  static const String _detailCacheTimePrefix = 'province_collection_detail_time_v2_';
  static const Duration _cacheTtl = Duration(hours: 24);

  final Map<String, ProvinceCollection> _detailCache = {};
  final Set<String> _loadingProvinces = {};

  /// Returns hard-coded province cards without calling the API.
  Future<List<ProvinceCollection>> getCollections({
    Set<String> savedNames = const {},
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) {
      invalidateCache();
    }
    return _buildStaticCollections(savedNames);
  }

  Future<ProvinceCollection> getCollectionDetails(
    String provinceName, {
    Set<String> savedNames = const {},
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _detailCache[provinceName] != null) {
      return _withHardcodedTotal(
        _rebuildVisited([_detailCache[provinceName]!], savedNames).first,
      );
    }

    if (!forceRefresh) {
      final persisted = await _readPersistedDetail(provinceName);
      if (persisted != null) {
        _detailCache[provinceName] = persisted;
        return _withHardcodedTotal(
          _rebuildVisited([persisted], savedNames).first,
        );
      }
    }

    if (_loadingProvinces.contains(provinceName)) {
      while (_loadingProvinces.contains(provinceName)) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (_detailCache[provinceName] != null) {
        return _withHardcodedTotal(
          _rebuildVisited([_detailCache[provinceName]!], savedNames).first,
        );
      }
    }

    _loadingProvinces.add(provinceName);
    try {
      final collection = await _fetchProvinceCollection(provinceName, savedNames);
      _detailCache[provinceName] = collection;
      await _writePersistedDetail(collection);
      return collection;
    } finally {
      _loadingProvinces.remove(provinceName);
    }
  }

  void invalidateCache() {
    _detailCache.clear();
    SharedPreferences.getInstance().then((prefs) {
      for (final provinceName in collectionProvinces) {
        prefs.remove(_detailCacheKey(provinceName));
        prefs.remove(_detailCacheTimeKey(provinceName));
      }
    });
  }

  List<ProvinceCollection> _buildStaticCollections(Set<String> savedNames) {
    return collectionProvinces.map((provinceName) {
      final cached = _detailCache[provinceName];
      if (cached != null) {
        return _withHardcodedTotal(
          _rebuildVisited([cached], savedNames).first,
        );
      }

      return ProvinceCollection(
        name: provinceName,
        totalPlaces: _provincePlaceLimits[provinceName] ?? 0,
        visitedPlaces: 0,
      );
    }).toList();
  }

  ProvinceCollection _withHardcodedTotal(ProvinceCollection collection) {
    return ProvinceCollection(
      name: collection.name,
      imageUrl: collection.imageUrl,
      totalPlaces: _provincePlaceLimits[collection.name] ?? collection.totalPlaces,
      visitedPlaces: collection.visitedPlaces,
      districts: collection.districts,
    );
  }

  String _detailCacheKey(String provinceName) =>
      '$_detailCachePrefix${Uri.encodeComponent(provinceName)}';

  String _detailCacheTimeKey(String provinceName) =>
      '$_detailCacheTimePrefix${Uri.encodeComponent(provinceName)}';

  Future<ProvinceCollection?> _readPersistedDetail(String provinceName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedAt = prefs.getInt(_detailCacheTimeKey(provinceName));
      final payload = prefs.getString(_detailCacheKey(provinceName));
      if (cachedAt == null || payload == null || payload.isEmpty) {
        return null;
      }

      final age = DateTime.now().millisecondsSinceEpoch - cachedAt;
      if (age > _cacheTtl.inMilliseconds) {
        return null;
      }

      final decoded = jsonDecode(payload);
      if (decoded is! Map) return null;
      final collection = _provinceCollectionFromJson(
        Map<String, dynamic>.from(decoded),
      );
      return collection.name == provinceName ? collection : null;
    } catch (e) {
      debugPrint('Error reading province detail cache: $e');
      return null;
    }
  }

  Future<void> _writePersistedDetail(ProvinceCollection collection) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = jsonEncode(_provinceCollectionToJson(collection));
      await prefs.setString(_detailCacheKey(collection.name), payload);
      await prefs.setInt(
        _detailCacheTimeKey(collection.name),
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('Error writing province detail cache: $e');
    }
  }

  Map<String, dynamic> _provinceCollectionToJson(ProvinceCollection pc) {
    return {
      'name': pc.name,
      'imageUrl': pc.imageUrl,
      'totalPlaces': pc.totalPlaces,
      'districts': pc.districts
          .map((district) => {
                'name': district.name,
                'places': district.places.map((place) => place.toJson()).toList(),
              })
          .toList(),
    };
  }

  ProvinceCollection _provinceCollectionFromJson(Map<String, dynamic> json) {
    final rawDistricts = json['districts'];
    final districts = rawDistricts is List
        ? rawDistricts
            .map((item) {
              final map = Map<String, dynamic>.from(item as Map);
              final rawPlaces = map['places'];
              final places = rawPlaces is List
                  ? rawPlaces
                      .map((place) => Destination.fromJson(
                            Map<String, dynamic>.from(place as Map),
                          ))
                      .toList()
                  : <Destination>[];
              return DistrictGroup(
                name: (map['name'] ?? '').toString(),
                places: places,
              );
            })
            .toList()
        : <DistrictGroup>[];

    return ProvinceCollection(
      name: (json['name'] ?? '').toString(),
      imageUrl: json['imageUrl']?.toString(),
      totalPlaces: json['totalPlaces'] is num
          ? (json['totalPlaces'] as num).toInt()
          : districts.fold<int>(0, (sum, district) => sum + district.places.length),
      districts: districts,
    );
  }

  // ────────────────────────────────────────────────────

  Future<_ProvinceEndpointResult> _fetchEndpointPage({
    required String endpoint,
    required String city,
    required int limit,
    required int page,
  }) async {
    try {
      final query = Uri(queryParameters: {
        'city': city,
        'limit': limit.toString(),
        'page': page.toString(),
        'sortBy': 'reviewsCount',
        'order': 'desc',
        'isCollection': 'true',
      }).query;
      final path = '$endpoint?$query';
      final response = await apiGet(path);
      final data = tryDecodeJsonObject(response.body);
      if (response.statusCode == 200 && data?['success'] == true) {
        final raw = data!['data'];
        final totalPages = data['totalPages'] is num
            ? (data['totalPages'] as num).toInt()
            : 1;

        if (raw is List) {
          final items = raw
              .map((item) {
                try {
                  final map = Map<String, dynamic>.from(item);
                  map['type'] = _typeForEndpoint(endpoint);
                  return Destination.fromJson(map);
                } catch (e) {
                  debugPrint('Error parsing destination: $e');
                  return null;
                }
              })
              .whereType<Destination>()
              .toList();
          return _ProvinceEndpointResult(
            items: items,
            totalPages: totalPages < 1 ? 1 : totalPages,
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching $endpoint for $city page $page: $e');
    }
    return const _ProvinceEndpointResult();
  }

  Future<List<Destination>> _fetchEndpointAllPages({
    required String endpoint,
    required String city,
    required int targetCount,
  }) async {
    final pageSize = targetCount < 100 ? targetCount : 100;
    final requestedPages = (targetCount / pageSize).ceil();
    final firstPage = await _fetchEndpointPage(
      endpoint: endpoint,
      city: city,
      limit: pageSize,
      page: 1,
    );
    final totalPages = firstPage.totalPages < requestedPages
        ? firstPage.totalPages
        : requestedPages;
    if (totalPages <= 1) {
      return firstPage.items;
    }

    final rest = await Future.wait(
      [
        for (var page = 2; page <= totalPages; page++)
          _fetchEndpointPage(
            endpoint: endpoint,
            city: city,
            limit: pageSize,
            page: page,
          ),
      ],
    );
    return [
      ...firstPage.items,
      for (final result in rest) ...result.items,
    ];
  }

  Future<ProvinceCollection> _fetchProvinceCollection(
    String provinceName,
    Set<String> savedNames,
  ) async {
    final cityQueries = _provinceCityQueries[provinceName] ?? [provinceName];
    final targetCount = _provincePlaceLimits[provinceName] ?? 20;
    final futures = <Future<List<Destination>>>[
      for (final city in cityQueries)
        for (final endpoint in _collectionEndpoints)
          _fetchEndpointAllPages(
            endpoint: endpoint,
            city: city,
            targetCount: targetCount,
          ),
    ];
    final results = await Future.wait(futures);

    final uniqueDestinations = <String, Destination>{};
    for (final result in results) {
      for (final dest in result) {
        final key = dest.id ??
            dest.sourceLocationId ??
            '${dest.type}:${dest.name}:${dest.province}';
        uniqueDestinations.putIfAbsent(key, () => dest);
      }
    }

    final provinceDestinations = uniqueDestinations.values.toList()
      ..sort((a, b) {
        final reviewsCompare =
            (b.reviewsCount ?? 0).compareTo(a.reviewsCount ?? 0);
        if (reviewsCompare != 0) return reviewsCompare;
        return (b.totalScore ?? 0).compareTo(a.totalScore ?? 0);
      });
    final limitedDestinations = provinceDestinations.length > targetCount
        ? provinceDestinations.take(targetCount).toList()
        : provinceDestinations;
    final districtMap = <String, List<Destination>>{};
    for (final dest in limitedDestinations) {
      final districtName =
          dest.province.trim().isNotEmpty ? dest.province.trim() : provinceName;
      districtMap.putIfAbsent(districtName, () => []).add(dest);
    }

    final districts = districtMap.entries.map((entry) {
      final visitedCount =
          entry.value.where((d) => savedNames.contains(d.name)).length;
      return DistrictGroup(
        name: entry.key,
        places: entry.value,
        visitedCount: visitedCount,
      );
    }).toList();

    districts.sort((a, b) {
      if (a.isUnlocked != b.isUnlocked) {
        return a.isUnlocked ? -1 : 1;
      }
      return b.places.length.compareTo(a.places.length);
    });

    String? heroImageUrl;
    final allWithImage =
        limitedDestinations.where((d) => d.hasImage == true).toList();
    if (allWithImage.isNotEmpty) {
      allWithImage.sort(
          (a, b) => (b.totalScore ?? 0).compareTo(a.totalScore ?? 0));
      final hero = allWithImage.first;
      heroImageUrl = hero.imagePath.isNotEmpty ? hero.imagePath : null;
    }

    final visitedTotal =
        limitedDestinations.where((d) => savedNames.contains(d.name)).length;

    return ProvinceCollection(
      name: provinceName,
      imageUrl: heroImageUrl,
      totalPlaces: targetCount,
      visitedPlaces: visitedTotal,
      districts: districts,
    );
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
