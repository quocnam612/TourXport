import 'package:flutter/material.dart';

class Destination {
  final String? id;
  final String name;
  final String province;
  final String price;
  final String imagePath;
  final String bgBlurPath;
  final double latitude;
  final double longitude;

  const Destination({
    this.id,
    required this.name,
    required this.province,
    required this.price,
    required this.imagePath,
    required this.bgBlurPath,
    this.latitude = 0.0,
    this.longitude = 0.0,
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    final String idVal = (json['_id'] ?? json['id'] ?? '') as String;
    final String nameVal = (json['title'] ?? json['name'] ?? '') as String;
    final String provinceVal = (json['state'] ?? json['city'] ?? json['province'] ?? '') as String;

    final sample = findSampleDestination(nameVal);

    // TripAdvisor image.url or direct imageUrl / imagePath
    String imgUrl = '';
    if (json['image'] != null && json['image'] is Map) {
      imgUrl = (json['image']['url'] ?? '') as String;
    }
    if (imgUrl.isEmpty) {
      imgUrl = (json['imageUrl'] ?? json['imagePath'] ?? sample?.imagePath ?? 'assets/images/halong.jpg') as String;
    }

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

    return Destination(
      id: idVal.isNotEmpty ? idVal : null,
      name: parsedName,
      province: parsedProvince,
      price: (json['price'] ?? json['priceRange'] ?? sample?.price ?? 'Chỉ từ 1.5 triệu đồng') as String,
      imagePath: imgUrl,
      bgBlurPath: imgUrl,
      latitude: latVal,
      longitude: lngVal,
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
      'latitude': latitude,
      'longitude': longitude,
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
        'assets/images/halong.jpg',
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
      // Beautify image by replacing TripAdvisor small thumbnail sizes with high-res original '/photo-o/' path
      String processedPath = path;
      if (path.contains('tripadvisor.com')) {
        processedPath = path
            .replaceAll('/photo-s/', '/photo-o/')
            .replaceAll('/photo-t/', '/photo-o/')
            .replaceAll('/photo-f/', '/photo-o/')
            .replaceAll('/photo-l/', '/photo-o/')
            .replaceAll('/photo-w/', '/photo-o/')
            .replaceAll('/photo-m/', '/photo-o/');
      }

      return Image.network(
        processedPath,
        fit: fit,
        width: width,
        height: height,
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
          // Double network fallback: if the high-res path fails to load, fall back to the original unmodified thumbnail URL
          if (processedPath != path) {
            return Image.network(
              path,
              fit: fit,
              width: width,
              height: height,
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
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/images/halong.jpg',
                fit: fit,
                width: width,
                height: height,
              ),
            );
          }
          // If all network assets fail, return a beautiful high-quality local placeholder image
          return Image.asset(
            'assets/images/halong.jpg',
            fit: fit,
            width: width,
            height: height,
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
        'assets/images/halong.jpg',
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
    imagePath: 'assets/images/Hoi An.jpg',
    bgBlurPath: 'assets/images/Hoi An.jpg',
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
