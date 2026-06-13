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
  'Cao Bằng': ['Cao Bằng', 'Cao Bang', 'Bao Lac', 'Dam Thuy', 'Pac Bo', 'Phuc Sen', 'Tỉnh Cao Bằng', 'Trung Khanh', 'Truong Ha'],
  'Lai Châu': ['Lai Châu', 'Lai Chau', 'Lai Châu, Tỉnh Lai Châu', 'Phong Tho', 'Phong Tho, Tỉnh Lai Châu', 'Sin Sui Ho, Tỉnh Lai Châu', 'Tam Đường', 'Tam Đường, Tỉnh Lai Châu'],
  'Lào Cai': ['Lào Cai', 'Lao Cai', 'Sapa', 'Bắc Hà', 'Hau Thao', 'La Pan Tan', 'La Pan Tan, Tỉnh Lào Cai', 'Lào Cai', 'Lào Cai, Tỉnh Lào Cai', 'Lao Chai', 'Mu Cang Chai', 'San Sa Ho', 'Sapa, Tỉnh Lào Cai', 'Su Pan', 'Ta Phin', 'Ta Van', 'Tỉnh Lào Cai'],
  'Thái Nguyên': ['Thái Nguyên', 'Thai Nguyen', 'Đồng Tiến', 'Thái Nguyên'],
  'Điện Biên': ['Điện Biên', 'Dien Bien', 'Điện Biên Phủ', 'Muong Lay', 'Muong Phan', 'Tuần Giáo'],
  'Lạng Sơn': ['Lạng Sơn', 'Lang Son', 'Bac Son', 'Huu Lien'],
  'Sơn La': ['Sơn La', 'Son La', 'Bac Yen', 'Bac Yen, Tỉnh Sơn La', 'Chieng On', 'Mộc Châu', 'Mộc Châu, Tỉnh Sơn La', 'Muong Sang', 'Muong Sang, Tỉnh Sơn La', 'Ngoc Chien', 'Phieng Luong, Tỉnh Sơn La', 'Sơn La, Tỉnh Sơn La', 'Ta Xua', 'Ta Xua, Bac Yen, Tỉnh Sơn La', 'Van Ho', 'Van Ho, Tỉnh Sơn La'],
  'Phú Thọ': ['Phú Thọ', 'Phu Tho', 'Ba Vi', 'Hien Luong', 'Thanh Thuy', 'Viet Tri', 'Xuan Dai'],
  'TP. Hà Nội': ['Hà Nội', 'Hanoi', 'Ha Noi', 'Ba Dinh', 'Ba Vi', 'Bắc Từ Liêm', 'Cau Giay', 'Dong Da', 'Gia Lam', 'Ha Dong', 'Hai Ba Trung', 'Hoai Duc', 'Hoan Kiem', 'Hoang Mai', 'Long Bien', 'Mai Dinh', 'Me Tri', 'Nam Từ Liêm', 'Son Tay', 'Tay Ho', 'Thành phố Hà Nội', 'Thanh Xuan', 'TP. Hà Nội', 'Tu Liem'],
  'TP. Hải Phòng': ['Hải Phòng', 'Hai Phong', 'Cat Ba Town', 'Cat Hai', 'Do Son', 'Gia Luan', 'Hong Bang', 'Hung Thang', 'Le Chan', 'Thành phố Hải Phòng', 'Thành phố Hải Phòng', 'TP. Hải Phòng', 'Tran Chau'],
  'Bắc Ninh': ['Bắc Ninh', 'Bac Ninh', 'Đình Bảng', 'Tỉnh Bắc Ninh', 'Tu Son'],
  'Quảng Ninh': ['Quảng Ninh', 'Quang Ninh', 'Bai Chay', 'Cai Rong', 'Cam Pha', 'Dong Trieu', 'Ha Long City', 'Hong Hai', 'Hung Thang', 'Móng Cái', 'Quan Lạn', 'Quang Châu', 'Tỉnh Quảng Ninh', 'Uong Bi', 'Van Don', 'Vịnh Hạ Long'],
  'Hưng Yên': ['Hưng Yên', 'Hung Yen', 'Dong Da', 'Hai Ba Trung', 'Hoang Mai', 'Long Bien', 'Phung Cong', 'Tam Tien', 'Van Giang'],
  'Ninh Bình': ['Ninh Bình', 'Ninh Binh', 'Gia Sinh', 'Gia Sinh, Tỉnh Ninh Bình', 'Gia Van', 'Gia Vien', 'Hoa Lu', 'Khe Ha', 'Kỳ Phú', 'Ninh An', 'Ninh Bình', 'Ninh Bình, Tỉnh Ninh Bình', 'Ninh Hai', 'Ninh Hai, Huyện Hoa Lư, Tỉnh Ninh Bình', 'Ninh Hoa, Huyện Hoa Lư, Tỉnh Ninh Bình', 'Ninh Thang', 'Ninh Xuân', 'Ninh Xuân, Huyện Hoa Lư, Tỉnh Ninh Bình', 'Tam Diep', 'Thien Ton', 'Tỉnh Ninh Bình', 'Truong Yen', 'Truong Yen, Huyện Hoa Lư, Tỉnh Ninh Bình', 'Van Phuong'],
  'Thanh Hóa': ['Thanh Hóa', 'Thanh Hoa', 'Ba Thuoc', 'Cam Luong', 'Co Lung', 'Hải Hòa', 'Hoang Hoa', 'Hoang Tien', 'Nga Thien', 'Nghi Son', 'Sầm Sơn', 'Thanh Hóa', 'Thanh Lam', 'Thanh Son', 'Thanh Yen', 'Tinh Gia District', 'Tỉnh Thanh Hóa', 'Tri Nang', 'Trieu Loc', 'Vinh Long', 'Vinh Tien'],
  'Nghệ An': ['Nghệ An', 'Nghe An', 'Con Cuong', 'Cửa Lò', 'Diễn Châu', 'Diễn Thành', 'Hoang Mai', 'Hung Thịnh', 'Kim Lien', 'Mon Son', 'Nghi Yen', 'Nghia Thuan', 'Que Phong', 'Quy Hop', 'Quynh Nghia', 'Thai Hoa', 'Thanh An', 'Tỉnh Nghệ An', 'Tràng Sơn', 'Vinh'],
  'Hà Tĩnh': ['Hà Tĩnh', 'Ha Tinh', 'Duc Tho', 'Kỳ Anh', 'Phuong Dien', 'Thiên Cầm'],
  'Quảng Trị': ['Quảng Trị', 'Quang Tri', 'Đông Hà', 'Hai Phu', 'Khe Sanh', 'Lao Bảo', 'Tan Hop', 'Vinh Linh', 'Vinh Truong'],
  'TP. Huế': ['Huế', 'Hue', 'Thừa Thiên Huế', 'Thua Thien Hue', 'Cu Du', 'Cu Du, Loc Vinh, Phu Loc District, Tỉnh Thừa Thiên - Huế', 'Huế', 'Huế, Tỉnh Thừa Thiên - Huế', 'Huong Thuy', 'Khe Tre', 'Lăng Cô', 'Loc Vinh, Phu Loc District, Tỉnh Thừa Thiên - Huế', 'Lộc Tiễn', 'Phong Son', 'Phú Bài', 'Phú Dương', 'Phú Dương, Tỉnh Thừa Thiên - Huế', 'Phú Lộc', 'Phú Lộc, Phu Loc District, Tỉnh Thừa Thiên - Huế', 'Quảng Lợi', 'Thành phố Huế', 'Thi Tran A Luoi', 'Tỉnh Thừa Thiên - Huế', 'TP. Huế', 'Vinh An'],
  'TP. Đà Nẵng': ['Đà Nẵng', 'Da Nang', 'An Hai', 'An Hai Bac', 'An Hai Bac, Son Tra Peninsula, Đà Nẵng', 'An Hai Dong', 'An Hai Tay', 'An Hai, Son Tra Peninsula, Đà Nẵng', 'Đà Nẵng', 'Điện Bàn', 'Điện Bàn, Đà Nẵng', 'Hai Chau', 'Hai Chau, Đà Nẵng', 'Hoa Hai', 'Hoa Hai, Đà Nẵng', 'Hoa Hiep Bac', 'Hoà Khánh Bắc', 'Hòa Phú', 'Lien Chieu', 'Man Thai, Son Tra Peninsula, Đà Nẵng', 'My An', 'My An, Đà Nẵng', 'Nai Hien Dong', 'Ngu Hanh Son', 'Ngu Hanh Son, Đà Nẵng', 'Phuoc My', 'Phuoc My, Son Tra Peninsula, Đà Nẵng', 'Son Tra Peninsula', 'Son Tra Peninsula, Đà Nẵng', 'Thanh Khe', 'Thành phố Đà Nẵng', 'Tho Quang', 'Tho Quang, Son Tra Peninsula, Đà Nẵng', 'TP. Đà Nẵng'],
  'Quảng Ngãi': ['Quảng Ngãi', 'Quang Ngai', 'Quảng Ngãi', 'Tỉnh Quảng Ngãi'],
  'Gia Lai': ['Gia Lai', 'Chu Jor', 'Pleiku', 'Thi Xa An Khe'],
  'Đắk Lắk': ['Đắk Lắk', 'Dak Lak', 'An Chan', 'An Mỹ', 'An Ninh Dong', 'Buôn Ma Thuột', 'Ea Huar', 'Hoa Tam', 'Krong Bong', 'Liên Sơn', 'Phu My', 'Quang Tien', 'Thị trấn Sông Cầu', 'Tỉnh Đắk Lắk', 'Tuy Hòa', 'Xuan Thinh'],
  'Khánh Hòa': ['Khánh Hòa', 'Khanh Hoa', 'Nha Trang', 'Cam Đức', 'Cam Hải Đông', 'Cam Hải Đông, Cam Lâm District, Khánh Hòa', 'Cam Hai Tay', 'Cam Ranh', 'Dien Dien', 'Dien Hoa', 'Dien Thọ', 'Dốc Lết', 'Khánh Hòa', 'Khanh Phu', 'Khanh Vinh', 'Nha Trang, Khánh Hòa', 'Ninh Hai, Ninh Hoa, Khánh Hòa', 'Ninh Hiep', 'Ninh Hoa', 'Ninh Phước', 'Ninh Vân, Ninh Hoa, Khánh Hòa', 'Van Ninh'],
  'Lâm Đồng': ['Lâm Đồng', 'Lam Dong', 'Đà Lạt', 'Da Lat', 'Bảo Lộc', 'Dalat', 'Di Linh', 'Đà Lạt', 'Gia Lam', 'Lac Duong', 'Lat', 'Lâm Đồng', 'Lien Nghia', 'Madagui Town', 'Me Linh', 'Nam Ban', 'Phi To', 'Phuong 8', 'Ta Nung', 'Thị Tran Nam Ban', 'Tỉnh Lâm Đồng', 'Tu Tra'],
  'Đồng Nai': ['Đồng Nai', 'Dong Nai', 'Biên Hòa', 'Doc Mo', 'Gia Tan 1', 'Gia Tan 2', 'Long Giao', 'Long Khánh', 'Long Thanh', 'Nam Cát Tiên', 'Nhon Trach', 'Phú Hữu', 'Quan Tom', 'Quang Trung', 'Tan Phu', 'Thái Thiên', 'Tỉnh Đồng Nai', 'Trảng Bom', 'Vinh Thanh', 'Xa Bang', 'Xuân Phú'],
  'Tây Ninh': ['Tây Ninh', 'Tay Ninh', 'Go Dau Ha', 'Trang Bang'],
  'TP. Hồ Chí Minh': ['TP. Hồ Chí Minh', 'Ho Chi Minh City', 'Hồ Chí Minh', 'Sai Gon', 'Sài Gòn', 'Thành phố Hồ Chí Minh', 'TP Hồ Chí Minh'],
  'Đồng Tháp': ['Đồng Tháp', 'Dong Thap', 'Cao Lãnh', 'Hong Ngu', 'Sa Đéc', 'Tram Chim'],
  'An Giang': ['An Giang', 'An Phu', 'Châu Đốc', 'Châu Đốc, Tỉnh An Giang', 'Long Xuyên', 'Long Xuyên, Tỉnh An Giang', 'Nui To', 'Tỉnh An Giang', 'Tinh Bien', 'Tinh Bien, Tỉnh An Giang'],
  'Vĩnh Long': ['Vĩnh Long', 'Vinh Long', 'Bình Hòa Phước', 'Bình Minh', 'Cái Bè', 'Ninh Kieu', 'Tỉnh Vĩnh Long', 'Vĩnh Long'],
  'TP. Cần Thơ': ['TP. Cần Thơ', 'Cần Thơ', 'Can Tho', 'Cần Thơ', 'Ninh Kieu', 'Thành phố Cần Thơ'],
  'Cà Mau': ['Cà Mau', 'Ca Mau', 'Ap Da Bac, Tỉnh Cà Mau, Đồng bằng Mekong', 'Cà Mau', 'Cà Mau, Tỉnh Cà Mau, Đồng bằng Mekong', 'Năm Căn', 'Năm Căn, Tỉnh Cà Mau, Đồng bằng Mekong', 'Tỉnh Cà Mau, Đồng bằng Mekong'],
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
      _fetchBatch('/locations?limit=3500&sortBy=reviewsCount&order=desc&isCollection=true'),
      _fetchBatch('/restaurants?limit=1000&sortBy=reviewsCount&order=desc&isCollection=true'),
      _fetchBatch('/hotels?limit=1000&sortBy=reviewsCount&order=desc&isCollection=true'),
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
        heroImageUrl = hero.imagePath.isNotEmpty ? hero.imagePath : null;
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
