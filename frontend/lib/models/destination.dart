import 'package:flutter/material.dart';

const String destinationPlaceholderPath = 'assets/images/placeholder.png';

class Destination {
  final String? id;
  final String name;
  final String province;
  final String price;
  final String imagePath;
  final String bgBlurPath;
  final List<String> galleryImagePaths;
  final double latitude;
  final double longitude;
  final String type; // e.g. 'Địa điểm', 'Nhà hàng', 'Khách sạn'
  final String? sourceLocationId;
  final String? description;
  final double? totalScore;
  final int? reviewsCount;
  final List<String> tags;
  final String? category;
  final String? ranking;
  final String? priceRange;
  final Map<String, dynamic>? openingHours;
  final bool? hasImage;

  const Destination({
    this.id,
    required this.name,
    required this.province,
    required this.price,
    required this.imagePath,
    required this.bgBlurPath,
    this.galleryImagePaths = const [],
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.type = 'Địa điểm',
    this.sourceLocationId,
    this.description,
    this.totalScore,
    this.reviewsCount,
    this.tags = const [],
    this.category,
    this.ranking,
    this.priceRange,
    this.openingHours,
    this.hasImage = true,
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    final String idVal = (json['_id'] ?? json['id'] ?? '').toString();
    final String sourceLocationIdVal = (json['sourceLocationId'] ?? '').toString();
    final String nameVal = (json['title'] ?? json['name'] ?? '').toString();
    final String provinceVal = (json['state'] ?? json['city'] ?? json['province'] ?? '').toString();
    final String typeVal = (json['type'] ?? 'Địa điểm').toString();
    final String descriptionVal = (json['description'] ?? '').toString().trim();
    final totalScoreVal = json['totalScore'];
    final reviewsCountVal = json['reviewsCount'];
    final tagsVal = json['tags'];
    final String categoryVal = (json['category'] ?? '').toString().trim();
    final String rankingVal = (json['ranking'] ?? '').toString().trim();
    final String priceRangeVal = (json['priceRange'] ?? '').toString().trim();
    final openingHoursVal = json['openingHours'];
    final galleryImagePaths = <String>[];
    final rawImages = json['images'];
    if (rawImages is List) {
      for (final item in rawImages) {
        String url = '';
        if (item is String) {
          url = item.trim();
        } else if (item is Map) {
          url = (item['url'] ?? '').toString().trim();
        }
        if (url.isNotEmpty && !galleryImagePaths.contains(url)) {
          galleryImagePaths.add(url);
        }
      }
    }

    final sample = findSampleDestination(nameVal);

    // TripAdvisor image.url or direct imageUrl / imagePath
    String imgUrl = '';
    if (json['image'] != null && json['image'] is Map) {
      imgUrl = (json['image']['url'] ?? '').toString();
    }
    if (imgUrl.isEmpty) {
      imgUrl = (json['imageUrl'] ?? json['imagePath'] ?? destinationPlaceholderPath).toString();
    }
    final bool hasRealImage = imgUrl.trim().isNotEmpty &&
        imgUrl != destinationPlaceholderPath &&
        imgUrl != 'assets/images/halong.jpg';

    // Coordinates extraction: GeoJSON is [lng, lat]
    double latVal = 0.0;
    double lngVal = 0.0;
    if (json['location'] != null && json['location'] is Map) {
      final loc = json['location'];
      if (loc['coordinates'] != null && loc['coordinates'] is List && loc['coordinates'].length >= 2) {
        lngVal = (loc['coordinates'][0] as num).toDouble();
        latVal = (loc['coordinates'][1] as num).toDouble();
      }
    } else {
      latVal = ((json['latitude'] ?? sample?.latitude ?? 0.0) as num).toDouble();
      lngVal = ((json['longitude'] ?? sample?.longitude ?? 0.0) as num).toDouble();
    }

    final String parsedName = _translateName(nameVal.isNotEmpty ? nameVal : (sample?.name ?? ''));
    final String parsedProvince = _translateProvince(provinceVal.isNotEmpty ? provinceVal : (sample?.province ?? ''));


    // Only fall back to the app placeholder if the image URL is empty or the legacy default image.
    if (imgUrl.isEmpty || imgUrl == 'assets/images/halong.jpg') {
      imgUrl = getLocalFallbackAsset(parsedName.isNotEmpty ? parsedName : parsedProvince);
    }

    return Destination(
      id: idVal.isNotEmpty ? idVal : null,
      name: parsedName,
      province: parsedProvince,
      price: (json['price'] ?? json['priceRange'] ?? sample?.price ?? 'Chỉ từ 1.5 triệu đồng').toString(),
      imagePath: imgUrl,
      bgBlurPath: imgUrl,
      galleryImagePaths: galleryImagePaths.where((url) => url != imgUrl).toList(),
      latitude: latVal,
      longitude: lngVal,
      type: typeVal,
      sourceLocationId: sourceLocationIdVal.isNotEmpty ? sourceLocationIdVal : null,
      description: descriptionVal.isNotEmpty ? descriptionVal : null,
      totalScore: totalScoreVal is num ? totalScoreVal.toDouble() : null,
      reviewsCount: reviewsCountVal is num ? reviewsCountVal.toInt() : null,
      tags: tagsVal is List
          ? tagsVal.map((tag) => tag.toString()).where((tag) => tag.trim().isNotEmpty).toList()
          : const [],
      category: categoryVal.isNotEmpty ? categoryVal : null,
      ranking: rankingVal.isNotEmpty ? rankingVal : null,
      priceRange: priceRangeVal.isNotEmpty ? priceRangeVal : null,
      openingHours: openingHoursVal is Map
          ? Map<String, dynamic>.from(openingHoursVal)
          : openingHoursVal is String && openingHoursVal.trim().isNotEmpty
              ? {'display': openingHoursVal.trim()}
              : openingHoursVal is List && openingHoursVal.isNotEmpty
                  ? {'display': openingHoursVal}
                  : null,
      hasImage: hasRealImage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'province': province,
      'price': price,
      'imagePath': imagePath,
      'bgBlurPath': bgBlurPath,
      'images': galleryImagePaths,
      'latitude': latitude,
      'longitude': longitude,
      'type': type,
      if (sourceLocationId != null) 'sourceLocationId': sourceLocationId,
      if (description != null) 'description': description,
      if (totalScore != null) 'totalScore': totalScore,
      if (reviewsCount != null) 'reviewsCount': reviewsCount,
      'tags': tags,
      if (category != null) 'category': category,
      if (ranking != null) 'ranking': ranking,
      if (priceRange != null) 'priceRange': priceRange,
      if (openingHours != null) 'openingHours': openingHours,
      'hasImage': hasImage == true,
    };
  }

  static Widget buildImage(
    String path, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
    if (path.isEmpty) {
      return Image.asset(
        destinationPlaceholderPath,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFF2A4A3E),
          width: width,
          height: height,
          child: const Center(
            child: Icon(Icons.image, color: Colors.white38, size: 40),
          ),
        ),
      );
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      // Load the authentic network image from the database completely unchanged,
      // using browser header spoofing to prevent access blocks or rate-limiting.
      return Image.network(
        path,
        fit: fit,
        width: width,
        height: height,
        filterQuality: FilterQuality.high,
        headers: const {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Referer': 'https://www.tripadvisor.com/',
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: const Color(0xFF1E2E2A),
            width: width,
            height: height,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF7A)),
                ),
              ),
            ),
          );
        },
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            child: child,
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            destinationPlaceholderPath,
            fit: fit,
            width: width,
            height: height,
            errorBuilder: (_, __, ___) => Image.asset(
              destinationPlaceholderPath,
              fit: fit,
              width: width,
              height: height,
            ),
          );
        },
      );
    }

    return Image.asset(
      path,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, __, ___) => Image.asset(
        destinationPlaceholderPath,
        fit: fit,
        width: width,
        height: height,
      ),
    );
  }

  static String _translateName(String name) {
    final String trimmed = name.trim();
    
    final Map<String, String> translationMap = {
      'War Remnants Museum': 'Bảo tàng Chứng tích Chiến tranh',
      'Cu Chi Tunnels': 'Địa đạo Củ Chi',
      'Bưu điện trung tâm Sài Gòn': 'Bưu điện Trung tâm Sài Gòn',
      'Lăng Chủ Tịch Hồ Chí Minh': 'Lăng Chủ tịch Hồ Chí Minh',
      'Hoàng Thành Huế': 'Đại Nội Huế (Hoàng Thành)',
      'Văn Miếu Q': 'Văn Miếu - Quốc Tử Giám',
      'Hoa Lo Prison': 'Di tích Nhà tù Hỏa Lò',
      'Núi Ngũ Hành Sơn': 'Danh thắng Ngũ Hành Sơn',
      'Vietnam Museum of Ethnology': 'Bảo tàng Dân tộc học Việt Nam',
      'Tháp Tài Chính Bitexco': 'Tòa tháp Bitexco Financial',
      'Bảo tàng Phụ nữ Việt Nam': 'Bảo tàng Phụ nữ Việt Nam',
      'Lady Buddha': 'Tượng Phật Bà Chùa Linh Ứng',
      'Nhà hát Thành Phố Hồ Chí Minh': 'Nhà hát Thành phố Hồ Chí Minh',
      'Chùa Thiên Mụ': 'Chùa Thiên Mụ',
      'Crazy House': 'Biệt thự Hằng Nga (Crazy House)',
      'Thánh Địa Mỹ Sơn': 'Thánh địa Mỹ Sơn',
      'Khu di tích chủ tịch Hồ Chí Minh tại Phủ Chủ Tịch': 'Di tích Phủ Chủ Tịch',
      'Quảng trường Hồ Chí Minh': 'Quảng trường Hồ Chí Minh',
      'Đồi Cát Trắng': 'Đồi Cát Trắng (Mũi Né)',
      'Nhà Thờ Lớn': 'Nhà Thờ Lớn Hà Nội',
      'Tam Cốc-Bích Động': 'Khu du lịch Tam Cốc - Bích Động',
      'My Khe Beach': 'Bãi biển Mỹ Khê',
      'Trang An Grottoes': 'Khu du lịch sinh thái Tràng An',
      'Fairy Stream (Suoi Tien)': 'Suối Tiên (Mũi Né)',
      'Fairy Stream': 'Suối Tiên (Mũi Né)',
      'Mausoleum of Emperor Minh Mang': 'Lăng Minh Mạng',
      'Tomb of Tu Duc': 'Lăng Tự Đức',
      'Long Son Pagoda': 'Chùa Long Sơn',
      'Cat Ba National Park': 'Vườn quốc gia Cát Bà',
      'Fansipan Mountain': 'Đỉnh núi Fansipan',
      'Golden Bridge': 'Cầu Vàng (Bà Nà Hills)',
      'Ba Na Hills': 'Khu du lịch Bà Nà Hills',
    };

    return translationMap[trimmed] ?? trimmed;
  }

  static String _translateProvince(String province) {
    final String trimmed = province.trim();
    final Map<String, String> provinceMap = {
      'Ho Chi Minh City': 'TP. Hồ Chí Minh',
      'Hanoi': 'Hà Nội',
      'Quang Nam': 'Quảng Nam',
      'Quang Ninh': 'Quảng Ninh',
      'Da Nang': 'Đà Nẵng',
      'Thua Thien Hue': 'Thừa Thiên Huế',
      'Hue': 'Thừa Thiên Huế',
      'Nha Trang': 'Khánh Hòa',
      'Khanh Hoa': 'Khánh Hòa',
      'Lao Cai': 'Lào Cai',
      'Sapa': 'Lào Cai',
      'Ninh Binh': 'Ninh Bình',
      'Binh Thuan': 'Bình Thuận',
      'Phan Thiet': 'Bình Thuận',
      'Mui Ne': 'Bình Thuận',
      'Kien Giang': 'Kiên Giang',
      'Phu Quoc': 'Kiên Giang',
      'Ba Ria-Vung Tau': 'Bà Rịa - Vũng Tàu',
      'Vung Tau': 'Bà Rịa - Vũng Tàu',
    };
    return provinceMap[trimmed] ?? trimmed;
  }
}

Destination? findSampleDestination(String name) {
  if (name.isEmpty) return null;
  for (var d in sampleDestinations) {
    if (d.name.toLowerCase().trim() == name.toLowerCase().trim()) {
      return d;
    }
  }
  for (var d in sampleDestinations) {
    if (d.name.toLowerCase().contains(name.toLowerCase()) || 
        name.toLowerCase().contains(d.name.toLowerCase())) {
      return d;
    }
  }
  return null;
}


const List<Destination> sampleDestinations = [
  Destination(
    name: 'Hạ Long Bay',
    province: 'Quảng Ninh',
    price: 'Chỉ từ 3 triệu đồng',
    imagePath: 'assets/images/halong.jpg',
    bgBlurPath: 'assets/images/halong.jpg',
    latitude: 20.9101,
    longitude: 107.1839,
  ),
  Destination(
    name: 'Hội An',
    province: 'Quảng Nam',
    price: 'Chỉ từ 2 triệu đồng',
    imagePath: 'assets/images/hoi_an.jpg',
    bgBlurPath: 'assets/images/hoi_an.jpg',
    latitude: 15.8801,
    longitude: 108.3380,
  ),
  Destination(
    name: 'Đà Nẵng',
    province: 'Đà Nẵng',
    price: 'Chỉ từ 1.5 triệu đồng',
    imagePath: 'assets/images/da_nang.jpg',
    bgBlurPath: 'assets/images/da_nang.jpg',
    latitude: 16.0544,
    longitude: 108.2022,
  ),
  Destination(
    name: 'Phong Nha',
    province: 'Quảng Bình',
    price: 'Chỉ từ 1 triệu đồng',
    imagePath: 'assets/images/phongnhakebang.jpg',
    bgBlurPath: 'assets/images/phongnhakebang.jpg',
    latitude: 17.5878,
    longitude: 106.2731,
  ),
];

String getLocalFallbackAsset(String query) {
  return destinationPlaceholderPath;
}
